
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../shell/app_shell.dart';
import '../view_models.dart';

class VisitDetailScreen extends ConsumerWidget {
  const VisitDetailScreen({
    super.key,
    required this.visitId,
  });

  final String visitId;

  Map<String, dynamic> _answers(String raw) {
    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      // Keep the rest of the visit visible.
    }

    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(
      visitDetailProvider(visitId),
    );

    final labels =
        ref.watch(dangerSignLabelsProvider).value ??
        const <String, String>{};

    if (result.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final detail = result.value;

    if (result.hasError || detail == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Visit details'),
        ),
        body: Center(
          child: Text(
            'This visit could not be found.',
            style: HbText.bodyMedium,
          ),
        ),
      );
    }

    final visit = detail.visit;
    final answers = _answers(visit.answersJson);

    final temperature = answers['temperature'];
    final condition = answers['general_condition'];
    final symptoms =
        answers['symptoms']?.toString().trim() ?? '';

    final recordedAt = visit.recordedAt.toLocal();

    final syncLabel = switch (visit.syncState) {
      SyncState.synced => 'Sent to the server',
      SyncState.failed =>
        'Could not be sent. Retry from Sync.',
      SyncState.local => 'Saved on this device',
      SyncState.queued => 'Waiting to send',
    };

    return Scaffold(
      bottomNavigationBar:
          const SubPageNav(current: 1),
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
            ],
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                visitTypeLabel(visit.type),
                style: HbText.headingLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${detail.patient.fullName} · '
                '${fullDate(recordedAt)} '
                '${clock(recordedAt)}',
                style: HbText.bodySmall,
              ),
            ],
          ),

          if (visit.isUrgent)
            HbCard(
              color: HbColors.red,
              shadow: false,
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This visit was marked urgent.',
                      style: HbText.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (detail.signs.isNotEmpty) ...[
            const SectionHeading('Danger signs'),
            HbCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  for (final code in detail.signs)
                    BulletLine(
                      labels[code] ?? code,
                      HbColors.red,
                    ),
                ],
              ),
            ),
          ],

          const SectionHeading('What was recorded'),

          HbCard(
            child: Column(
              children: [
                DetailRow(
                  'Visit type',
                  visitTypeLabel(visit.type),
                ),

                if (temperature != null) ...[
                  const SizedBox(height: 12),
                  DetailRow(
                    'Temperature',
                    '$temperature °C',
                  ),
                ],

                if (condition != null) ...[
                  const SizedBox(height: 12),
                  DetailRow(
                    'General condition',
                    condition.toString(),
                  ),
                ],

                if (visit.followUpOn != null) ...[
                  const SizedBox(height: 12),
                  DetailRow(
                    'Follow-up',
                    fullDate(
                      visit.followUpOn!.toLocal(),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                DetailRow(
                  'Sync',
                  syncLabel,
                  valueColor:
                      visit.syncState == SyncState.synced
                          ? HbColors.brand
                          : HbColors.warning,
                ),
              ],
            ),
          ),

          if (symptoms.isNotEmpty) ...[
            const SectionHeading(
              'Symptoms and observations',
            ),
            HbCard(
              child: Text(
                symptoms,
                style: HbText.bodyMedium,
              ),
            ),
          ],

          if (visit.notes?.trim().isNotEmpty == true) ...[
            const SectionHeading('Notes'),
            HbCard(
              child: Text(
                visit.notes!.trim(),
                style: HbText.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
