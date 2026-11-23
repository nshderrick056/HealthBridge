import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_bridge/main.dart';

void main() {
  testWidgets('Login requires credentials and reports unconnected sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(const HealthBridgeApp());
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Enter your CHW ID or phone number'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'HB-02418');
    await tester.enterText(find.byType(TextFormField).last, 'test-password');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Sign-in is not connected yet.'), findsOneWidget);
  });
  testWidgets('Login fits reference and small viewports', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [const Size(390, 844), const Size(320, 568)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const HealthBridgeApp());
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'an unconfirmed SMS alert offers Resend and Call, and the store build can confirm it by hand',
    (tester) async {
      await seedUrgent('sms_composer', DispatchState.unconfirmed);
      phoneScreen(tester);
      await tester.pumpWidget(
        _app(db, const SmsAlertSentScreen(visitId: 'v1')),
      );
      await settle(tester);

      expect(find.text('SMS alert sent'), findsOneWidget);
      expect(find.text('No confirmation yet'), findsOneWidget);
      expect(find.text('Resend SMS'), findsOneWidget);
      expect(find.text('Call health centre'), findsOneWidget);

      await tester.ensureVisible(find.text('I got the confirmation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I got the confirmation'));
      await settle(tester);

      expect(find.text('Alert received by the health centre'), findsOneWidget);
      expect(find.text('Resend SMS'), findsNothing);
      expect(find.text('I got the confirmation'), findsNothing);
      final d = (await tester.runAsync(
        () => db.select(db.urgentDispatch).getSingle(),
      ))!;
      expect(d.state, DispatchState.confirmed);
      await finish(tester);
    },
  );

  Future<void> seedPatient() => db
      .into(db.patients)
      .insert(
        PatientsCompanion.insert(
          id: 'p1',
          shortId: 'P000001',
          fullName: 'Uwase Marie',
          village: 'Nyamata',
          sex: const Value('F'),
          ageEstimate: const Value(32),
          consentAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> openProfile(WidgetTester tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uwase Marie'));
    await tester.pumpAndSettle();
  }

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

  testWidgets('archiving asks first, hides the patient and can be undone', (
    tester,
  ) async {
    await seedPatient();
    await openProfile(tester);

    await tester.tap(find.byTooltip('Archive patient'));
    await tester.pumpAndSettle();
    expect(find.text('Archive this patient?'), findsOneWidget);
    await tester.tap(find.text('Archive'));
    await settle(tester);

    expect(find.text('Uwase Marie archived'), findsOneWidget);
    expect(
      find.text('No patients yet. Register your first patient.'),
      findsOneWidget,
    );
    var p = (await tester.runAsync(() => db.select(db.patients).getSingle()))!;
    expect(p.archivedAt, isNotNull); // kept, not deleted

    await tester.tap(find.text('Undo'));
    await settle(tester);
    p = (await tester.runAsync(() => db.select(db.patients).getSingle()))!;
    expect(p.archivedAt, isNull);
    expect(find.text('Uwase Marie'), findsOneWidget);
    await finish(tester);
  });

  testWidgets(
    'editing a patient saves, queues an upload and shows the change',
    (tester) async {
      await seedPatient();
      await openProfile(tester);

      await tester.tap(find.byTooltip('Edit patient'));
      await tester.pumpAndSettle();
      expect(find.text('Edit patient'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Uwase Marie'),
        'Uwase Marie-Claire',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '32'), 'abc');
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      expect(
        find.text('Enter the age in whole years (0 to 130)'),
        findsOneWidget,
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'abc'), '33');
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      expect(find.text('Uwase Marie-Claire'), findsOneWidget);
      final p = (await tester.runAsync(
        () => db.select(db.patients).getSingle(),
      ))!;
      expect(p.fullName, 'Uwase Marie-Claire');
      expect(p.ageEstimate, 33);
      expect(p.syncState, SyncState.queued);
      expect(
        (await tester.runAsync(() => db.select(db.outbox).get()))!,
        hasLength(1),
      );
      await finish(tester);
    },
  );

