import '../../core/api/api_client.dart';
import '../../domain/entities/supervision.dart';

/// The supervisor's view of their health centre, through the HealthBridge API (which scopes every
/// call to the centre in the sign-in token). Status changes go through the server, which checks the
/// allowed moves, records who made them and texts the CHW.
class SupervisionRepository {
  SupervisionRepository(this._api);

  final ApiClient _api;

  /// [status] null lists every case; `open` everything not yet resolved.
  Future<List<AlertSummary>> alerts({String? status}) async {
    final j = await _api.get('/alerts', query: {'status': ?status});
    return [
      for (final a in j['alerts'] as List)
        AlertSummary.fromJson(a as Map<String, dynamic>),
    ];
  }

  Future<AlertDetail> alert(String id) async =>
      AlertDetail.fromJson(await _api.get('/alerts/$id'));

  Future<void> setStatus(String id, AlertStatus status, {String? note}) =>
      _api.patch('/alerts/$id', {
        'status': status.wire,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });

  Future<List<ChwSummary>> chws() async {
    final j = await _api.get('/chws');
    return [
      for (final c in j['chws'] as List)
        ChwSummary.fromJson(c as Map<String, dynamic>),
    ];
  }

  /// A CHW of the centre and their visits, newest first.
  Future<ChwHistory> chw(String id) async =>
      ChwHistory.fromJson(await _api.get('/chws/$id'));

  /// The centre's patients, latest visit first; [query] searches name, patient ID and village.
  Future<List<PatientRow>> patients({String? query}) async {
    final q = query?.trim();
    final j = await _api.get(
      '/patients',
      query: {if (q != null && q.isNotEmpty) 'q': q},
    );
    return [
      for (final p in j['patients'] as List)
        PatientRow.fromJson(p as Map<String, dynamic>),
    ];
  }

  Future<PatientHistory> patient(String id) async =>
      PatientHistory.fromJson(await _api.get('/patients/$id'));
}

