'use client';
import Link from 'next/link';
import { useState, type ReactNode } from 'react';
import { api, ApiError } from '@/lib/client';
import {
  describeAnswers,
  formatClock,
  formatDate,
  formatDateTime,
  POLL_MS,
  STATUS_LABEL,
  STATUS_ORDER,
  VISIT_TYPE_LABEL,
} from '@/lib/format';
import type { AlertDetail, AlertStatus } from '@/lib/types';
import { ChannelBadge, PendingTag, StatusPill } from './badges';
import { usePolling } from './usePolling';

type Action = Exclude<AlertStatus, 'new'>;

// Dark pills for the usual next steps, red only for escalating, white for the rest.
const ACTIONS: { status: Action; label: string; tone: 'dark' | 'red' | 'light' }[] = [
  { status: 'reviewed', label: 'Mark as reviewed', tone: 'dark' },
  { status: 'escalated', label: 'Escalate case', tone: 'red' },
  { status: 'follow_up', label: 'Request follow-up', tone: 'light' },
  { status: 'resolved', label: 'Mark resolved', tone: 'dark' },
];

const BUTTON = {
  dark: 'bg-ink text-white enabled:hover:bg-brand-deep',
  red: 'bg-red text-white enabled:hover:opacity-90',
  light: 'border-[1.5px] border-edge bg-white text-ink enabled:hover:bg-canvas',
};

const ERRORS: Record<string, string> = {
  status_changed: 'Someone else changed this case just now. The latest status is shown; check it and try again.',
  invalid_transition: 'This case can no longer move to that status. The latest status is shown.',
};

/** Today in Kigali as yyyy-mm-dd, the earliest follow-up date. */
const today = () => new Date(Date.now() + 2 * 3_600_000).toISOString().slice(0, 10);

export function CaseDetail({ id }: { id: string }) {
  const { data: c, error, reload } = usePolling<AlertDetail>(`alerts/${id}`, POLL_MS);
  // follow_up and resolved ask first: one needs a date, the other closes the case for good.
  const [confirming, setConfirming] = useState<Action | null>(null);
  const [note, setNote] = useState('');
  const [followUpBy, setFollowUpBy] = useState('');
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string>();

  if (!c) {
    return error === 'not_found' ? (
      <p className="rounded-3xl bg-white p-8 text-center text-muted shadow-card">
        This case does not exist or belongs to another health centre. <Link href="/alerts" className="font-semibold text-brand underline underline-offset-4">Back to alerts</Link>
      </p>
    ) : (
      <p className="text-muted" role={error ? 'alert' : undefined}>
        {error ? 'Could not load the case. Trying again in 10 seconds.' : 'Loading case…'}
      </p>
    );
  }

  async function act(status: Action) {
    if (status === 'follow_up' && !followUpBy) return setActionError('Choose a follow-up date.');
    const parts = [status === 'follow_up' ? `Follow up by ${formatDate(followUpBy)}` : '', note.trim()];
    setBusy(true);
    setActionError(undefined);
    try {
      await api(`alerts/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status, note: parts.filter(Boolean).join('. ') || undefined }),
      });
      setConfirming(null);
      setNote('');
      setFollowUpBy('');
    } catch (e) {
      setActionError(e instanceof ApiError ? (ERRORS[e.code] ?? 'Could not save. Try again.') : 'Could not save. Try again.');
    } finally {
      await reload();
      setBusy(false);
    }
  }

  const answers = describeAnswers(c.visit.answers);
  const village = c.patient.village;
  const open = c.status === 'new' || c.status === 'escalated';

