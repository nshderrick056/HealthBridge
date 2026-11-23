import { NextResponse, type NextRequest } from 'next/server';
import { ACCESS_COOKIE, apiUrl, clearSession, refreshAccess, REFRESH_COOKIE, setSession } from './session';

// Only the routes the dashboard's pages use are reachable; anything else is a 404 here. The API
// still checks the caller's role on each one (supervisor routes, admin routes).
const ROUTES: { method: string; path: RegExp }[] = [
  { method: 'GET', path: /^alerts$/ },
  { method: 'GET', path: /^alerts\/[0-9a-f-]{36}$/ },
  { method: 'PATCH', path: /^alerts\/[0-9a-f-]{36}$/ },
  { method: 'GET', path: /^chws$/ },
  { method: 'GET', path: /^chws\/[A-Za-z0-9_-]{1,128}$/ },
  { method: 'GET', path: /^patients$/ },
  { method: 'GET', path: /^patients\/[A-Za-z0-9_-]{1,128}$/ },
  { method: 'GET', path: /^admin\/reset-requests$/ },