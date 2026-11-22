import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/db.dart';
import 'patients_screen.dart';
import 'register_patient_controller.dart';

/// Registers a patient, or edits [patient] when given. Not in the Figma file (it only has the
/// "Register patient" button); built from the same components.
/// Stateful only to own the text controllers; the choices live in [RegisterPatientController].
class RegisterPatientScreen extends ConsumerStatefulWidget {
  const RegisterPatientScreen({super.key, this.patient});

  final Patient? patient;

  @override
  ConsumerState<RegisterPatientScreen> createState() =>
      _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends ConsumerState<RegisterPatientScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.patient?.fullName);
  late final _village = TextEditingController(text: widget.patient?.village);
  late final _age = TextEditingController(
    text: widget.patient?.ageEstimate?.toString(),
  );
  late final _phone = TextEditingController(text: widget.patient?.phone);

  bool get _editing => widget.patient != null;

  @override
  void dispose() {
    for (final c in [_name, _village, _age, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(registerPatientProvider(widget.patient).notifier)
          .save(
            fullName: _name.text,
            village: _village.text,
            age: _age.text,
            phone: _phone.text,
          );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the patient. Try again.')),
      );
