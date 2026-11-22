
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/db.dart';
import '../../data/providers.dart';
import '../record/record_visit_screen.dart';
import '../shell/app_shell.dart';
import '../view_models.dart';
import 'patient_profile_controller.dart';
import 'register_patient_screen.dart';
import 'visit_detail_screen.dart';

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({
    super.key,
    required this.patientId,
  });

  final String patientId;

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive this patient?'),
        content: Text(
          '${patient.fullName} will be removed from '
          'the active patient list. Their visit history '
          'will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final actions = ref.read(patientActionsProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final archived = await actions.archive(patient);

      if (!context.mounted) return;

      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text('${patient.fullName} archived.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await actions.restore(archived);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not restore the patient.',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not archive the patient. Try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientResult = ref.watch(allPatientsProvider);
    final visitResult = ref.watch(allVisitsProvider);

    if (patientResult.isLoading || visitResult.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final patients = patientResult.value ?? const [];
    final visits = visitResult.value ?? const [];

    Patient? patient;
    for (final item in patients) {
      if (item.id == patientId) {
        patient = item;
        break;
      }
    }

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient profile'),
        ),
        body: Center(
          child: Text(
            'This patient could not be found.',
            style: HbText.bodyMedium,
          ),
        ),
      );
    }

    final view = PatientView(
      patient,
      visits.where(
        (visit) => visit.patientId == patientId,
      ).toList(),
    );

    final latest = view.latest;
    final due = latest?.followUpOn;

    final expanded = ref.watch(
      historyExpandedProvider(patientId),
    );

    final history = expanded
        ? view.visits
        : view.visits.take(3).toList();

    final firstName = patient.fullName.trim().isEmpty
        ? 'patient'
        : patient.fullName.trim().split(RegExp(r'\s+')).first;

    void open(Widget screen) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => screen,
        ),
      );
    }

    return Scaffold(
      body: PageBody(
        children: [
          Row(
            children: [
              HbCircleButton(
                icon: Icons.chevron_left,
                tooltip: 'Back',
                onPressed: () =>
                    Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              HbCircleButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit patient',
                onPressed: () => open(
                  RegisterPatientScreen(patient: patient),
                ),
              ),
              const SizedBox(width: 10),
              HbCircleButton(
                icon: Icons.archive_outlined,
                tooltip: 'Archive patient',
                onPressed: () =>
                    _archive(context, ref, patient!),
              ),
            ],
          ),

          HbGradientCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HbAvatar(
                      patient.fullName,
                      kind: AvatarKind.lime,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.fullName,
                            style:
                                HbText.headingLarge.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            [
                              if (view.ageSex.isNotEmpty)
                                view.ageSex,
                              patient.village,
                            ].join(' · '),
                            style:
                                HbText.bodySmall.copyWith(
                              color: HbColors.onBrand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(
                  height: 1,
                  color: Color(0x33FFFFFF),
                ),
                const SizedBox(height: 12),

                Text(
                  switch (view.status) {
                    StatusKind.urgent =>
                      'Urgent at the last visit',
                    StatusKind.attention =>
                      'Needs attention',
                    _ when due != null =>
                      'Follow-up scheduled ${fullDate(due)}',
                    _ => 'Last visit: ${view.when}',
                  },
                  style: HbText.headingSmall.copyWith(
                    color: view.status == StatusKind.urgent
                        ? Colors.white
                        : HbColors.lime,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  latest == null
                      ? 'No visits yet · ID ${patient.shortId}'
                      : '${visitTypeLabel(latest.type)} · '
                          'ID ${patient.shortId}',
                  style: HbText.bodySmall.copyWith(
                    color: HbColors.onBrand,
                  ),
                ),
              ],
            ),
          ),

          HbButton.primary(
            'Record visit for $firstName',
            icon: Icons.add,
            onPressed: () => open(
              RecordVisitScreen(patientId: patientId),
            ),
          ),

          if (history.isEmpty)
            HbCard(
              child: Text(
                'No visits have been recorded for this patient.',
                style: HbText.bodyMedium,
              ),
            )
          else ...[
            SectionHeading(
              'Visits',
              action: view.visits.length > 3
                  ? expanded
                      ? 'Show less'
                      : 'View all'
                  : null,
              onAction: () => ref
                  .read(
                    historyExpandedProvider(patientId)
                        .notifier,
                  )
                  .toggle(),
            ),

            HbCard(
              padding:
                  const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final (index, visit)
                      in history.indexed) ...[
                    if (index > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        child: HbDivider(),
                      ),
                    InkWell(
                      onTap: () => open(
                        VisitDetailScreen(
                          visitId: visit.id,
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          18, 12, 18, 12,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${fullDate(visit.recordedAt.toLocal())} '
                                    '· ${visitTypeLabel(visit.type)}',
                                    style:
                                        HbText.headingSmall,
                                  ),
                                ),
                                if (visit.isUrgent)
                                  Text(
                                    'Urgent',
                                    style:
                                        HbText.labelMedium
                                            .copyWith(
                                      color: HbColors.red,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              visit.notes?.trim().isNotEmpty ==
                                      true
                                  ? visit.notes!.trim()
                                  : 'No notes recorded.',
                              style: HbText.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar:
          const SubPageNav(current: 1),
    );
  }
}
