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
    final form = state.form;

    return Scaffold(
      bottomNavigationBar: const SubPageNav(current: 2),
      body: form == null
          ? _picker(patients, visits)
          : _formBody(form, state.signs, visits),
    );
  }

  // Same status as every other screen, from the patient's own visits.
  PatientView _view(Patient p, List<Visit> visits) =>
      PatientView(p, visits.where((v) => v.patientId == p.id).toList());

  Widget _picker(List<Patient> patients, List<Visit> visits) {
    final views = [for (final p in patients) _view(p, visits)];
    bool isDue(PatientView v) =>
        v.status == StatusKind.followUp || v.status == StatusKind.attention;
    final due = views.where(isDue).toList();
    final others = views.where((v) => !isDue(v)).toList();
    Widget card(List<PatientView> list) => HbCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final (i, v) in list.indexed) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: HbDivider(),
              ),
            PatientRow(view: v, onTap: () => _open(v.patient)),
          ],
        ],
      ),
    );
    return PageBody(
      children: [
        const HbStepBar(step: 'Step 1 / 3'),
        Text('Who is this visit for?', style: HbText.headingLarge),
        if (patients.isEmpty)
          Text('Register a patient first.', style: HbText.bodySmall),
        if (due.isNotEmpty) ...[const SectionHeading('Due today'), card(due)],
        if (others.isNotEmpty) ...[
          SectionHeading(due.isEmpty ? 'Your patients' : 'Everyone else'),
          card(others),
        ],
      ],
    );
  }

  Widget _formBody(VisitForm f, List<DangerSign> signs, List<Visit> visits) {
    final view = _view(f.patient, visits);
    return Form(
      key: _key,
      onChanged: _save,
      child: PageBody(
        children: [
          const HbStepBar(step: 'Step 2 / 3'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record visit', style: HbText.headingLarge),
              const SizedBox(height: 4),
              Text(
                [
                  f.patient.fullName,
                  if (view.ageSex.isNotEmpty) view.ageSex,
                  'today',
                ].join(' · '),
                style: HbText.bodySmall,
              ),
            ],
          ),
          const SectionHeading('Visit type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in VisitType.values)
                HbChoice(
                  visitTypeLabel(t),
                  selected: f.type == t,
                  onTap: () {
                    _controller.setType(t);
                    _save();
                  },
                ),
            ],
          ),
          if (signs.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading('Danger signs'),
                Text(
                  'Tick any you see. Any danger sign makes this visit urgent.',
                  style: HbText.bodySmall,
                ),
              ],
            ),
            HbCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final (i, s) in signs.indexed) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: HbDivider(),
                      ),
                    _SignRow(
                      label: s.labelEn,
                      ticked: f.signs.contains(s.code),
                      onChanged: (v) {
                        _controller.setSign(s.code, v);
                        _save();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SectionHeading('Measurements'),
          HbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HbTextField(
                  label: 'Temperature (°C)',
