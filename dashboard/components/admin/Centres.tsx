'use client';
import Link from 'next/link';
import { useState, type FormEvent } from 'react';
import { errorText, normalizePhone, type Centre } from '@/lib/admin';
import { api, ApiError } from '@/lib/client';
import { HospitalIcon } from '../icons';
import { usePolling } from '../usePolling';

const input =
  'mt-2 block w-full min-h-12 rounded-2xl border-[1.5px] border-edge bg-white px-4 text-base focus:border-brand focus:outline-none';

/** Health centres, and a form to add one. Every account belongs to one; alerts give CHWs its call number. */
export function Centres() {
  const { data, error, reload } = usePolling<{ centres: Centre[] }>('admin/health-centers', 60_000);
  const [name, setName] = useState('');
  const [district, setDistrict] = useState('');
  const [sector, setSector] = useState('');
  const [call, setCall] = useState('');
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; text: string }>();

  async function submit(e: FormEvent) {
    e.preventDefault();
    setResult(undefined);
    if (name.trim().length < 2) return setResult({ ok: false, text: 'Enter the name (2 letters or more).' });
    if (!district.trim() || !sector.trim()) return setResult({ ok: false, text: 'Enter the district and sector.' });
    const callNumber = call.trim() ? normalizePhone(call) : undefined;
    if (callNumber === null) return setResult({ ok: false, text: 'Enter the call number like 0788 000 111, or leave it empty.' });
    setBusy(true);
    try {
      await api('admin/health-centers', {
        method: 'POST',
        body: JSON.stringify({
          name: name.trim(),
          district: district.trim(),
          sector: sector.trim(),
          ...(callNumber && { callNumber }),
        }),
      });
      setResult({ ok: true, text: `${name.trim()} added.` });
      setName('');
      setDistrict('');
      setSector('');
      setCall('');
      await reload();
    } catch (err) {
      setResult({ ok: false, text: errorText(err instanceof ApiError ? err.code : 'request_failed') });
    } finally {
      setBusy(false);
    }
