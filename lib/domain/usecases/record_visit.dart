
import '../../data/db.dart' show Visit;
import '../entities/enums.dart';
import '../repositories/visit_repository.dart';

class RecordVisit {
  RecordVisit(this._visits);

  final VisitRepository _visits;

  Future<Visit> call({
    required String patientId,
    required VisitType type,
    required Map<String, Object?> answers,
    required Iterable<String> signCodes,
    String notes = '',
  }) {
    final id = patientId.trim();

    if (id.isEmpty) {
      throw ArgumentError('A patient must be selected.');
    }

    final codes = signCodes
        .map((code) => code.trim())
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();

    final cleanedNotes = notes.trim();

    return _visits.record(
      patientId: id,
      type: type,
      answers: Map<String, Object?>.of(answers),
      signCodes: codes,
      notes: cleanedNotes.isEmpty ? null : cleanedNotes,
    );
  }
}
