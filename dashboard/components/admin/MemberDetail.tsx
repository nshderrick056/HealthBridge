'use client';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState, type ReactNode } from 'react';
import { errorText, type Member } from '@/lib/admin';
import { api, ApiError } from '@/lib/client';
import { formatDateTime } from '@/lib/format';
import { Avatar } from '../badges';
import { usePolling } from '../usePolling';

const ROLE = { chw: 'CHW', supervisor: 'Supervisor' };
const CHW_ROLE = { asm: 'ASM (maternal and newborn)', binome: 'Binôme' };

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex flex-wrap justify-between gap-x-6 gap-y-1 px-5 py-3.5 sm:px-6">
      <dt className="text-muted">{label}</dt>
      <dd className="font-medium">{children}</dd>
    </div>
  );
}

/** One member's details, with Deactivate / Activate and Delete (which asks first). */
export function MemberDetail({ id }: { id: string }) {
  const router = useRouter();
  const { data, error, reload } = usePolling<Member>(`admin/users/${id}`, 60_000);
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState<string>();

  async function run(fn: () => Promise<void>) {
    setBusy(true);
    setFailed(undefined);
    try {
      await fn();
    } catch (e) {
      setFailed(errorText(e instanceof ApiError ? e.code : 'request_failed'));
    } finally {
      setBusy(false);
    }
  }

  const setActive = (active: boolean) =>
    run(async () => {
      await api(`admin/users/${id}`, { method: 'PATCH', body: JSON.stringify({ active }) });
      await reload();
    });

  const remove = () =>
    run(async () => {
      await api(`admin/users/${id}`, { method: 'DELETE' });
      router.replace('/admin/members');
    });

  return (
    <div className="space-y-6">
      <Link
        href="/admin/members"
        className="inline-flex min-h-11 items-center gap-2 rounded-full bg-white px-4 text-[15px] font-medium shadow-card hover:bg-teal-tint"
      >
        <span aria-hidden>←</span> All members
      </Link>
      {error === 'not_found' && (
        <p className="rounded-3xl bg-white p-8 text-center text-muted shadow-card">This member no longer exists.</p>
      )}
      {error && error !== 'not_found' && !data && (
        <p role="alert" className="rounded-2xl bg-red-tint px-4 py-3 text-[15px] text-red">
          Could not load this member. Trying again shortly.
        </p>
      )}
