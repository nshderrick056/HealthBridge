import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/patient_repository.dart';
import '../db.dart';
import '../models.dart';

/// Every write puts the patient row and its outbox row in one transaction, so a record is never
/// saved without being queued for upload (or the other way round).
class PatientsRepository implements PatientRepository {
  PatientsRepository(this._db, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  @override
  Future<Patient> create({
    required String fullName,
    required String village,
    String? sex,
    DateTime? birthDate,
    int? ageEstimate,
    String? phone,
    DateTime? consentAt,
  }) {
    final now = _now();
    final id = _uuid.v4();
    return _db.transaction(() async {
      final row = PatientsCompanion.insert(
        id: id,
        shortId: 'P${id.substring(0, 6).toUpperCase()}',
        fullName: fullName,
        village: village,
        sex: Value(sex),
        birthDate: Value(birthDate),
        ageEstimate: Value(ageEstimate),
        phone: Value(phone),
        consentAt: consentAt ?? now,
        createdAt: now,
        updatedAt: now,
        syncState: const Value(SyncState.queued),
      );
      final patient = await _db.into(_db.patients).insertReturning(row);
      await _enqueue(patient);
      return patient;
    });
  }

  @override
  Future<Patient> update(Patient p) {
    return _db.transaction(() async {
      final next = p.copyWith(updatedAt: _now(), syncState: SyncState.queued);
      await _db.update(_db.patients).replace(next);
      await _enqueue(next);
      return next;
