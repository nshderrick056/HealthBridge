import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../domain/entities/supervision.dart';
import '../view_models.dart';

final chwHistoryProvider = FutureProvider.autoDispose
    .family<ChwHistory, String>(
      (ref, id) => ref.watch(supervisionRepositoryProvider).chw(id),
    );

final patientHistoryProvider = FutureProvider.autoDispose
    .family<PatientHistory, String>(
      (ref, id) => ref.watch(supervisionRepositoryProvider).patient(id),
    );

/// The supervisor's patient search text.
class PatientSearchController extends Notifier<String> {
  @override
  String build() => '';

  void search(String text) => state = text.trim();
}

final patientSearchProvider = NotifierProvider<PatientSearchController, String>(
  PatientSearchController.new,
);

final centrePatientsProvider = FutureProvider.autoDispose<List<PatientRow>>((
  ref,
) async {
  final query = ref.watch(patientSearchProvider);
  final repo = ref.watch(supervisionRepositoryProvider);
  // Wait for typing to pause; a newer query rebuilds this provider, so the old one stops here.
  if (query.isNotEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!ref.mounted) return const [];
  }
  return repo.patients(query: query);
});

const _visitType = {
  'maternal': 'Maternal Health',
  'child': 'Child Health',
  'malaria': 'Malaria',
  'nutrition': 'Malnutrition',
};

String _when(DateTime? d) => d == null ? '' : '${relativeDay(d)} ${clock(d)}';

Widget _loading() => const Padding(
  padding: EdgeInsets.all(24),
  child: Center(child: CircularProgressIndicator()),
);

