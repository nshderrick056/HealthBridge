
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/providers.dart';
import '../../sync/sync_service.dart';

class RegisterPatientState {
  const RegisterPatientState({
    this.sex,
    this.consent = false,
    this.busy = false,
  });

  final String? sex;
  final bool consent;
  final bool busy;

  RegisterPatientState copyWith({
    String? Function()? sex,
    bool? consent,
    bool? busy,
  }) {
    return RegisterPatientState(
      sex: sex != null ? sex() : this.sex,
      consent: consent ?? this.consent,
      busy: busy ?? this.busy,
    );
  }
}

class RegisterPatientController
    extends Notifier<RegisterPatientState> {
  RegisterPatientController(this.editing);

  final Patient? editing;

  @override
  RegisterPatientState build() {
    return RegisterPatientState(
      sex: editing?.sex,
      consent: editing != null,
    );
  }

  void setSex(String sex) {
    if (state.busy) return;
    if (sex != 'F' && sex != 'M') return;

    state = state.copyWith(sex: () => sex);
  }

  void setConsent(bool consent) {
    if (state.busy || editing != null) return;

    state = state.copyWith(consent: consent);
  }

  Future<void> save({
    required String fullName,
    required String village,
    required String age,
    required String phone,
  }) async {
    if (state.busy) return;

    if (!state.consent) {
      throw StateError(
        'Patient consent is required before registration.',
      );
    }

    final name = fullName.trim();
    final location = village.trim();

    if (name.isEmpty || location.isEmpty) {
      throw ArgumentError(
        'Patient name and village are required.',
      );
    }

    state = state.copyWith(busy: true);

    try {
      await ref.read(savePatientProvider).call(
            editing: editing,
            fullName: name,
            village: location,
            sex: state.sex,
            age: age.trim(),
            phone: phone.trim(),
          );

      // Local saving succeeds independently of network availability.
      final syncNow = ref.read(syncNowProvider);
      unawaited(
        syncNow().catchError(
          (Object error, StackTrace stackTrace) {},
        ),
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(busy: false);
      }
    }
  }
}

final registerPatientProvider =
    NotifierProvider.autoDispose.family<
      RegisterPatientController,
      RegisterPatientState,
      Patient?
    >(
      RegisterPatientController.new,
    );

String? validateAge(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) return null;

  final age = int.tryParse(text);

  if (age == null || age < 0 || age > 130) {
    return 'Enter the age in whole years (0 to 130)';
  }

  return null;
}
