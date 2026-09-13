import { extname } from 'node:path';
import { randomUUID } from 'node:crypto';
import type { IncomingMessage } from 'node:http';
import type { TenantPrincipal } from './tenantAuth.js';
import { createEvidenceStorage, type EvidenceStorage } from './evidenceStorage.js';

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
  storageKind: EvidenceStorage['kind'];
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
  constructor(private readonly storage: EvidenceStorage = createEvidenceStorage()) {}

  get storageKind(): EvidenceStorage['kind'] {
    return this.storage.kind;
  }

  async upload(req: IncomingMessage, principal: TenantPrincipal, tripId: string, evidenceType: string): Promise<TripEvidenceRecord> {
    if (!['driver', 'khalashi', 'owner', 'manager', 'dispatcher', 'accountant'].includes(principal.role)) {
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
    const extension = extname(rawName).toLowerCase().replace(/[^.a-z0-9]/g, '');
    const prefix = `${company}/${trip}`;
    const objectKey = `${prefix}/${id}${extension}`;
    const metadataKey = `${objectKey}.json`;

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
      storagePath: objectKey,
      storageKind: this.storage.kind,
      createdAt: new Date().toISOString(),
    };

    await this.storage.put(objectKey, body, contentType);
    await this.storage.putJson(metadataKey, record);
    return record;
  }

  async list(companyId: string, tripId: string): Promise<TripEvidenceRecord[]> {
    const prefix = `${safeSegment(companyId)}/${safeSegment(tripId)}/`;
    const values = await this.storage.listJson(prefix);
    const records: TripEvidenceRecord[] = [];
    for (const value of values) {
      if (!value || typeof value !== 'object') continue;
      const parsed = value as Partial<TripEvidenceRecord>;
      if (parsed.companyId !== companyId || parsed.tripId !== tripId) continue;
      if (!parsed.id || !parsed.createdAt || !parsed.storagePath || !parsed.contentType || !parsed.evidenceType) continue;
      records.push(parsed as TripEvidenceRecord);
    }
    return records.sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
  }
}
