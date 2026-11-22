
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings.dart';
import '../../data/db.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'visit_form.dart';

class RecordVisitState {
  const RecordVisitState({
    this.patientId,
    this.form,
    this.signs = const [],
  });

  final String? patientId;
  final VisitForm? form;
  final List<DangerSign> signs;
}

class RecordVisitController extends Notifier<RecordVisitState> {
  RecordVisitController(this.initialPatientId);

  final String? initialPatientId;

  bool _opening = false;
  int _typeRequest = 0;

  @override
  RecordVisitState build() {
    return RecordVisitState(
      patientId: initialPatientId,
    );
  }

  String get draftKey => 'visit.record.${state.patientId}';

  Future<VisitForm?> open(Patient patient) async {
    if (_opening) return null;

    if (state.form != null &&
        state.patientId == patient.id) {
      return state.form;
    }

    _opening = true;
    _typeRequest++;

    state = RecordVisitState(
      patientId: patient.id,
    );

    try {
      final form = VisitForm(
        patient: patient,
        type: ref.read(settingsProvider).defaultVisitType,
      );

      final draft = await ref
          .read(draftsRepositoryProvider)
          .load('visit.record.${patient.id}');

      if (draft != null) {
        form.restore(draft);
      }

      final signs = await ref
          .read(dangerSignsRepositoryProvider)
          .forType(form.type);

      if (!ref.mounted) return null;

      state = RecordVisitState(
        patientId: patient.id,
        form: form,
        signs: signs,
      );

      return form;
    } finally {
      _opening = false;
    }
  }

  void saveDraft({
    required String symptoms,
    required String temperature,
    required String notes,
  }) {
    final form = state.form;
    if (form == null) return;

    form.symptoms = symptoms;
    form.temperature =
        double.tryParse(temperature.trim());
    form.notes = notes;

    final repository = ref.read(draftsRepositoryProvider);
    final key = draftKey;
    final draft = form.toDraft();

    unawaited(
      Future<void>.sync(
        () async => repository.save(key, draft),
      ).catchError((Object error, StackTrace stack) {}),
    );
  }

  Future<void> setType(VisitType type) async {
    final form = state.form;
    if (form == null || form.type == type) return;

    form.type = type;
    form.signs.clear();

    final request = ++_typeRequest;
    _changed();

    final signs = await ref
        .read(dangerSignsRepositoryProvider)
        .forType(type);

    if (!ref.mounted ||
        request != _typeRequest ||
        state.form != form) {
      return;
    }

    state = RecordVisitState(
      patientId: state.patientId,
      form: form,
      signs: signs,
    );
  }

  void setCondition(String condition) {
    final form = state.form;
    if (form == null) return;

    if (form.condition == condition) return;

    form.condition = condition;
    _changed();
  }

  void setSign(String code, bool ticked) {
    final form = state.form;
    if (form == null) return;

    if (!state.signs.any((sign) => sign.code == code)) {
      return;
    }

    if (ticked) {
      form.signs.add(code);
    } else {
      form.signs.remove(code);
    }

    _changed();
  }

  void _changed() {
    if (!ref.mounted) return;

    state = RecordVisitState(
      patientId: state.patientId,
      form: state.form,
      signs: state.signs,
    );
  }
}

final recordVisitProvider =
    NotifierProvider.autoDispose.family<
      RecordVisitController,
      RecordVisitState,
      String?
    >(
      RecordVisitController.new,
    );
