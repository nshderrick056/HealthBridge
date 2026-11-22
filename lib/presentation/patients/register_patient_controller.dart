import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/providers.dart';
import '../../sync/sync_service.dart';

class RegisterPatientState {
  const RegisterPatientState({this.sex, this.consent = false});

  final String? sex;
  final bool consent;
}

/// The register / edit patient form's choices, and saving the patient.
/// Keyed by the patient being edited; null registers a new one.
class RegisterPatientController extends Notifier<RegisterPatientState> {
  RegisterPatientController(this.editing);

  final Patient? editing;

  // An existing patient already gave consent when they were registered.
  @override
  RegisterPatientState build() =>
      RegisterPatientState(sex: editing?.sex, consent: editing != null);

  void setSex(String sex) =>
      state = RegisterPatientState(sex: sex, consent: state.consent);

  void setConsent(bool consent) =>
      state = RegisterPatientState(sex: state.sex, consent: consent);

  /// Saves on the phone (with its outbox row) and starts an upload if online.
  Future<void> save({
