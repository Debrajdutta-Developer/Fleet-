import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { GetObjectCommand, ListObjectsV2Command, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';

export interface EvidenceStorage {
  readonly kind: 'local' | 's3';
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

export function createEvidenceStorage(): EvidenceStorage {
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
