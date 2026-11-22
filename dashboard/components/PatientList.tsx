'use client';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { formatDateTime, timeAgo } from '@/lib/format';
import { ageSex, type PatientRow } from '@/lib/history';
import { Avatar } from './badges';
import { ChevronIcon } from './icons';
import { usePolling } from './usePolling';

/** The centre's patients, latest visit first, with a search over name, ID and village. */
export function PatientList() {
  const [text, setText] = useState('');
  const [q, setQ] = useState('');
  // Search after typing pauses, not on every key.
  useEffect(() => {
    const t = setTimeout(() => setQ(text.trim()), 300);
    return () => clearTimeout(t);
  }, [text]);
  const { data, error } = usePolling<{ patients: PatientRow[] }>(
    q ? `patients?q=${encodeURIComponent(q)}` : 'patients',
    60_000,
  );

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">
          Patients {data && <span className="text-xl font-normal text-muted">{data.patients.length}</span>}
        </h1>
        <p className="mt-1 text-muted">Everyone your CHWs follow, latest visit first.</p>
      </header>
      <label className="block max-w-md">
        <span className="sr-only">Search patients</span>
        <input
          type="search"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Name, patient ID or village"
          className="block min-h-12 w-full rounded-full bg-white px-5 text-base shadow-card focus:outline-2 focus:outline-brand"
        />
      </label>
      {error && !data && (
        <p role="alert" className="rounded-2xl bg-red-tint px-4 py-3 text-[15px] text-red">
          Could not load the patients. Trying again shortly.
