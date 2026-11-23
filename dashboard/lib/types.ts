// Response shapes of the supervisor API (server/src/supervisor/routes.ts).

export type AlertStatus = 'new' | 'reviewed' | 'escalated' | 'follow_up' | 'resolved';
export type Channel = 'internet' | 'sms';
export type VisitType = 'maternal' | 'child' | 'malaria' | 'nutrition';

export type AlertSummary = {
  id: string;
  status: AlertStatus;
  channel: Channel;
  createdAt: string;
  ackedToChwAt: string | null;
  isPartial: boolean;
  visit: { id: string; type: VisitType; recordedAt: string };
  patient: { shortId: string; name: string | null };
  chw: { id: string; name: string };
  village: string | null;
  dangerSigns: string[];
};

export type AlertList = { alerts: AlertSummary[]; counts: Record<AlertStatus, number> };

export type AlertEvent = {
  id: string;
  fromStatus: AlertStatus | null;
  toStatus: AlertStatus;
  note: string | null;
  actor: string | null;
  createdAt: string;
};

export type AlertDetail = {
  id: string;
  status: AlertStatus;
  channel: Channel;
  createdAt: string;
  ackedToChwAt: string | null;
  next: AlertStatus[];
  visit: {