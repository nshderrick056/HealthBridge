'use client';
import Link from 'next/link';
import { useState } from 'react';
import type { Member } from '@/lib/admin';
import { Avatar } from '../badges';
import { ChevronIcon } from '../icons';
import { usePolling } from '../usePolling';

const TABS = [
  { role: 'chw', label: 'CHWs' },
  { role: 'supervisor', label: 'Supervisors' },
] as const;

/** Every CHW or supervisor in two tabs; a member opens their own page. */
export function Members() {
  const [role, setRole] = useState<'chw' | 'supervisor'>('chw');
  const { data, error } = usePolling<{ members: Member[] }>(`admin/users?role=${role}`, 60_000);

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">Members</h1>
          <p className="mt-1 max-w-3xl text-muted">
            Click a member to see their details, switch their account off, or delete it.
          </p>
        </div>
        <Link
          href="/admin/members/new"
          className="inline-flex min-h-12 items-center rounded-full bg-ink px-6 font-semibold text-white hover:bg-brand-deep"
        >
          Add a member
        </Link>
      </header>

      <div role="tablist" aria-label="Member type" className="flex gap-2">
        {TABS.map((t) => (
          <button
            key={t.role}
            type="button"
            role="tab"
            aria-selected={role === t.role}
            onClick={() => setRole(t.role)}
            className={`min-h-11 rounded-full px-5 text-[15px] ${
              role === t.role ? 'bg-ink font-semibold text-white' : 'bg-white text-ink shadow-card hover:bg-teal-tint'
            }`}
          >
            {t.label}
            {data && role === t.role && <span className="ml-2 text-white/75">{data.members.length}</span>}
          </button>
        ))}
      </div>

      {error && !data && (
        <p role="alert" className="rounded-2xl bg-red-tint px-4 py-3 text-[15px] text-red">
          Could not load the members. Trying again shortly.
        </p>
      )}
      {!data && !error && <p className="text-muted">Loading…</p>}
      {data && data.members.length === 0 && (
