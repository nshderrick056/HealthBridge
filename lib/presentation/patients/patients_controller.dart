
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../view_models.dart';

enum PatientFilter {
  all,
  followUp,
  urgent,
}

class PatientsQuery {
  const PatientsQuery({
    this.text = '',
    this.filter = PatientFilter.all,
  });

  final String text;
  final PatientFilter filter;

  PatientsQuery copyWith({
    String? text,
    PatientFilter? filter,
  }) {
    return PatientsQuery(
      text: text ?? this.text,
      filter: filter ?? this.filter,
    );
  }
}

class PatientsQueryController extends Notifier<PatientsQuery> {
  @override
  PatientsQuery build() => const PatientsQuery();

  void search(String text) {
    if (state.text == text) return;

    state = state.copyWith(text: text);
  }

  void filterBy(PatientFilter filter) {
    if (state.filter == filter) return;

    state = state.copyWith(filter: filter);
  }

  void clear() {
    state = const PatientsQuery();
  }
}

final patientsQueryProvider =
    NotifierProvider.autoDispose<
      PatientsQueryController,
      PatientsQuery
    >(
      PatientsQueryController.new,
    );

List<PatientView> filterPatients(
  List<PatientView> all,
  PatientsQuery query,
) {
  final search = query.text.trim().toLowerCase();

  final filtered = all.where((view) {
    final patient = view.patient;

    final matchesSearch = search.isEmpty ||
        patient.fullName.toLowerCase().contains(search) ||
        patient.village.toLowerCase().contains(search) ||
        patient.shortId.toLowerCase().contains(search) ||
        patient.id.toLowerCase().contains(search);

    if (!matchesSearch) return false;

    return switch (query.filter) {
      PatientFilter.all => true,
      PatientFilter.followUp =>
        view.status == StatusKind.followUp,
      PatientFilter.urgent =>
        view.status == StatusKind.urgent,
    };
  }).toList();

  filtered.sort(
    (first, second) => first.patient.fullName
        .toLowerCase()
        .compareTo(second.patient.fullName.toLowerCase()),
  );

  return filtered;
}

final visiblePatientsProvider =
    Provider.autoDispose<List<PatientView>>((ref) {
  final patients =
      ref.watch(allPatientsProvider).value ?? const [];

  final visits =
      ref.watch(allVisitsProvider).value ?? const [];

  final query = ref.watch(patientsQueryProvider);

  final views = buildPatientViews(patients, visits);

  return filterPatients(views, query);
});

