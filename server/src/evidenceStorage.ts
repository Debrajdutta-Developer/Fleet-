import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { GetObjectCommand, ListObjectsV2Command, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';

export interface EvidenceStorage {
  readonly kind: 'local' | 's3' | 'supabase';
  put(key: string, body: Buffer, contentType: string): Promise<void>;
  putJson(key: string, value: unknown): Promise<void>;
  listJson(prefix: string): Promise<unknown[]>;
}

export class LocalEvidenceStorage implements EvidenceStorage {
  readonly kind = 'local' as const;
  constructor(private readonly root: string) {}

  private pathFor(key: string): string {
    return join(this.root, ...key.split('/'));
  }

  async put(key: string, body: Buffer): Promise<void> {
    const path = this.pathFor(key);
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, body, { flag: 'wx' });
  }

  async putJson(key: string, value: unknown): Promise<void> {
    const path = this.pathFor(key);
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, JSON.stringify(value, null, 2), { flag: 'wx' });
  }

  async listJson(prefix: string): Promise<unknown[]> {
    const dir = this.pathFor(prefix.replace(/\/$/, ''));
    let names: string[] = [];
    try {
      names = await readdir(dir);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
      throw error;
    }
    const values: unknown[] = [];
    for (const name of names.filter((name) => name.endsWith('.json'))) {
      try {
        values.push(JSON.parse(await readFile(join(dir, name), 'utf8')) as unknown);
      } catch {
        // Malformed sidecars are ignored; callers still validate tenant/trip fields.
      }
    }
    return values;
  }
}

export class S3EvidenceStorage implements EvidenceStorage {
  readonly kind = 's3' as const;
  private readonly client: S3Client;

  constructor(
    private readonly bucket: string,
    options: { region: string; endpoint?: string; accessKeyId: string; secretAccessKey: string; forcePathStyle?: boolean },
  ) {
    this.client = new S3Client({
      region: options.region,
      endpoint: options.endpoint || undefined,
      forcePathStyle: options.forcePathStyle ?? false,
      credentials: {
        accessKeyId: options.accessKeyId,
        secretAccessKey: options.secretAccessKey,
      },
    });
  }

  async put(key: string, body: Buffer, contentType: string): Promise<void> {
    await this.client.send(new PutObjectCommand({ Bucket: this.bucket, Key: key, Body: body, ContentType: contentType }));
  }

  async putJson(key: string, value: unknown): Promise<void> {
    await this.client.send(new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      Body: Buffer.from(JSON.stringify(value)),
      ContentType: 'application/json',
    }));
  }

  async listJson(prefix: string): Promise<unknown[]> {
    const values: unknown[] = [];
    let continuationToken: string | undefined;
    do {
      const page = await this.client.send(new ListObjectsV2Command({
        Bucket: this.bucket,
        Prefix: prefix,
        ContinuationToken: continuationToken,
      }));
      for (const object of page.Contents ?? []) {
        if (!object.Key?.endsWith('.json')) continue;
        const result = await this.client.send(new GetObjectCommand({ Bucket: this.bucket, Key: object.Key }));
        try {
          const text = await result.Body?.transformToString();
          if (text) values.push(JSON.parse(text) as unknown);
        } catch {
          // Ignore malformed metadata objects.
        }
      }
      continuationToken = page.IsTruncated ? page.NextContinuationToken : undefined;
    } while (continuationToken);
    return values;
  }
}

interface SupabaseListItem {
  name?: string;
}

export class SupabaseEvidenceStorage implements EvidenceStorage {
  readonly kind = 'supabase' as const;
  private readonly baseUrl: string;

  constructor(
    projectUrl: string,
    private readonly serviceRoleKey: string,
    private readonly bucket: string,
  ) {
    this.baseUrl = projectUrl.replace(/\/$/, '');
  }

  private headers(contentType?: string): Record<string, string> {
    return {
      apikey: this.serviceRoleKey,
      Authorization: `Bearer ${this.serviceRoleKey}`,
      ...(contentType ? { 'Content-Type': contentType } : {}),
    };
  }

