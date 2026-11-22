
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/bottom_nav.dart';
import '../admin/admin_screens.dart';
import '../profile/profile_screen.dart';
import '../supervisor/chws_screen.dart';
import '../supervisor/history_screens.dart';
import '../supervisor/inbox_screen.dart';

class _TabController extends Notifier<int> {
  @override
  int build() => 0;

  void go(int index) {
    if (index < 0 || index > 3) return;
    if (state == index) return;

    state = index;
  }
}

final _supervisorTab =
    NotifierProvider<_TabController, int>(
      _TabController.new,
    );

final _adminTab =
    NotifierProvider<_TabController, int>(
      _TabController.new,
    );

class _RoleShell extends ConsumerWidget {
  const _RoleShell({
    required this.tab,
    required this.pages,
    required this.items,
  });

  final NotifierProvider<_TabController, int> tab;
  final List<Widget> pages;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tab);

    final index = selected >= 0 && selected < pages.length
        ? selected
        : 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: index,
          children: pages,
        ),
      ),
      bottomNavigationBar: HbPillNav(
        items: items,
        current: index,
        onTap: ref.read(tab.notifier).go,
      ),
    );
  }
}

class SupervisorShell extends StatelessWidget {
  const SupervisorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return _RoleShell(
      tab: _supervisorTab,
      pages: const [
        InboxScreen(),
        ChwsScreen(),
        SupervisorPatientsScreen(),
        ProfileScreen(),
      ],
      items: const [
        (Icons.warning_amber_rounded, 'Alerts'),
        (Icons.groups_outlined, 'CHWs'),
        (Icons.folder_shared_outlined, 'Patients'),
        (Icons.person_outline, 'Profile'),
      ],
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return _RoleShell(
      tab: _adminTab,
      pages: const [
        ResetRequestsScreen(),
        NewAccountScreen(),
        CentresScreen(),
        ProfileScreen(),
      ],
      items: const [
        (Icons.lock_reset, 'Resets'),
        (Icons.person_add_alt_outlined, 'New account'),
        (Icons.local_hospital_outlined, 'Centres'),
        (Icons.person_outline, 'Profile'),
      ],
    );
  }
}
