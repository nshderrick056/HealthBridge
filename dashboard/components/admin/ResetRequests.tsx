'use client';
import { useState } from 'react';
import { errorText, type ResetRequest } from '@/lib/admin';
import { api, ApiError } from '@/lib/client';
import { formatDateTime, timeAgo } from '@/lib/format';
import { Avatar } from '../badges';
import { usePolling } from '../usePolling';

const ROLE: Record<string, string> = { chw: 'CHW', supervisor: 'Supervisor', admin: 'Admin' };

/** People who asked to reset their PIN or password. Approving texts them a one-time code. */
export function ResetRequests() {
  const { data, error, reload } = usePolling<{ requests: ResetRequest[] }>('admin/reset-requests', 30_000);
  const [busy, setBusy] = useState<string>();
  const [result, setResult] = useState<{ ok: boolean; text: string }>();

  async function approve(r: ResetRequest) {
    setBusy(r.id);
    setResult(undefined);
    try {
      await api(`admin/reset-requests/${r.id}/approve`, { method: 'POST' });
      setResult({ ok: true, text: `Approved. ${r.name ?? 'They'} will get a code by SMS, valid for 30 minutes.` });
    } catch (e) {
      setResult({ ok: false, text: errorText(e instanceof ApiError ? e.code : 'request_failed') });
    } finally {
      await reload();
      setBusy(undefined);
    }
  }

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">Reset requests</h1>
        <p className="mt-1 max-w-3xl text-muted">
          When you approve, the person gets a new sign-in code by SMS. Check it is really them first, by phone or in
          person.
        </p>
      </header>

      {result && (
        <p
          role={result.ok ? 'status' : 'alert'}
          className={`rounded-2xl px-4 py-3 text-[15px] ${result.ok ? 'bg-teal-tint text-brand' : 'bg-red-tint text-red'}`}
        >
          {result.text}
        </p>
      )}
      {error && !data && (
        <p role="alert" className="rounded-2xl bg-red-tint px-4 py-3 text-[15px] text-red">
