
import '../../data/db.dart' show Patient;

abstract interface class PatientRepository {
  Future<Patient> create({
    required String fullName,
    required String village,
    String? sex,
    DateTime? birthDate,
    int? ageEstimate,
    String? phone,
    DateTime? consentAt,
  });

  Future<Patient> update(Patient patient);

  Future<Patient> archive(Patient patient);

  Future<Patient> restore(Patient patient);

  Future<Patient?> get(String id);
}
