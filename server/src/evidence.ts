import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { randomUUID } from 'node:crypto';
import type { IncomingMessage } from 'node:http';
import type { TenantPrincipal } from './tenantAuth.js';

export type EvidenceType = 'fuel_receipt' | 'toll_receipt' | 'repair_receipt' | 'pod' | 'weighment' | 'other';

export interface TripEvidenceRecord {
  id: string;
  companyId: string;
  tripId: string;
  uploadedBy: string;
  uploaderRole: TenantPrincipal['role'];
  evidenceType: EvidenceType;
  originalFileName: string;
  contentType: string;
  sizeBytes: number;
  storagePath: string;
  createdAt: string;
}

const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'application/pdf']);
const MAX_BYTES = 10 * 1024 * 1024;
const EVIDENCE_TYPES = new Set<EvidenceType>(['fuel_receipt', 'toll_receipt', 'repair_receipt', 'pod', 'weighment', 'other']);

function safeSegment(value: string): string {
  const normalized = value.trim().replace(/[^A-Za-z0-9._-]/g, '_');
  if (!normalized) throw new Error('invalid evidence path segment');
  return normalized.slice(0, 120);
}

async function readBinary(req: IncomingMessage): Promise<Buffer> {
  const chunks: Buffer[] = [];
  let total = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > MAX_BYTES) throw new Error('evidence file exceeds 10 MB limit');
    chunks.push(buffer);
  }
  if (!total) throw new Error('evidence file is empty');
  return Buffer.concat(chunks);
}

export class EvidenceStore {
  constructor(private readonly root = process.env.FLEETOS_EVIDENCE_DIR?.trim() || './data/evidence') {}

  async upload(req: IncomingMessage, principal: TenantPrincipal, tripId: string, evidenceType: string): Promise<TripEvidenceRecord> {
    if (!['driver', 'owner', 'manager', 'dispatcher', 'accountant'].includes(principal.role)) {
      throw new Error('role is not allowed to upload trip evidence');
    }
    if (!EVIDENCE_TYPES.has(evidenceType as EvidenceType)) throw new Error('unsupported evidence type');

    const rawName = String(req.headers['x-file-name'] ?? '').trim();
    if (!rawName) throw new Error('x-file-name header is required');
    const contentType = String(req.headers['content-type'] ?? '').split(';')[0].trim().toLowerCase();
    if (!ALLOWED_TYPES.has(contentType)) throw new Error('only JPEG, PNG, WEBP and PDF evidence is accepted');

    const body = await readBinary(req);
    const id = randomUUID();
    const company = safeSegment(principal.companyId);
    const trip = safeSegment(tripId);
    const fileName = `${id}${extname(rawName).toLowerCase()}`;
    const dir = join(this.root, company, trip);
    await mkdir(dir, { recursive: true });
    const storagePath = join(dir, fileName);
    await writeFile(storagePath, body, { flag: 'wx' });

    const record: TripEvidenceRecord = {
      id,
      companyId: principal.companyId,
      tripId,
      uploadedBy: principal.sub,
      uploaderRole: principal.role,
      evidenceType: evidenceType as EvidenceType,
      originalFileName: rawName.slice(0, 240),
      contentType,
      sizeBytes: body.length,
      storagePath,
      createdAt: new Date().toISOString(),
    };
    await writeFile(`${storagePath}.json`, JSON.stringify(record, null, 2), { flag: 'wx' });
    return record;
  }

  async list(companyId: string, tripId: string): Promise<TripEvidenceRecord[]> {
    const dir = join(this.root, safeSegment(companyId), safeSegment(tripId));
    let names: string[] = [];
    try {
      names = await readdir(dir);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
      throw error;
    }
    const records: TripEvidenceRecord[] = [];
    for (const name of names.filter((name) => name.endsWith('.json'))) {
      try {
        const parsed = JSON.parse(await readFile(join(dir, name), 'utf8')) as TripEvidenceRecord;
        if (parsed.companyId === companyId && parsed.tripId === tripId) records.push(parsed);
      } catch {
        // Ignore malformed metadata sidecars; never expose untrusted raw directory data.
      }
    }
    return records.sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
  }
}
