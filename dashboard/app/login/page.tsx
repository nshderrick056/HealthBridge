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
        className="sticky top-0 hidden h-screen w-1/2 flex-col bg-gradient-to-br from-brand to-brand-deep p-16 lg:flex"
      >
        <p className="text-2xl font-semibold tracking-tight text-lime">HealthBridge</p>
        <div className="flex min-h-0 flex-1 items-end justify-center py-6">
          <Image
            src={careTeam}