'use client';
import Link from 'next/link';
import { useState, type FormEvent, type ReactNode } from 'react';
import { errorText, normalizePhone, type Centre } from '@/lib/admin';
import { api, ApiError } from '@/lib/client';
import { usePolling } from '../usePolling';

type Role = 'chw' | 'supervisor';

const input =
  'mt-2 block w-full min-h-12 rounded-2xl border-[1.5px] border-edge bg-white px-4 text-base focus:border-brand focus:outline-none';

function Field({ label, hint, children }: { label: string; hint?: string; children: ReactNode }) {
  return (
    <label className="block text-[15px] font-medium">
      {label}
      {children}
      {hint && <span className="mt-1 block text-sm font-normal text-muted">{hint}</span>}
    </label>
  );
}

/**
 * Creates a CHW (phone, optional email) or a supervisor (phone + email). The server makes a temporary
 * PIN and/or password and texts it; the admin never sees it, and the person sets their own at first sign-in.
 */
export function NewAccount() {
  const { data } = usePolling<{ centres: Centre[] }>('admin/health-centers', 60_000);
  const [role, setRole] = useState<Role>('chw');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [centre, setCentre] = useState('');
  const [chwRole, setChwRole] = useState<'asm' | 'binome'>('asm');
  const [village, setVillage] = useState('');
  const [email, setEmail] = useState('');
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; text: string }>();

  const intl = normalizePhone(phone);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setResult(undefined);
    if (fullName.trim().length < 2) return setResult({ ok: false, text: 'Enter the full name (2 letters or more).' });
    if (!intl) return setResult({ ok: false, text: 'Enter a phone number, e.g. 0788 123 456.' });
    if (!centre) return setResult({ ok: false, text: 'Choose a health centre.' });
    if (role === 'chw' && !village.trim()) return setResult({ ok: false, text: 'Enter the village.' });
    if (role === 'supervisor' && !email.trim()) return setResult({ ok: false, text: 'A supervisor needs an email.' });
    setBusy(true);
    try {
