import { cookies } from 'next/headers';
import type { ReactNode } from 'react';
import { NAME_COOKIE } from '@/lib/session';
import { NavLinks, type Section } from './NavLinks';

const initials = (name: string) => {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '?';
  return (parts[0][0] + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
};
