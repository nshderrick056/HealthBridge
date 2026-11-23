// Admin pages: what the API's /admin routes return, and the helpers the forms share.

export type ResetRequest = {
  id: string;
  userId: string;
  name: string | null;
  phone: string | null;
  role: string | null;
  createdAt: string | null;
};

export type Centre = { id: string; name: string; district: string | null };

export type Member = {
  id: string;
  role: 'chw' | 'supervisor';
  fullName: string;
  phone: string;
  email: string | null;
  chwRole: 'asm' | 'binome' | null;
