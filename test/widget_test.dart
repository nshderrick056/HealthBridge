// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_bridge/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

  testWidgets(
    'recording a visit with a danger sign saves it as urgent and opens the urgent screen',
    (tester) async {
      await db
          .into(db.patients)
          .insert(
            PatientsCompanion.insert(
              id: 'p1',
              shortId: 'P000001',
              fullName: 'Uwase Marie',
              village: 'Nyamata',
              consentAt: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await pumpShell(tester);
      await tester.tap(find.text('Record').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uwase Marie'));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Heavy bleeding'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Heavy bleeding'));
      await tester.pump();
      await tester.tap(find.text('Heavy bleeding'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Review visit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Review visit'));
      await tester.pumpAndSettle();
      expect(find.text('Check and save'), findsOneWidget);
      expect(find.text('This visit is urgent'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Save visit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save visit'));
      await settle(tester);
      await settle(
        tester,
      ); // the next screen loads the visit with a second real-time query

      expect(find.text('Send urgent alert'), findsOneWidget);
      expect(
        find.text('Uwase Marie needs the health centre today'),
        findsOneWidget,
      );
      expect(find.text('Heavy bleeding'), findsOneWidget);
      final visits = (await tester.runAsync(() => db.select(db.visits).get()))!;
      expect(visits.single.isUrgent, isTrue);
      expect(visits.single.syncState, SyncState.queued);
      expect(
        (await tester.runAsync(() => db.select(db.outbox).get()))!,
        hasLength(1),
      );
      await finish(tester);
    },
  );

  Future<void> seedUrgent(String channel, DispatchState state) async {
    final now = DateTime.now();
    await db
        .into(db.patients)
        .insert(
          PatientsCompanion.insert(
            id: 'p1',
            shortId: 'P000001',
            fullName: 'Uwase Marie',
            village: 'Nyamata',
            consentAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            id: 'v1',
            shortCode: '7f3c9a21',
            patientId: 'p1',
            type: VisitType.maternal,
            recordedAt: now,
            isUrgent: const Value(true),
          ),
        );
    await db
        .into(db.urgentDispatch)
        .insert(
          UrgentDispatchCompanion.insert(
            visitId: 'v1',
            channel: channel,
            state: state,
            sentAt: Value(now),
          ),
        );
  }

