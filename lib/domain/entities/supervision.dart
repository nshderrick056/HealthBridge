// What supervisors and admins see, as the HealthBridge API returns it (server/src/supervisor and admin).

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();

/// Where a case is; the server decides which moves are allowed.
enum AlertStatus {
  newCase('new', 'New'),
  reviewed('reviewed', 'Reviewed'),
  escalated('escalated', 'Escalated'),
  followUp('follow_up', 'Follow-up'),
  resolved('resolved', 'Resolved');

  const AlertStatus(this.wire, this.label);
  final String wire;
  final String label;

  static AlertStatus parse(String wire) =>
      values.firstWhere((s) => s.wire == wire, orElse: () => newCase);
}

class AlertSummary {
  AlertSummary.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      status = AlertStatus.parse(j['status'] as String),
      channel = j['channel'] as String,
      createdAt = _date(j['createdAt']),
      isPartial = j['isPartial'] as bool? ?? false,
      visitType = (j['visit'] as Map?)?['type'] as String?,
      patientShortId = (j['patient'] as Map?)?['shortId'] as String?,
      patientName = (j['patient'] as Map?)?['name'] as String?,
      chwName = (j['chw'] as Map?)?['name'] as String?,
      village = j['village'] as String?,
      dangerSigns = ((j['dangerSigns'] as List?) ?? const []).cast<String>();

  final String id;
  final AlertStatus status;

  /// internet | sms
  final String channel;
  final DateTime? createdAt;

  /// Reached the health centre by SMS only; the full visit has not arrived yet.
  final bool isPartial;
  final String? visitType;
  final String? patientShortId;

  /// Null while the case came by SMS only (the name is not in the SMS).
  final String? patientName;
  final String? chwName;
  final String? village;
  final List<String> dangerSigns;
}

