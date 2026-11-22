
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/providers.dart';
import '../../sync/sync_service.dart';

class PatientActions {
  PatientActions(this._ref);

  final Ref _ref;

  Future<Patient> archive(Patient patient) async {
    final archived = await _ref
        .read(archivePatientProvider)
        .call(patient);

    _sync();

    return archived;
  }

  Future<void> restore(Patient patient) async {
    await _ref
        .read(archivePatientProvider)
        .undo(patient);

    _sync();
  }

  void _sync() {
    final syncNow = _ref.read(syncNowProvider);

    unawaited(
      syncNow().catchError((Object error, StackTrace stack) {
        // Local changes remain queued for a later sync attempt.
      }),
    );
  }
}

final patientActionsProvider = Provider<PatientActions>(
  PatientActions.new,
);

class HistoryExpandedController extends Notifier<bool> {
  HistoryExpandedController(this.patientId);

  final String patientId;

  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void expand() {
    if (!state) state = true;
  }

  void collapse() {
    if (state) state = false;
  }
}

final historyExpandedProvider =
    NotifierProvider.autoDispose
        .family<HistoryExpandedController, bool, String>(
  HistoryExpandedController.new,
);
