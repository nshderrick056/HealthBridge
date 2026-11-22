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
      );
      expect((await later.get(p.id))!.village, 'Other Village');
      expect(await db.select(db.outbox).get(), hasLength(2));
    });

    test('watch filters by name, short ID and village', () async {
      final p = await newPatient();
      await patients.create(fullName: 'Someone Else', village: 'Far Hill');
      expect(
        (await patients.watch(query: 'far').first).map((x) => x.fullName),
        ['Someone Else'],
      );
      expect((await patients.watch(query: p.shortId).first).map((x) => x.id), [
        p.id,
      ]);
      expect(await patients.watch().first, hasLength(2));
    });
  });

  group('visits', () {
    test(
      'an urgent visit gets its short code, signs and one outbox row',
      () async {
        final p = await newPatient();
        final v = await visits.record(
          patientId: p.id,
          type: VisitType.maternal,
          answers: {'temperature': 38.9, 'gestational_weeks': 32},
          signCodes: ['HB', 'CV', 'HB'],
        );
        expect(v.isUrgent, isTrue);
        expect(v.shortCode, v.id.substring(0, 8));
        expect(v.syncState, SyncState.queued);
        expect(await visits.signCodes(v.id), ['CV', 'HB']);

        final box = await (db.select(
          db.outbox,
        )..where((t) => t.entity.equals('visit'))).get();
        expect(box, hasLength(1));
        final payload =
            jsonDecode(box.single.payloadJson) as Map<String, dynamic>;
        expect(payload['danger_signs'], ['CV', 'HB']);
        expect(payload['answers'], containsPair('temperature', 38.9));
        expect(payload['recorded_at'], '2026-10-06T19:14:00.000Z');
