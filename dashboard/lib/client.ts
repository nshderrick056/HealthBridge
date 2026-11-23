// Browser side: every call goes to this app's /api/*, which adds the session token (lib/proxy.ts).

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
  ) {
    super(code);
  }
}
