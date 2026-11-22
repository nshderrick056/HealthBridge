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
  const PatientProfileScreen({super.key, required this.patientId});

  final String patientId;

  /// Asks first, then archives, leaves the profile and offers Undo.
  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
  ) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive this patient?'),
        content: Text(
          '${patient.fullName} will be hidden from your lists. '
          'Their visits are kept, and you can undo this straight away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(patientActionsProvider);
    try {
      final archived = await actions.archive(patient);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${patient.fullName} archived'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => actions.restore(archived),
          ),
        ),
      );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not archive. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(allPatientsProvider).value ?? const [];
    final visits = ref.watch(allVisitsProvider).value ?? const [];
    final showAll = ref.watch(historyExpandedProvider(patientId));
    void toggleHistory() =>
        ref.read(historyExpandedProvider(patientId).notifier).toggle();
    final found = patients.where((p) => p.id == patientId);
    if (found.isEmpty) return const Scaffold(body: SizedBox.shrink());
    final view = PatientView(
      found.first,
      visits.where((v) => v.patientId == patientId).toList(),
