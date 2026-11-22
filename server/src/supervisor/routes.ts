// Supervisor API (PRD FR-12, FR-13, FR-15) for the web dashboard; the mobile app reads the same data from
// Firestore directly, under the security rules. Every query is scoped to the health centre in the
// caller's token, so a supervisor never sees, or learns of, another centre's cases. Status changes always
// come here (the rules forbid them from apps) so the transitions, history and CHW notice stay consistent.
// Guards sit on each route: this router is mounted at the root and must not block what it does not serve.
import { Router, type Response } from 'express';
import { FieldValue, Timestamp, type DocumentSnapshot } from 'firebase-admin/firestore';
import { z } from 'zod';
import { audit, type UserDoc } from '../accounts';
import type { Fb } from '../firebase';
import { HttpError } from '../http';
import { callerOf, requireRole, requireUser } from '../middleware/auth';
import type { SmsSender } from '../sms/gateway';
import { STUB_PATIENT_NAME } from '../sms/webhook';

const STATUSES = ['new', 'reviewed', 'escalated', 'follow_up', 'resolved'] as const;
type Status = (typeof STATUSES)[number];

// Where a case can go next. 'new' is only ever the starting state, and a resolved case stays closed.
export const TRANSITIONS: Record<Status, Status[]> = {
  new: ['reviewed', 'escalated', 'follow_up', 'resolved'],
  reviewed: ['escalated', 'follow_up', 'resolved'],
  escalated: ['follow_up', 'resolved'],
  follow_up: ['escalated', 'resolved'],
  resolved: [],
};

const listQuery = z.object({
  // 'open' is everything not yet resolved, the inbox default.
  status: z.enum([...STATUSES, 'open']).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(100),
});
const idParam = z.string().min(1).max(100);
const patchBody = z.object({
  status: z.enum(['reviewed', 'escalated', 'follow_up', 'resolved']),
  note: z.string().trim().max(500).optional(),
});

// Status changes the CHW must act on are texted at once. Only the case code, never patient details.
const CHW_NOTICE: Partial<Record<Status, (code: string) => string>> = {
  escalated: (code) => `HealthBridge: case ${code} has been escalated by the health centre.`,
  follow_up: (code) => `HealthBridge: the health centre asks you to follow up case ${code}.`,
};

const iso = (t: unknown) => (t instanceof Timestamp ? t.toDate().toISOString() : null);
// An SMS-only case has a stub patient: name unknown and no village, until the full record arrives.
const patientName = (p: { fullName?: string } | undefined) =>
  !p || p.fullName === STUB_PATIENT_NAME ? null : (p.fullName ?? null);

