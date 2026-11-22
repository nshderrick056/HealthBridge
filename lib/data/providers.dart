import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_service.dart';
import 'repositories/supervision_repository.dart';
import '../domain/usecases/patient_use_cases.dart';
import '../domain/usecases/record_visit.dart';
import 'db.dart';
import 'repositories/danger_signs_repository.dart';
import 'repositories/drafts_repository.dart';
import 'repositories/patients_repository.dart';
import 'repositories/urgent_repository.dart';
import 'repositories/visits_repository.dart';

/// Must be overridden at startup with the opened database:
/// `ProviderScope(overrides: [databaseProvider.overrideWithValue(await openAppDatabase())], ...)`.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('override databaseProvider'),
);

final patientsRepositoryProvider = Provider(
  (ref) => PatientsRepository(ref.watch(databaseProvider)),
);
final visitsRepositoryProvider = Provider(
  (ref) => VisitsRepository(ref.watch(databaseProvider)),
);
final draftsRepositoryProvider = Provider(
  (ref) => DraftsRepository(ref.watch(databaseProvider)),
);
final dangerSignsRepositoryProvider = Provider(
  (ref) => DangerSignsRepository(ref.watch(databaseProvider)),
);
final urgentRepositoryProvider = Provider(
  (ref) => UrgentRepository(ref.watch(databaseProvider)),
);

/// The HealthBridge API as the signed-in user (supervisor and admin screens).
final apiClientProvider = Provider(
  (ref) => ApiClient(
    auth: ref.watch(authServiceProvider),
    session: () => ref.read(sessionProvider),
    onSession: (s) => ref.read(sessionProvider.notifier).state = s,
  ),
);
final supervisionRepositoryProvider = Provider(
  (ref) => SupervisionRepository(ref.watch(apiClientProvider)),
);
final adminRepositoryProvider = Provider(
  (ref) => AdminRepository(ref.watch(apiClientProvider)),
);

/// Domain use cases, wired to this layer's repositories (the domain only knows the interfaces).
final savePatientProvider = Provider(
  (ref) => SavePatient(ref.watch(patientsRepositoryProvider)),
);
final archivePatientProvider = Provider(
  (ref) => ArchivePatient(ref.watch(patientsRepositoryProvider)),
