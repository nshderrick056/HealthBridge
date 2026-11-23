import { NextResponse, type NextRequest } from 'next/server';
import { firebaseSignIn, setSession } from '@/lib/session';

export async function POST(req: NextRequest) {
  const body = (await req.json().catch(() => null)) as { email?: unknown; password?: unknown } | null;
  const { email, password } = body ?? {};
  if (typeof email !== 'string' || typeof password !== 'string' || !email || !password) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 });
  }
