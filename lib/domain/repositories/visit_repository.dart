
import '../../data/db.dart' show Visit;
import '../entities/enums.dart';

abstract interface class VisitRepository {
  Future<Visit> record({
    required String patientId,
    required VisitType type,
    Map<String, Object?> answers,
    List<String> signCodes,
    String? notes,
    DateTime? followUpOn,
    DateTime? recordedAt,
  });

  Future<Visit?> get(String id);

  Future<List<String>> signCodes(String visitId);
}
