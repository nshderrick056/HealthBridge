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
}
