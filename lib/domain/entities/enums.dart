
// Visit categories supported by HealthBridge.
enum VisitType {
  maternal,
  child,
  malaria,
  nutrition,
}

// Local record synchronization status.
enum SyncState {
  local,
  queued,
  synced,
  failed,
}

// Progress of an urgent alert.
enum DispatchState {
  sending,
  sentSms,
  confirmed,
  unconfirmed,
}
