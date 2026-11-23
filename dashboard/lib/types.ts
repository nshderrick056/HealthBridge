// Response shapes of the supervisor API (server/src/supervisor/routes.ts).

export type AlertStatus = 'new' | 'reviewed' | 'escalated' | 'follow_up' | 'resolved';
export type Channel = 'internet' | 'sms';
export type VisitType = 'maternal' | 'child' | 'malaria' | 'nutrition';
