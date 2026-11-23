// Server side only (route handlers and proxy.ts). The API tokens live in httpOnly cookies, so
// browser JavaScript never sees them; the browser talks to /api/*, which forwards to API_URL.
import type { NextResponse } from 'next/server';

export const ACCESS_COOKIE = 'hb_access';
export const REFRESH_COOKIE = 'hb_refresh';
export const NAME_COOKIE = 'hb_name';
/** 'supervisor' or 'admin'. Only picks which pages to show; the API checks the role on every call. */
export const ROLE_COOKIE = 'hb_role';
export type DashboardRole = 'supervisor' | 'admin';

export function apiUrl() {
  const url = process.env.API_URL;
  if (!url) throw new Error('API_URL is not set');
  return url.replace(/\/+$/, '');
}
