import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings.dart';
import '../../data/db.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'visit_form.dart';

/// No `==` override on purpose: every change is a new object, so watchers rebuild even though
/// [form] itself is edited in place.
class RecordVisitState {
  const RecordVisitState({this.patientId, this.form, this.signs = const []});

  final String? patientId;

  /// Null until the patient's form (and any saved draft) has loaded.
  final VisitForm? form;

  /// The danger signs offered for the form's visit type.
  final List<DangerSign> signs;
}

/// The record-visit form: which patient, what has been entered, and the autosaved draft.
/// Keyed by the patient the screen was opened for (null opens the patient picker).
class RecordVisitController extends Notifier<RecordVisitState> {
  RecordVisitController(this.initialPatientId);

  final String? initialPatientId;
  var _opening = false;

  @override
  RecordVisitState build() => RecordVisitState(patientId: initialPatientId);

  String get draftKey => 'visit.record.${state.patientId}';

  /// Loads the patient's form, restoring a half-filled draft. Returns null when a form is already
  /// opening: the screen's first build and the picker can both ask, and there is one form per screen.
  Future<VisitForm?> open(Patient p) async {
    if (_opening) return null;
    _opening = true;
    state = RecordVisitState(patientId: p.id);
    final form = VisitForm(
      patient: p,
      type: ref.read(settingsProvider).defaultVisitType,
    );
    final draft = await ref
        .read(draftsRepositoryProvider)
        .load('visit.record.${p.id}');
    // Half-filled forms survive a crash or an app switch, with their own visit type.
    if (draft != null) form.restore(draft);
    final signs = await ref
        .read(dangerSignsRepositoryProvider)
        .forType(form.type);
    if (!ref.mounted) return null;
    state = RecordVisitState(patientId: p.id, form: form, signs: signs);
