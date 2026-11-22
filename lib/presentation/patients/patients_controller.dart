import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../view_models.dart';

enum PatientFilter { all, followUp, urgent }

class PatientsQuery {
  const PatientsQuery({this.text = '', this.filter = PatientFilter.all});

  final String text;
  final PatientFilter filter;
}

/// The Patients tab's search box and filter pills.
class PatientsQueryController extends Notifier<PatientsQuery> {
  @override
  PatientsQuery build() => const PatientsQuery();

  void search(String text) =>
      state = PatientsQuery(text: text, filter: state.filter);

  void filterBy(PatientFilter filter) =>
      state = PatientsQuery(text: state.text, filter: filter);
}

final patientsQueryProvider =
    NotifierProvider.autoDispose<PatientsQueryController, PatientsQuery>(
      PatientsQueryController.new,
