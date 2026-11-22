
import 'package:drift/drift.dart' show Value;

import '../../data/db.dart' show Patient;
import '../repositories/patient_repository.dart';

class SavePatient {
  SavePatient(this._patients);

  final PatientRepository _patients;

  Future<Patient> call({
    Patient? editing,
    required String fullName,
    required String village,
    String? sex,
    String age = '',
    String phone = '',
  }) {
    final name = fullName.trim();
    final location = village.trim();
    final ageText = age.trim();
    final phoneText = phone.trim();

    if (name.isEmpty || location.isEmpty) {
      throw ArgumentError(
        'Patient name and village are required.',
      );
    }

    final ageEstimate =
        ageText.isEmpty ? null : int.tryParse(ageText);

    if (ageText.isNotEmpty &&
        (ageEstimate == null ||
            ageEstimate < 0 ||
            ageEstimate > 130)) {
      throw ArgumentError(
        'Age must be between 0 and 130 years.',
      );
    }

    if (sex != null && sex != 'M' && sex != 'F') {
      throw ArgumentError('Invalid patient sex.');
    }

    final phoneOrNull =
        phoneText.isEmpty ? null : phoneText;

    if (editing == null) {
      return _patients.create(
        fullName: name,
        village: location,
        sex: sex,
        ageEstimate: ageEstimate,
        phone: phoneOrNull,
      );
    }

    return _patients.update(
      editing.copyWith(
        fullName: name,
        village: location,
        sex: Value(sex),
        ageEstimate: Value(ageEstimate),
        phone: Value(phoneOrNull),
      ),
    );
  }
}

class ArchivePatient {
  ArchivePatient(this._patients);

  final PatientRepository _patients;

  Future<Patient> call(Patient patient) {
    return _patients.archive(patient);
  }

  Future<Patient> undo(Patient patient) {
    return _patients.restore(patient);
  }
}
