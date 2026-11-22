
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

class RecordVisitScreen extends ConsumerStatefulWidget {
  const RecordVisitScreen({
    super.key,
    this.patientId,
  });

  final String? patientId;

  @override
  ConsumerState<RecordVisitScreen> createState() =>
      _RecordVisitScreenState();
}

class _RecordVisitScreenState
    extends ConsumerState<RecordVisitScreen> {
  final _symptoms = TextEditingController();
  final _temperature = TextEditingController();
  final _notes = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _opening = false;
  String? _error;

  RecordVisitController get _controller =>
      ref.read(
        recordVisitProvider(widget.patientId).notifier,
      );

  @override
  void dispose() {
    _symptoms.dispose();
    _temperature.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _open(Patient patient) async {
    if (_opening) return;

    setState(() {
      _opening = true;
      _error = null;
    });

    try {
      final form = await _controller.open(patient);

      if (!mounted || form == null) return;

      _symptoms.text = form.symptoms;
      _temperature.text =
          form.temperature?.toString() ?? '';
      _notes.text = form.notes;
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load this visit. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  void _saveDraft() {
    final state = ref.read(
      recordVisitProvider(widget.patientId),
    );

    if (state.form == null) return;

    _controller.saveDraft(
      symptoms: _symptoms.text,
      temperature: _temperature.text,
      notes: _notes.text,
    );
  }

  void _review(VisitForm form) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    _saveDraft();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewVisitScreen(
          form: form,
          draftKey: _controller.draftKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientResult = ref.watch(allPatientsProvider);
    final visitResult = ref.watch(allVisitsProvider);

    final patients = patientResult.value ?? const <Patient>[];
    final visits = visitResult.value ?? const <Visit>[];

    final state = ref.watch(
      recordVisitProvider(widget.patientId),
    );

    final patientId = state.patientId;

    if (patientId != null &&
        state.form == null &&
        !_opening &&
        _error == null) {
      Patient? selected;

      for (final patient in patients) {
        if (patient.id == patientId) {
          selected = patient;
          break;
        }
      }

      if (selected != null) {
        final patient = selected;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_opening) {
            _open(patient);
          }
        });
      }
    }

    return Scaffold(
      bottomNavigationBar:
          const SubPageNav(current: 2),
      body: _error != null
          ? _errorBody()
          : state.form == null
              ? patientResult.isLoading ||
                      visitResult.isLoading ||
                      _opening
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _picker(patients, visits)
              : _formBody(
                  state.form!,
                  state.signs,
                  visits,
                ),
    );
  }

  Widget _errorBody() {
    return PageBody(
      children: [
        Text(
          'Unable to open visit',
          style: HbText.headingLarge,
        ),
        Text(
          _error!,
          style: HbText.bodyMedium,
        ),
        HbButton.primary(
          'Try again',
          onPressed: () {
            setState(() {
              _error = null;
            });
          },
        ),
      ],
    );
  }

  PatientView _view(
    Patient patient,
    List<Visit> visits,
  ) {
    return PatientView(
      patient,
      visits
          .where(
            (visit) => visit.patientId == patient.id,
          )
          .toList(),
    );
  }

  Widget _picker(
    List<Patient> patients,
    List<Visit> visits,
  ) {
    final views = [
      for (final patient in patients)
        _view(patient, visits),
    ];

    bool isDue(PatientView view) {
      return view.status == StatusKind.followUp ||
          view.status == StatusKind.attention;
    }

    final due = views.where(isDue).toList();
    final others =
        views.where((view) => !isDue(view)).toList();

    Widget patientCard(List<PatientView> items) {
      return HbCard(
        padding:
            const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final (index, view) in items.indexed) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  child: HbDivider(),
                ),
              PatientRow(
                view: view,
                onTap: () => _open(view.patient),
              ),
            ],
          ],
        ),
      );
    }

    return PageBody(
      children: [
        const HbStepBar(step: 'Step 1 / 3'),

        Text(
          'Who is this visit for?',
          style: HbText.headingLarge,
        ),

        if (patients.isEmpty)
          Text(
            'Register a patient before recording a visit.',
            style: HbText.bodySmall,
          ),

        if (due.isNotEmpty) ...[
          const SectionHeading('Due today'),
          patientCard(due),
        ],

        if (others.isNotEmpty) ...[
          SectionHeading(
            due.isEmpty ? 'Your patients' : 'Everyone else',
          ),
          patientCard(others),
        ],
      ],
    );
  }

  Widget _formBody(
    VisitForm form,
    List<DangerSign> signs,
    List<Visit> visits,
  ) {
    final view = _view(form.patient, visits);

    return Form(
      key: _formKey,
      onChanged: _saveDraft,
      child: PageBody(
        children: [
          const HbStepBar(step: 'Step 2 / 3'),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record visit',
                style: HbText.headingLarge,
              ),
              const SizedBox(height: 4),
              Text(
                [
                  form.patient.fullName,
                  if (view.ageSex.isNotEmpty)
                    view.ageSex,
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
              for (final type in VisitType.values)
                HbChoice(
                  visitTypeLabel(type),
                  selected: form.type == type,
                  onTap: () {
                    _controller.setType(type);
                    _saveDraft();
                  },
                ),
            ],
          ),

          if (signs.isNotEmpty) ...[
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SectionHeading('Danger signs'),
                Text(
                  'Select any signs you observe. '
                  'A danger sign marks the visit as urgent.',
                  style: HbText.bodySmall,
                ),
              ],
            ),

            HbCard(
              padding:
                  const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final (index, sign)
                      in signs.indexed) ...[
                    if (index > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        child: HbDivider(),
                      ),
                    _SignRow(
                      label: sign.labelEn,
                      ticked:
                          form.signs.contains(sign.code),
                      onChanged: (selected) {
                        _controller.setSign(
                          sign.code,
                          selected,
                        );
                        _saveDraft();
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                HbTextField(
                  label: 'Temperature (°C)',
                  hint: 'e.g. 37.2',
                  controller: _temperature,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return null;
                    }

                    return temperatureC.check(
                      double.tryParse(value.trim()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Text(
                  'General condition',
                  style: HbText.labelMedium,
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final condition
                        in const ['Stable', needsAttention])
                      HbChoice(
                        condition,
                        selected:
                            form.condition == condition,
                        onTap: () {
                          _controller.setCondition(condition);
                          _saveDraft();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),

          HbTextField(
            label: 'Symptoms / observations',
            hint: 'What did you observe?',
            controller: _symptoms,
            maxLines: 3,
          ),

          HbTextField(
            label: 'Notes',
            hint: 'Anything else to record',
            controller: _notes,
            maxLines: 3,
          ),

          if (form.signs.isNotEmpty)
            Text(
              form.signs.length == 1
                  ? '1 danger sign selected: '
                      'this visit is urgent.'
                  : '${form.signs.length} danger signs '
                      'selected: this visit is urgent.',
              style: HbText.labelMedium.copyWith(
                color: HbColors.red,
              ),
            ),

          HbButton.primary(
            'Review visit',
            onPressed: () => _review(form),
          ),
        ],
      ),
    );
  }
}

class _SignRow extends StatelessWidget {
  const _SignRow({
    required this.label,
    required this.ticked,
    required this.onChanged,
  });

  final String label;
  final bool ticked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: ticked,
      child: InkWell(
        onTap: () => onChanged(!ticked),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: ticked
                      ? HbColors.red
                      : HbColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: ticked
                      ? null
                      : Border.all(
                          color: HbColors.edge,
                          width: 2,
                        ),
                ),
                child: ticked
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  label,
                  style: HbText.bodyMedium.copyWith(
                    fontSize: 17,
                    color: ticked
                        ? HbColors.red
                        : HbColors.ink,
                    fontWeight: ticked
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
