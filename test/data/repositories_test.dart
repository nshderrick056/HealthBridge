import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_bridge/data/db.dart';
import 'package:health_bridge/data/forms/danger_signs.dart';
import 'package:health_bridge/data/forms/validation.dart';
import 'package:health_bridge/data/models.dart';
import 'package:health_bridge/data/repositories/danger_signs_repository.dart';
import 'package:health_bridge/data/repositories/drafts_repository.dart';
import 'package:health_bridge/data/repositories/patients_repository.dart';
import 'package:health_bridge/data/repositories/visits_repository.dart';

void main() {
  late AppDatabase db;
  late PatientsRepository patients;
  late VisitsRepository visits;

  final clock = DateTime.utc(2026, 10, 6, 19, 14);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    patients = PatientsRepository(db, now: () => clock);
    visits = VisitsRepository(db, now: () => clock);
  });
  tearDown(() => db.close());

  Future<Patient> newPatient() =>
      patients.create(fullName: 'Test Patient', village: 'Demo Village');

  group('patients', () {
    test(
      'create saves the patient and queues exactly one outbox row',
      () async {
        final p = await newPatient();
        expect(p.syncState, SyncState.queued);
        expect(p.shortId, matches(RegExp(r'^P[0-9A-F]{6}$')));
        expect(
          p.createdAt.isAtSameMomentAs(clock),
          isTrue,
        ); // drift returns local time

        final box = await db.select(db.outbox).get();
        expect(box, hasLength(1));
        expect(box.single.entity, 'patient');
        expect(box.single.entityId, p.id);
        expect(box.single.op, OutboxOp.upsert);
        expect(
          jsonDecode(box.single.payloadJson),
          containsPair('short_id', p.shortId),
        );
      },
    );

    test('update bumps updatedAt and queues another change', () async {
      final p = await newPatient();
      final later = PatientsRepository(
        db,
        now: () => clock.add(const Duration(hours: 1)),
      );
      final next = await later.update(p.copyWith(village: 'Other Village'));
      expect(
        next.updatedAt.isAtSameMomentAs(clock.add(const Duration(hours: 1))),
        isTrue,
