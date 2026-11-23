import { cookies } from 'next/headers';
import type { ReactNode } from 'react';
import { NAME_COOKIE } from '@/lib/session';
import { NavLinks, type Section } from './NavLinks';

const initials = (name: string) => {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '?';
  return (parts[0][0] + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
};

function SignOut({ className = '' }: { className?: string }) {
  return (
    <form action="/api/auth/logout" method="post">
      <button
        type="submit"
        className={`min-h-11 rounded-full border border-white/25 px-5 text-[15px] font-medium text-white hover:bg-white/10 ${className}`}
      >
        Sign out
      </button>
    </form>
  );
}
