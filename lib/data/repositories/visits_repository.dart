import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/visit_repository.dart';
import '../db.dart';
import '../forms/danger_signs.dart';
import '../models.dart';

class VisitsRepository implements VisitRepository {
  VisitsRepository(this._db, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  /// Saves a finished visit, its ticked danger signs and its outbox row in one transaction.
  /// `isUrgent` is derived from [signCodes] here, so the UI cannot get it out of step with the signs.
  @override
  Future<Visit> record({
    required String patientId,
    required VisitType type,
    Map<String, Object?> answers = const {},
    List<String> signCodes = const [],
    String? notes,
    DateTime? followUpOn,
    DateTime? recordedAt,
  }) {
    final id = _uuid.v4();
    final codes = signCodes.toSet().toList()..sort();
    return _db.transaction(() async {
      final visit = await _db
          .into(_db.visits)
          .insertReturning(
            VisitsCompanion.insert(
              id: id,
              shortCode: id.substring(0, 8),
              patientId: patientId,
              type: type,
              answersJson: Value(jsonEncode(answers)),
              notes: Value(notes),
              isUrgent: Value(isUrgent(codes)),
              followUpOn: Value(followUpOn),
              recordedAt: recordedAt ?? _now(),
              syncState: const Value(SyncState.queued),
            ),
          );
      await _db.batch(
        (b) => b.insertAll(_db.visitDangerSigns, [
          for (final c in codes)
            VisitDangerSignsCompanion.insert(visitId: id, code: c),
        ]),
      );
      await _db
          .into(_db.outbox)
          .insert(
