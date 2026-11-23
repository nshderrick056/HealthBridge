import 'package:flutter_test/flutter_test.dart';
import 'package:health_bridge/domain/entities/supervision.dart';

void main() {
  test('a patient history reads the profile, CHW and visits from the API', () {
    final h = PatientHistory.fromJson({
      'patient': {
        'id': 'p1',
        'shortId': 'P0412',
        'name': 'Uwase Marie',
        'village': 'Nyamata',
        'sex': 'F',
        'ageEstimate': 32,
        'birthDate': null,
        'archived': false,
      },
      'chw': {'id': 'c1', 'name': 'Claudine M.', 'phone': '+250780000101'},
      'visits': [
        {
          'id': 'v1',
          'type': 'maternal',
          'recordedAt': '2026-11-10T08:00:00Z',
          'isUrgent': true,
          'isPartial': false,
          'dangerSigns': ['Heavy bleeding'],
          'temperature': 38.9,
          'condition': 'Needs attention',
          'symptoms': null,
          'notes': 'Referred',
          'followUpOn': null,
        },
      ],
    });