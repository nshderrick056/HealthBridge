import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../shell/app_shell.dart';
import '../view_models.dart';
import 'review_visit_controller.dart';
import 'urgent_detected_screen.dart';
import 'record_saved_screen.dart';
import 'visit_form.dart';

class ReviewVisitScreen extends ConsumerWidget {
  const ReviewVisitScreen({
    super.key,
    required this.form,
    required this.draftKey,
  });

  final VisitForm form;
  final String draftKey;

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final visit = await ref
          .read(submitVisitProvider.notifier)
          .submit(form, draftKey);
      final next = visit.isUrgent
          ? UrgentDetectedScreen(visitId: visit.id)
          : RecordSavedScreen(visitId: visit.id);
      await navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => next),
        (r) => r.isFirst,
      );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the visit. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = form;
    final busy = ref.watch(submitVisitProvider);
    final online = ref.watch(isOnlineProvider);
    final labels =
        ref.watch(dangerSignLabelsProvider).value ?? const <String, String>{};
    final symptoms = f.symptoms
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final urgent = f.signs.isNotEmpty;
    final now = DateTime.now();
    return Scaffold(
      bottomNavigationBar: const SubPageNav(current: 2),
      body: PageBody(
        children: [
          const HbStepBar(step: 'Step 3 / 3'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check and save', style: HbText.headingLarge),
              const SizedBox(height: 4),
              Text(
                '${f.patient.fullName} · today ${clock(now)}',
                style: HbText.bodySmall,
              ),
            ],
          ),
          if (urgent)
            HbCard(
