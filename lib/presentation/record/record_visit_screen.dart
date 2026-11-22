import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/db.dart';
import '../../data/forms/validation.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../patients/patients_screen.dart';
import '../shell/app_shell.dart';
import '../view_models.dart';
import 'record_visit_controller.dart';
import 'review_visit_screen.dart';
import 'visit_form.dart';

/// Stateful only to own the text controllers; the form lives in [RecordVisitController].
class RecordVisitScreen extends ConsumerStatefulWidget {
  const RecordVisitScreen({super.key, this.patientId});

  final String? patientId;

  @override
  ConsumerState<RecordVisitScreen> createState() => _RecordVisitScreenState();
}

class _RecordVisitScreenState extends ConsumerState<RecordVisitScreen> {
  final _symptoms = TextEditingController();
  final _temperature = TextEditingController();
  final _notes = TextEditingController();
  final _key = GlobalKey<FormState>();

  RecordVisitController get _controller =>
      ref.read(recordVisitProvider(widget.patientId).notifier);

  @override
  void dispose() {
    for (final c in [_symptoms, _temperature, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _open(Patient p) async {
    final form = await _controller.open(p);
    if (form == null || !mounted) return;
    _symptoms.text = form.symptoms;
    _temperature.text = form.temperature?.toString() ?? '';
    _notes.text = form.notes;
  }

  void _save() => _controller.saveDraft(
    symptoms: _symptoms.text,
    temperature: _temperature.text,
    notes: _notes.text,
  );

  void _review(VisitForm form) {
    if (!_key.currentState!.validate()) return;
    _save();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReviewVisitScreen(form: form, draftKey: _controller.draftKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(allPatientsProvider).value ?? const [];
    final visits = ref.watch(allVisitsProvider).value ?? const <Visit>[];
    final state = ref.watch(recordVisitProvider(widget.patientId));
    final id = state.patientId;
    if (id != null && state.form == null) {
      final p = patients.where((p) => p.id == id);
      if (p.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(p.first));
      }
    }
