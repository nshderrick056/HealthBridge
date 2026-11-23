'use client';
import { useRouter } from 'next/navigation';
import { useState, type FormEvent } from 'react';

const MESSAGES: Record<string, string> = {
  invalid_credentials: 'Wrong email or password.',
  invalid_request: 'Enter your email and a password of at least 8 characters.',
  too_many_attempts: 'Too many attempts. Wait 15 minutes, then try again.',
  not_supervisor: 'This account cannot use the dashboard. CHWs use the HealthBridge app.',
  must_change: 'You are using the temporary password from the SMS. Sign in to the HealthBridge app first to choose your own.',
  api_unreachable: 'Cannot reach the HealthBridge server. Check your connection and try again.',
};
