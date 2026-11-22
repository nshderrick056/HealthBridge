import 'package:drift/drift.dart';

import 'forms/danger_signs.dart';
import 'models.dart';
import 'db_connection.dart';

part 'db.g.dart';

// Backend Schema section 2. Times are UTC; ids are UUID v4 generated on the phone.

class Patients extends Table {
  TextColumn get id => text()();
  TextColumn get shortId => text().unique()(); // e.g. P3FA9C1, safe for SMS
  TextColumn get fullName => text()();
  TextColumn get sex => text().nullable()(); // F | M
  DateTimeColumn get birthDate => dateTime().nullable()();
  IntColumn get ageEstimate => integer().nullable()();
  TextColumn get village => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get consentAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set when the CHW archives the patient (the app's "delete"); the record and visits are kept.
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(Constant(SyncState.local.name))();

  @override
  Set<Column> get primaryKey => {id};
}

