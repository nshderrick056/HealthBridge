
import 'dart:convert';

import '../db.dart';

class DraftsRepository {
  DraftsRepository(
    this._db, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> save(
    String screen,
    Map<String, Object?> data,
  ) async {
    if (screen.trim().isEmpty) {
      throw ArgumentError('A draft key is required.');
    }

    await _db.into(_db.drafts).insertOnConflictUpdate(
          DraftsCompanion.insert(
            id: screen,
            screen: screen,
            dataJson: jsonEncode(data),
            updatedAt: _now(),
          ),
        );
  }

  Future<Map<String, Object?>?> load(
    String screen,
  ) async {
    if (screen.trim().isEmpty) return null;

    final row = await (_db.select(_db.drafts)
          ..where((table) => table.id.equals(screen)))
        .getSingleOrNull();

    if (row == null) return null;

    try {
      final decoded = jsonDecode(row.dataJson);

      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } on FormatException {
      // An unreadable draft should not crash the visit screen.
    } on TypeError {
      // Ignore draft data with an incompatible structure.
    }

    return null;
  }

  Future<void> delete(String screen) async {
    if (screen.trim().isEmpty) return;

    await (_db.delete(_db.drafts)
          ..where((table) => table.id.equals(screen)))
        .go();
  }
}
