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