import type { Metadata } from 'next';
import Image from 'next/image';
import { LoginForm } from '@/components/LoginForm';
import careTeam from './care-team.webp';

export const metadata: Metadata = { title: 'Sign in' };

// The illustration's bottom fades into the green, as in the Figma frame's "Fade mask".
const fade = 'linear-gradient(to bottom, #000 45%, rgb(0 0 0 / 0.5) 70%, transparent 88%)';
