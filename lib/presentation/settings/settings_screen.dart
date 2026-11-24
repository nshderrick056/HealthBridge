
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models.dart';
import '../patients/patients_screen.dart';
import '../view_models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: HbColors.canvas,
      appBar: AppBar(
        backgroundColor: HbColors.canvas,
        foregroundColor: HbColors.ink,
        elevation: 0,
        toolbarHeight: 52,
      ),
      body: PageBody(
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle: 'Your preferences are saved on this phone.',
          ),

          HbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Text size',
                  style: HbText.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a comfortable reading size.',
                  style: HbText.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final size in TextSize.values)
                      ChoiceChipPill(
                        label: size.label,
                        selected: current.textSize == size,
                        onTap: () =>
                            controller.setTextSize(size),
                      ),
                  ],
                ),
              ],
            ),
          ),

          HbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default visit type',
                  style: HbText.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'This visit type will be selected when '
                  'you start a new patient visit.',
                  style: HbText.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in VisitType.values)
                      ChoiceChipPill(
                        label: visitTypeLabel(type),
                        selected:
                            current.defaultVisitType == type,
                        onTap: () =>
                            controller.setDefaultVisitType(type),
                      ),
                  ],
                ),
              ],
            ),
          ),

          HbCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            child: SwitchListTile(
              title: Text(
                'Remember my login',
                style: HbText.labelMedium,
              ),
              subtitle: Text(
                'Pre-fill your phone number or login ID. '
                'Your PIN and password are never saved here.',
                style: HbText.bodySmall,
              ),
              value: current.rememberLogin,
              onChanged: controller.setRememberLogin,
              activeThumbColor: HbColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
