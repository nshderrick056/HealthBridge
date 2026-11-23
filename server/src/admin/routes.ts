// Admin-only: health centres, accounts (there is no self sign-up), and approving reset requests.
import { randomBytes, randomInt } from 'node:crypto';
import { hash } from '@node-rs/argon2';
import { Router } from 'express';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';
import { type AccountInput, audit, createAccount, newAccountInput, phone, type UserDoc } from '../accounts';
import type { Fb } from '../firebase';
import { HttpError } from '../http';
import { callerOf, requireRole, requireUser } from '../middleware/auth';
import type { SmsSender } from '../sms/gateway';

const centreBody = z.object({
  name: z.string().trim().min(2).max(200),
  district: z.string().trim().min(1).max(100),
  sector: z.string().trim().min(1).max(100),
  callNumber: phone.optional(),
});

/** How long an approved reset code stays valid. */
export const RESET_CODE_MS = 30 * 60_000;

export function adminRouter(fb: Fb, sender: SmsSender) {
  const router = Router();
  router.use(requireUser(fb), requireRole('admin'));

  /** For the new-account form's health centre picker, by name. */
  router.get('/health-centers', async (_req, res) => {
    const snap = await fb.fs.collection('healthCenters').get();
    const centres = snap.docs.map((d) => ({ id: d.id, name: d.data().name as string, district: d.data().district ?? null }));
    centres.sort((a, b) => a.name.localeCompare(b.name));
    res.json({ centres });
  });

  router.post('/health-centers', async (req, res) => {
    const b = centreBody.parse(req.body);
    const ref = await fb.fs.collection('healthCenters').add({
      name: b.name,
      district: b.district,
      sector: b.sector,
      callNumber: b.callNumber ?? null,
    });
    await audit(fb, callerOf(res).uid, 'health_center.create', 'healthCenters', ref.id);
    res.status(201).json({ id: ref.id, name: b.name });
  });

  /**
   * The server makes a temporary PIN (CHW) and/or password (with an email) and texts them to the new
   * user, who must set their own at first sign-in. The admin never sees them.
   */
  router.post('/users', async (req, res) => {
    const b = newAccountInput.parse(req.body);
    const pin = b.role === 'chw' ? randomInt(1_000_000).toString().padStart(6, '0') : undefined;
    const password = b.email ? randomBytes(9).toString('base64url') : undefined;
    const id = await createAccount(fb, { ...b, pin, password } as AccountInput, undefined, true);
    await audit(fb, callerOf(res).uid, 'user.create', 'users', id);

    const parts = [
      pin && `PIN ${pin}`,
      password && `email ${b.email} and password ${password}`,
    ].filter(Boolean);
    let smsSent = true;
    try {
      await sender.send(
        b.phone,
        `HealthBridge: your account is ready. Sign in with ${parts.join(', or ')}. You will then choose your own.`,
      );
    } catch {
      // The account stands; the user can still get in through Forgot PIN/password.
      smsSent = false;
    }
    res.status(201).json({ id, role: b.role, fullName: b.fullName, smsSent });
  });

  /** A member (CHW or supervisor) as the admin pages show them. */
  const memberJson = (id: string, u: FirebaseFirestore.DocumentData) => ({
    id,
    role: u.role as string,
    fullName: u.fullName as string,
    phone: u.phone as string,
    email: (u.email as string | null) ?? null,
    chwRole: (u.chwRole as string | null) ?? null,
    village: (u.village as string | null) ?? null,
    healthCenterId: (u.healthCenterId as string | null) ?? null,
    active: u.active !== false,
    createdAt: (u.createdAt as Timestamp | undefined)?.toDate().toISOString() ?? null,
  });

  const members = ['chw', 'supervisor'] as const;
  const idParam = z.string().min(1).max(128);

  /** Admins manage CHWs and supervisors only; an admin account is never changed or deleted here. */
  async function member(id: unknown) {
    const ref = fb.fs.collection('users').doc(idParam.parse(id));
    const data = (await ref.get()).data();
    if (!data || !members.includes(data.role)) throw new HttpError(404, 'not_found');
    return { ref, data };
  }

  /** CHWs or supervisors, by name, each with the name of their health centre. */
  router.get('/users', async (req, res) => {
    const role = z.enum(members).parse(req.query.role);
    const [users, centres] = await Promise.all([
      fb.fs.collection('users').where('role', '==', role).get(),
      fb.fs.collection('healthCenters').get(),
    ]);
    const names = new Map(centres.docs.map((c) => [c.id, c.data().name as string]));
    const list = users.docs
      .map((d) => ({ ...memberJson(d.id, d.data()), healthCenterName: names.get(d.data().healthCenterId) ?? null }))
      .sort((a, b) => a.fullName.localeCompare(b.fullName));

