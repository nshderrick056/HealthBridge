'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { AlertIcon, HospitalIcon, KeyIcon, UserIcon, UserPlusIcon } from './icons';

export type Section = 'supervisor' | 'admin';

const LINKS = {
  supervisor: [
    { href: '/alerts', label: 'Urgent alerts', short: 'Alerts', Icon: AlertIcon },
    { href: '/chws', label: 'Community health workers', short: 'CHWs', Icon: UserIcon },
    { href: '/patients', label: 'Patients', short: 'Patients', Icon: HospitalIcon },
  ],
  admin: [
    { href: '/admin/resets', label: 'Reset requests', short: 'Resets', Icon: KeyIcon },
    { href: '/admin/members', label: 'Members', short: 'Members', Icon: UserPlusIcon },
    { href: '/admin/centres', label: 'Health centres', short: 'Centres', Icon: HospitalIcon },
  ],
};

/** The dark sidebar's links; the current one is a lime pill. Horizontal in the phone top bar. */
export function NavLinks({ section = 'supervisor', vertical = false }: { section?: Section; vertical?: boolean }) {
  const path = usePathname();
  return (
    <nav aria-label="Main" className={vertical ? 'flex flex-col gap-1' : 'flex gap-1 overflow-x-auto'}>
      {LINKS[section].map(({ href, label, short, Icon }) => {
        const active = path === href || path.startsWith(`${href}/`);