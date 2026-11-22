import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/entities/supervision.dart';
import '../view_models.dart';
import 'supervisor_controllers.dart';

/// One case for the supervisor (Figma v3 "Case detail"): the patient, the danger signs, the visit,
/// the CHW, the next steps the server allows, and the history. Stateful only to own the note.
class CaseScreen extends ConsumerStatefulWidget {
  const CaseScreen({super.key, required this.alertId});

  final String alertId;

  @override
  ConsumerState<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends ConsumerState<CaseScreen> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _move(AlertStatus to) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref
        .read(caseStatusProvider(widget.alertId).notifier)
        .move(to, _note.text);
    if (error == null) _note.clear();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Case moved to ${to.label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(caseProvider(widget.alertId));
    final saving = ref.watch(caseStatusProvider(widget.alertId));
    return Scaffold(
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            'Could not load this case.',
            style: HbText.bodyMedium.copyWith(color: HbColors.red),
          ),
        ),
        data: (d) => _body(d, saving),
      ),
    );
  }

  static String _action(AlertStatus to) => switch (to) {
    AlertStatus.escalated => 'Escalate',
    AlertStatus.followUp => 'Ask for follow-up',
    AlertStatus.resolved => 'Resolve',
    AlertStatus.reviewed => 'Mark reviewed',
    AlertStatus.newCase => to.label,
  };

