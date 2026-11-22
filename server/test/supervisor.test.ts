import { randomUUID } from 'node:crypto';
import { Timestamp } from 'firebase-admin/firestore';
import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import { bearer, centre, chw, clearEmulators, fb, idToken, makeApp, supervisor } from './emulator';

const { app, sender } = makeApp();
const { fs } = fb;
let supA: string;
let supB: string;

beforeAll(async () => {
  await clearEmulators();
  await centre('hc-a');
  await centre('hc-b');
  await chw('chw-a', 'hc-a', '+250780000501');
  await supervisor('sup-a', 'hc-a', '+250780000502');
  await supervisor('sup-b', 'hc-b', '+250780000503');
  await fs.collection('dangerSigns').doc('HB').set({ visitType: 'maternal', labelEn: 'Heavy bleeding', labelRw: '' });
  supA = bearer(await idToken('sup-a'));
  supB = bearer(await idToken('sup-b'));
});

/** An urgent visit from chw-a with its alert; [minutes] orders them in time. */
async function urgentCase(minutes: number, channel = 'internet') {
  const visitId = randomUUID();
  const patientId = randomUUID();
  await fs.collection('patients').doc(patientId).set({
    shortId: `P${minutes}`,
    chwId: 'chw-a',
    healthCenterId: 'hc-a',
    fullName: 'Uwase Marie',
    village: 'Nyamata',
  });
  await fs.collection('visits').doc(visitId).set({
    shortCode: visitId.slice(0, 8),
    patientId,
    chwId: 'chw-a',
    healthCenterId: 'hc-a',
    deviceId: 'D000001',
    type: 'maternal',
    dangerSigns: ['HB'],
    isUrgent: true,
    isPartial: false,
    recordedAt: Timestamp.fromMillis(Date.UTC(2026, 9, 6, 19, minutes)),
  });
  await fs.collection('alerts').doc(visitId).set({
    visitId,
    chwId: 'chw-a',
    healthCenterId: 'hc-a',
    channel,
    status: 'new',
    createdAt: Timestamp.fromMillis(Date.UTC(2026, 9, 6, 19, minutes)),
    ackedToChwAt: null,
  });
  return visitId;
}

