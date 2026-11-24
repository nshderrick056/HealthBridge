
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../sync/background_sync.dart';
import '../settings/settings_screen.dart';
import '../shell/app_shell.dart';
import '../sync/sync_status_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _signingOut = false;
  String? _error;

  Future<void> _logout() async {
    if (_signingOut) return;

    setState(() {
      _signingOut = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).logout();

      if (!mounted) return;

      ref.read(sessionProvider.notifier).state = null;
      ref.read(tabIndexProvider.notifier).state = 0;

      try {
        await cancelBackgroundSync();
      } catch (_) {
        // The account has already been signed out.
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not sign out. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _signingOut = false;
        });
      }
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final name = session?.fullName.trim() ?? '';
    final displayName = name.isEmpty ? 'HealthBridge user' : name;

    final roleLabel = switch (session?.role) {
      'supervisor' => 'Supervisor',
      'admin' => 'Administrator',
      _ => 'Community Health Worker',
    };

    return PageBody(
      children: [
        const PageHeader(
          title: 'Profile',
          subtitle: 'Your account',
        ),

        HbCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: HbColors.teal,
                child: Text(
                  initials(displayName),
                  style: HbText.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: HbText.headingSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      roleLabel,
                      style: HbText.bodySmall,
                    ),
                    if (session?.email != null &&
                        session!.email!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        session.email!,
                        style: HbText.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        HbButton.secondary(
          'Sync status',
          onPressed: () => _open(
            const SyncStatusScreen(),
          ),
        ),

        HbButton.secondary(
          'Settings',
          onPressed: () => _open(
            const SettingsScreen(),
          ),
        ),

        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: HbText.bodySmall.copyWith(
                color: HbColors.red,
              ),
            ),
          ),

        HbButton.secondary(
          _signingOut ? 'Signing out...' : 'Log out',
          onPressed: _signingOut ? null : _logout,
        ),
      ],
    );
  }
}
