
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/widgets/bottom_nav.dart';
import '../alerts/alerts_screen.dart';
import '../home/home_screen.dart';
import '../patients/patients_screen.dart';
import '../profile/profile_screen.dart';
import '../record/record_visit_screen.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

void _openRecordVisit(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const RecordVisitScreen(),
    ),
  );
}

class SubPageNav extends ConsumerWidget {
  const SubPageNav({
    super.key,
    this.current,
  });

  final int? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HbBottomNav(
      current: current,
      onTap: (index) {
        if (index == 2) {
          if (current != 2) {
            _openRecordVisit(context);
          }
          return;
        }

        if (index < 0 || index > 4) return;

        ref.read(tabIndexProvider.notifier).state = index;

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
      },
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _tabs = <Widget>[
    HomeScreen(),
    PatientsScreen(),
    SizedBox.shrink(),
    AlertsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(tabIndexProvider);

    final activeIndex =
        selectedIndex >= 0 &&
                selectedIndex < _tabs.length &&
                selectedIndex != 2
            ? selectedIndex
            : 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: activeIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: HbBottomNav(
        current: activeIndex,
        onTap: (index) {
          if (index == 2) {
            _openRecordVisit(context);
            return;
          }

          if (index < 0 || index >= _tabs.length) {
            return;
          }

          ref.read(tabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
