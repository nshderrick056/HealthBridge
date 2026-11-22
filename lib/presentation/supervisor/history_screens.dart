import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../domain/entities/supervision.dart';
import '../view_models.dart';

final chwHistoryProvider = FutureProvider.autoDispose
    .family<ChwHistory, String>(
      (ref, id) => ref.watch(supervisionRepositoryProvider).chw(id),
    );

final patientHistoryProvider = FutureProvider.autoDispose
    .family<PatientHistory, String>(
      (ref, id) => ref.watch(supervisionRepositoryProvider).patient(id),
    );

/// The supervisor's patient search text.
class PatientSearchController extends Notifier<String> {
  @override
  String build() => '';

  void search(String text) => state = text.trim();
}

final patientSearchProvider = NotifierProvider<PatientSearchController, String>(
  PatientSearchController.new,
);

final centrePatientsProvider = FutureProvider.autoDispose<List<PatientRow>>((
  ref,
) async {
  final query = ref.watch(patientSearchProvider);
  final repo = ref.watch(supervisionRepositoryProvider);
  // Wait for typing to pause; a newer query rebuilds this provider, so the old one stops here.
  if (query.isNotEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!ref.mounted) return const [];
  }
  return repo.patients(query: query);
});

const _visitType = {
  'maternal': 'Maternal Health',
  'child': 'Child Health',
  'malaria': 'Malaria',
  'nutrition': 'Malnutrition',
};

String _when(DateTime? d) => d == null ? '' : '${relativeDay(d)} ${clock(d)}';

Widget _loading() => const Padding(
  padding: EdgeInsets.all(24),
  child: Center(child: CircularProgressIndicator()),
);

Widget _failed(Object e, String what) => HbCard(
  child: Text(
    e.toString().contains('not_found')
        ? 'This $what does not exist or belongs to another health centre.'
        : 'Could not load this $what. Check your connection.',
    style: HbText.bodyMedium.copyWith(color: HbColors.red),
  ),
);

Widget _backRow(BuildContext context) => Row(
  children: [
    HbCircleButton(
      icon: Icons.chevron_left,
      tooltip: 'Back',
      onPressed: () => Navigator.of(context).maybePop(),
    ),
  ],
);

/// One visit with everything recorded. [onPatient] links the patient on a CHW's history.
class HistoryVisitCard extends StatelessWidget {
  const HistoryVisitCard({super.key, required this.visit, this.onPatient});

  final HistoryVisit visit;
  final VoidCallback? onPatient;

  @override
  Widget build(BuildContext context) {
    final v = visit;
    return HbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _visitType[v.type] ?? 'Visit',
                      style: HbText.headingSmall,
                    ),
                    Text(_when(v.recordedAt), style: HbText.bodySmall),
                  ],
                ),
              ),
              if (v.isUrgent) const StatusChip(StatusKind.urgent),
            ],
          ),
          if (onPatient != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onPatient,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  v.patientName ?? 'Patient ${v.patientShortId ?? ''}',
                  style: HbText.labelMedium.copyWith(
                    color: HbColors.brand,
                    decoration: TextDecoration.underline,
                    decorationColor: HbColors.brand,
                  ),
                ),
              ),
            ),
          ],
          if (v.isPartial)
            Text(
              'Came by SMS; the full record is not here yet.',
              style: HbText.bodySmall.copyWith(color: HbColors.warning),
            ),
          if (v.dangerSigns.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final s in v.dangerSigns) BulletLine(s, HbColors.red),
          ],
          if (v.temperature != null ||
              v.condition != null ||
              v.followUpOn != null) ...[
            const SizedBox(height: 8),
            if (v.temperature != null)
              DetailRow('Temperature', '${v.temperature} °C'),
            if (v.condition != null) ...[
              const SizedBox(height: 6),
              DetailRow('Condition', v.condition!),
            ],
            if (v.followUpOn != null) ...[
              const SizedBox(height: 6),
              DetailRow('Follow-up', fullDate(v.followUpOn!)),
            ],
          ],
          if (v.symptoms != null) ...[
            const SizedBox(height: 8),
            Text('Symptoms', style: HbText.bodySmall),
            Text(v.symptoms!, style: HbText.bodyMedium),
          ],
          if (v.notes != null) ...[
            const SizedBox(height: 8),
            Text('Notes', style: HbText.bodySmall),
            Text(v.notes!, style: HbText.bodyMedium),
          ],
        ],
      ),
    );
  }
}

