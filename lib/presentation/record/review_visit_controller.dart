
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/providers.dart';
import '../../sync/sync_service.dart';
import 'visit_form.dart';

class SubmitVisitController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<Visit> submit(
    VisitForm form,
    String draftKey,
  ) async {
    if (state) {
      throw StateError(
        'A visit is already being saved.',
      );
    }

    state = true;

    try {
      final visit = await ref
          .read(recordVisitUseCaseProvider)
          .call(
            patientId: form.patient.id,
            type: form.type,
            answers: form.answers,
            signCodes: form.signs,
            notes: form.notes,
          );

      // The visit is already saved locally at this point.
      final drafts = ref.read(draftsRepositoryProvider);

      try {
        await drafts.delete(draftKey);
      } catch (_) {
        // Draft cleanup can be retried independently.
      }

      final syncNow = ref.read(syncNowProvider);

      unawaited(
        syncNow().catchError(
          (Object error, StackTrace stackTrace) {},
        ),
      );

      return visit;
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}

final submitVisitProvider =
    NotifierProvider.autoDispose<
      SubmitVisitController,
      bool
    >(
      SubmitVisitController.new,
    );
