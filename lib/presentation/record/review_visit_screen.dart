
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../shell/app_shell.dart';
import '../view_models.dart';
import 'record_saved_screen.dart';
import 'review_visit_controller.dart';
import 'urgent_detected_screen.dart';
import 'visit_form.dart';

class ReviewVisitScreen extends ConsumerWidget {
  const ReviewVisitScreen({
    super.key,
    required this.form,
    required this.draftKey,
  });

  final VisitForm form;
  final String draftKey;

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (ref.read(submitVisitProvider)) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final visit = await ref
          .read(submitVisitProvider.notifier)
          .submit(form, draftKey);

      if (!context.mounted) return;

      final Widget destination = visit.isUrgent
          ? UrgentDetectedScreen(visitId: visit.id)
          : RecordSavedScreen(visitId: visit.id);

      await Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => destination,
        ),
        (route) => route.isFirst,
      );
    } catch (_) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the visit. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(submitVisitProvider);
    final online = ref.watch(isOnlineProvider);
    final labels =
        ref.watch(dangerSignLabelsProvider).value ??
        const <String, String>{};

    final symptoms = form.symptoms
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final urgent = form.signs.isNotEmpty;

    return Scaffold(
      bottomNavigationBar: const SubPageNav(current: 2),
      body: PageBody(
        children: [
          const HbStepBar(step: 'Step 3 / 3'),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check and save',
                style: HbText.headingLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${form.patient.fullName} · '
                '${fullDate(DateTime.now())}',
                style: HbText.bodySmall,
              ),
            ],
          ),

          if (urgent)
            HbCard(
              color: HbColors.red,
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This visit is urgent',
                    style: HbText.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'After saving, send the alert to '
                    'the health centre.',
                    style: HbText.bodySmall.copyWith(
                      color: HbColors.onRed,
                    ),
                  ),
                ],
              ),
            ),

          const SectionHeading('Visit information'),

          HbCard(
            child: Column(
              children: [
                DetailRow(
                  'Visit type',
                  visitTypeLabel(form.type),
                ),

                if (urgent) ...[
                  const SizedBox(height: 12),
                  DetailRow(
                    'Danger signs',
                    [
                      for (final code in form.signs)
                        labels[code] ?? code,
                    ].join(', '),
                    valueColor: HbColors.red,
                  ),
                ],

                if (form.temperature != null) ...[
                  const SizedBox(height: 12),
                  DetailRow(
                    'Temperature',
                    '${form.temperature} °C',
                  ),
                ],

                const SizedBox(height: 12),
                DetailRow(
                  'General condition',
                  form.condition,
                ),
              ],
            ),
          ),

          if (symptoms.isNotEmpty) ...[
            const SectionHeading(
              'Symptoms and observations',
            ),
            HbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final symptom in symptoms)
                    BulletLine(
                      symptom,
                      HbColors.brand,
                    ),
                ],
              ),
            ),
          ],

          if (form.notes.trim().isNotEmpty) ...[
            const SectionHeading('Notes'),
            HbCard(
              child: Text(
                form.notes.trim(),
                style: HbText.bodyMedium,
              ),
            ),
          ],

          HbPill(
            online
                ? 'Online · sync will be attempted'
                : urgent
                    ? 'Offline · urgent alert can use SMS'
                    : 'Offline · saved locally for later sync',
            dot: online
                ? HbColors.brand
                : HbColors.amberMark,
          ),

          HbButton.primary(
            busy ? 'Saving visit...' : 'Save visit',
            onPressed: busy
                ? null
                : () => _submit(context, ref),
          ),

          HbButton.secondary(
            'Edit information',
            onPressed: busy
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
