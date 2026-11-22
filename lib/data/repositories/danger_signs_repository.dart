
import 'package:drift/drift.dart';

import '../db.dart';
import '../models.dart';

class DangerSignsRepository {
  DangerSignsRepository(this._db);

  final AppDatabase _db;

  Future<List<DangerSign>> forType(VisitType type) {
    return (_db.select(_db.dangerSigns)
          ..where(
            (table) => table.visitType.equalsValue(type),
          )
          ..orderBy([
            (table) => OrderingTerm.asc(table.code),
          ]))
        .get();
  }

  Future<void> replaceAll(
    List<DangerSignsCompanion> signs,
  ) async {
    if (signs.isEmpty) {
      throw ArgumentError(
        'Cannot replace danger signs with an empty list.',
      );
    }

    await _db.transaction(() async {
      await _db.delete(_db.dangerSigns).go();

      await _db.batch((batch) {
        batch.insertAll(
          _db.dangerSigns,
          signs,
        );
      });
    });
  }
}
