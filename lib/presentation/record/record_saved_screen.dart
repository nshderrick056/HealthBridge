
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../shell/app_shell.dart';
import '../sync/sync_status_screen.dart';
import '../view_models.dart';

class RecordSavedScreen extends ConsumerWidget {
  const RecordSavedScreen({
    super.key,
    required this.visitId,
  });

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(visitDetailProvider(visitId));

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
          title: const Text('Saved visit'),
        ),
        body: Center(
          child: Text(
            'The visit details could not be loaded. '
            'Check your patient records or sync status.',
            style: HbText.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final visit = detail.visit;
    final recorded = visit.recordedAt.toLocal();

    final syncMessage = switch (visit.syncState) {
      SyncState.synced => 'Sent successfully',
      SyncState.failed => 'Upload failed · retry from Sync',
      SyncState.queued => 'Waiting to synchronize',
      SyncState.local => 'Saved locally · not yet queued',
    };

    final synced = visit.syncState == SyncState.synced;

    return Scaffold(
      bottomNavigationBar: const SubPageNav(),
      body: PageBody(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                'Visit saved',
                style: HbText.headingLarge.copyWith(
                  fontSize: 34,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${detail.patient.fullName} · '
                '${visitTypeLabel(visit.type)} · '
                '${clock(recorded)}',
                style: HbText.bodySmall,
              ),

              const SizedBox(height: 12),

              const HbPill(
                'Saved on this phone',
                icon: Icons.check,
                foreground: HbColors.brand,
              ),
            ],
          ),

          HbCard(
            child: Column(
              children: [
                DetailRow(
                  'Sync status',
                  syncMessage,
                  valueColor: synced
                      ? HbColors.brand
                      : HbColors.warning,
                ),

                const SizedBox(height: 12),

                DetailRow(
                  'Patient ID',
                  detail.patient.shortId,
                ),

                const SizedBox(height: 12),

                DetailRow(
                  'Village',
                  detail.patient.village,
                ),

                const SizedBox(height: 12),

                DetailRow(
                  'Recorded',
                  '${fullDate(recorded)} · ${clock(recorded)}',
                ),
              ],
            ),
          ),

          Text(
            synced
                ? 'This visit has been synchronized '
                    'with the server.'
                : 'The visit is stored on this device. '
                    'Keep the app available for synchronization '
                    'when a connection is available.',
            style: HbText.bodyMedium.copyWith(
              color: HbColors.muted,
            ),
          ),

          HbButton.primary(
            'Back to home',
            onPressed: () {
              ref.read(tabIndexProvider.notifier).state = 0;
              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
          ),

          HbButton.secondary(
            'View sync status',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SyncStatusScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
