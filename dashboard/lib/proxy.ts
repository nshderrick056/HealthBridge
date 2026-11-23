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
  { method: 'POST', path: /^admin\/reset-requests\/[A-Za-z0-9_-]{1,64}\/approve$/ },
  { method: 'GET', path: /^admin\/health-centers$/ },
  { method: 'GET', path: /^admin\/health-centers\/[A-Za-z0-9_-]{1,128}$/ },
  { method: 'GET', path: /^admin\/users$/ },
  { method: 'GET', path: /^admin\/users\/[A-Za-z0-9_-]{1,128}$/ },
  { method: 'PATCH', path: /^admin\/users\/[A-Za-z0-9_-]{1,128}$/ },
  { method: 'DELETE', path: /^admin\/users\/[A-Za-z0-9_-]{1,128}$/ },
  { method: 'POST', path: /^admin\/health-centers$/ },
  { method: 'POST', path: /^admin\/users$/ },
];

const json = (body: unknown, status: number) =>
  NextResponse.json(body, { status, headers: { 'cache-control': 'no-store' } });

/** Forwards /api/<path> to the API with the session's bearer token, refreshing it once on expiry. */
export async function forward(req: NextRequest, path: string[]) {
  const target = path.join('/');
  if (!ROUTES.some((r) => r.method === req.method && r.path.test(target))) return json({ error: 'not_found' }, 404);

  const access = req.cookies.get(ACCESS_COOKIE)?.value;
  const refresh = req.cookies.get(REFRESH_COOKIE)?.value;
  const body = req.method === 'GET' ? undefined : await req.text();
