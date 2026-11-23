import type { Metadata } from 'next';
import Image from 'next/image';
import { LoginForm } from '@/components/LoginForm';
import careTeam from './care-team.webp';

export const metadata: Metadata = { title: 'Sign in' };

// The illustration's bottom fades into the green, as in the Figma frame's "Fade mask".
const fade = 'linear-gradient(to bottom, #000 45%, rgb(0 0 0 / 0.5) 70%, transparent 88%)';

/** Green brand panel beside the form on wide screens (Figma "Supervisor sign in"); form alone on phones. */
export default function LoginPage() {
  return (
    <main className="flex min-h-screen">
      <section
        aria-hidden