  private objectUrl(key: string): string {
    const encodedPath = key.split('/').map(encodeURIComponent).join('/');
    return `${this.baseUrl}/storage/v1/object/${encodeURIComponent(this.bucket)}/${encodedPath}`;
  }

  private async assertOk(response: Response, operation: string): Promise<void> {
    if (response.ok) return;
    const text = await response.text().catch(() => '');
    throw new Error(`Supabase Storage ${operation} failed (${response.status})${text ? `: ${text.slice(0, 300)}` : ''}`);
  }

  async put(key: string, body: Buffer, contentType: string): Promise<void> {
    const response = await fetch(this.objectUrl(key), {
      method: 'POST',
      headers: {
        ...this.headers(contentType),
        'x-upsert': 'false',
      },
      body,
    });
    await this.assertOk(response, 'upload');
  }

  async putJson(key: string, value: unknown): Promise<void> {
    await this.put(key, Buffer.from(JSON.stringify(value)), 'application/json');
  }

  async listJson(prefix: string): Promise<unknown[]> {
    const normalizedPrefix = prefix.replace(/^\/+|\/+$/g, '');
    const parent = normalizedPrefix.includes('/')
      ? normalizedPrefix.slice(0, normalizedPrefix.lastIndexOf('/'))
      : normalizedPrefix;
    const response = await fetch(`${this.baseUrl}/storage/v1/object/list/${encodeURIComponent(this.bucket)}`, {
      method: 'POST',
      headers: this.headers('application/json'),
      body: JSON.stringify({ prefix: normalizedPrefix, limit: 1000, offset: 0, sortBy: { column: 'name', order: 'asc' } }),
    });
    await this.assertOk(response, 'list');
    const items = await response.json() as SupabaseListItem[];
    const values: unknown[] = [];

    for (const item of items) {
      if (!item.name?.endsWith('.json')) continue;
      const key = item.name.includes('/') ? item.name : `${parent}/${item.name}`;
      const objectResponse = await fetch(this.objectUrl(key), { headers: this.headers() });
      if (!objectResponse.ok) continue;
      try {
        values.push(JSON.parse(await objectResponse.text()) as unknown);
      } catch {
        // Ignore malformed metadata objects.
      }
    }
    return values;
  }
}

export function createEvidenceStorage(): EvidenceStorage {
  const supabaseUrl = process.env.FLEETOS_EVIDENCE_SUPABASE_URL?.trim();
  const supabaseBucket = process.env.FLEETOS_EVIDENCE_SUPABASE_BUCKET?.trim();
  const supabaseServiceRoleKey = process.env.FLEETOS_EVIDENCE_SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (supabaseUrl || supabaseBucket || supabaseServiceRoleKey) {
    if (!supabaseUrl || !supabaseBucket || !supabaseServiceRoleKey) {
      throw new Error('Supabase evidence storage requires project URL, bucket and service role key');
    }
    return new SupabaseEvidenceStorage(supabaseUrl, supabaseServiceRoleKey, supabaseBucket);
  }

  const bucket = process.env.FLEETOS_EVIDENCE_S3_BUCKET?.trim();
  if (bucket) {
    const accessKeyId = process.env.FLEETOS_EVIDENCE_S3_ACCESS_KEY_ID?.trim() ?? '';
    const secretAccessKey = process.env.FLEETOS_EVIDENCE_S3_SECRET_ACCESS_KEY?.trim() ?? '';
    if (!accessKeyId || !secretAccessKey) {
      throw new Error('S3 evidence storage requires access key ID and secret access key');
    }
    return new S3EvidenceStorage(bucket, {
      region: process.env.FLEETOS_EVIDENCE_S3_REGION?.trim() || 'auto',
      endpoint: process.env.FLEETOS_EVIDENCE_S3_ENDPOINT?.trim() || undefined,
      accessKeyId,
      secretAccessKey,
      forcePathStyle: process.env.FLEETOS_EVIDENCE_S3_FORCE_PATH_STYLE === 'true',
    });
  }

  return new LocalEvidenceStorage(process.env.FLEETOS_EVIDENCE_DIR?.trim() || './data/evidence');
}
