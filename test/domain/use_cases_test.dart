import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_bridge/data/db.dart';
import 'package:health_bridge/data/repositories/patients_repository.dart';
import 'package:health_bridge/data/repositories/visits_repository.dart';
import 'package:health_bridge/domain/entities/enums.dart';
import 'package:health_bridge/domain/usecases/patient_use_cases.dart';
import 'package:health_bridge/domain/usecases/record_visit.dart';

void main() {
  late AppDatabase db;
  late PatientsRepository patients;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    patients = PatientsRepository(db);
  });
  tearDown(() => db.close());

  group('SavePatient', () {
    test('cleans the form text when registering', () async {
      final p = await SavePatient(patients)(
        fullName: '  Uwase Marie ',
        village: ' Nyamata',
        sex: 'F',
        age: ' 32 ',
        phone: '   ',
      );
      expect(p.fullName, 'Uwase Marie');
      expect(p.village, 'Nyamata');
      expect(p.ageEstimate, 32);
      expect(p.phone, isNull);
    });

    test('edits the given patient instead of creating one', () async {
      final save = SavePatient(patients);
      final p = await save(fullName: 'Uwase Marie', village: 'Nyamata');
      await save(
        editing: p,
        fullName: 'Uwase Marie-Claire',
        village: 'Nyamata',
        age: 'not a number',
        phone: '+250780000200',
      );
      final rows = await db.select(db.patients).get();
      expect(rows, hasLength(1));
