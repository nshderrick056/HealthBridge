import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../view_models.dart';
import 'patient_profile_screen.dart';
import 'patients_controller.dart';
import 'register_patient_screen.dart';

class PatientsScreen extends ConsumerWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(allPatientsProvider).value ?? const [];
    final views = ref.watch(visiblePatientsProvider);
    final query = ref.watch(patientsQueryProvider);
    final controller = ref.read(patientsQueryProvider.notifier);
    // One card per village, villages in alphabetical order.
    final byVillage = <String, List<PatientView>>{};
    for (final v in views) {
      (byVillage[v.patient.village] ??= []).add(v);
    }
    final villages = byVillage.keys.toList()..sort();

    return PageBody(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Patients', style: HbText.headingLarge),
            const SizedBox(width: 10),
            Text(
              '${patients.length}',
              style: HbText.headingMedium.copyWith(
                color: HbColors.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        TextField(
          onChanged: controller.search,
          style: HbText.bodyMedium.copyWith(fontSize: 17),
          decoration: const InputDecoration(
            hintText: 'Search by name or village',
            prefixIcon: Icon(Icons.search, size: 20, color: HbColors.muted),
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (f, label) in const [
              (PatientFilter.all, 'All'),
              (PatientFilter.followUp, 'Follow-up due'),
              (PatientFilter.urgent, 'Urgent'),
            ])
              ChoiceChipPill(
                label: label,
                selected: query.filter == f,
                onTap: () => controller.filterBy(f),
              ),
          ],
        ),
        if (views.isEmpty)
