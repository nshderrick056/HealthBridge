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
