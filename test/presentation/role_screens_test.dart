import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_bridge/core/api/api_client.dart';
import 'package:health_bridge/core/auth/auth_service.dart';
import 'package:health_bridge/core/theme/app_theme.dart';
import 'package:health_bridge/data/providers.dart';
import 'package:health_bridge/data/repositories/supervision_repository.dart';
import 'package:health_bridge/domain/entities/supervision.dart';
import 'package:health_bridge/presentation/admin/admin_screens.dart';
import 'package:health_bridge/presentation/auth/change_secret_screen.dart';
import 'package:health_bridge/presentation/supervisor/case_screen.dart';
import 'package:health_bridge/presentation/supervisor/inbox_screen.dart';

ApiClient _unused() => ApiClient(
  auth: AuthService(baseUrl: 'http://api.test'),
  session: () => null,
  onSession: (_) {},
);

class _FakeSupervision extends SupervisionRepository {
  _FakeSupervision() : super(_unused());
  final moves = <(String, AlertStatus, String?)>[];

  @override
  Future<List<AlertSummary>> alerts({String? status}) async => [
    AlertSummary.fromJson({
      'id': 'a1',
      'status': 'new',
      'channel': 'sms',
      'createdAt': '2026-11-15T08:00:00Z',
      'isPartial': true,
      'patient': {'shortId': 'P0412', 'name': null},
      'chw': {'name': 'Mukamana Alice'},
      'village': 'Gatare',
      'dangerSigns': ['Heavy bleeding'],
    }),
  ];

  @override
  Future<AlertDetail> alert(String id) async => AlertDetail.fromJson({
    'id': id,
    'status': 'escalated',
    'channel': 'internet',
    'next': ['follow_up', 'resolved'],
    'visit': {'shortCode': '7f3c9a21', 'type': 'maternal', 'answers': {}},
    'patient': {
      'shortId': 'P0412',
      'name': 'Uwase Marie',
      'village': 'Nyamata',
    },
    'chw': {'name': 'Mukamana Alice', 'phone': '+250780000501'},
    'dangerSigns': [
      {'code': 'HB', 'label': 'Heavy bleeding'},
    ],
    'events': [
      {'fromStatus': 'new', 'toStatus': 'escalated', 'actor': 'Grace'},
    ],
  });

  @override
  Future<void> setStatus(String id, AlertStatus status, {String? note}) async =>
      moves.add((id, status, note));
}

class _FakeAdmin extends AdminRepository {
  _FakeAdmin() : super(_unused());
  final approved = <String>[];

  @override
  Future<List<ResetRequest>> resetRequests() async => approved.isEmpty
      ? [
          ResetRequest.fromJson({
            'id': 'r1',
            'name': 'Mukamana Alice',
            'phone': '+250790218726',
            'role': 'chw',
          }),
        ]
      : [];

  @override
  Future<void> approve(String requestId) async => approved.add(requestId);

  final centreNames = <String>['Nyamata Health Centre'];
  String? lastCall;

  @override
  Future<List<HealthCentre>> centres() async => [
    for (final (i, n) in centreNames.indexed)
      HealthCentre.fromJson({'id': 'hc$i', 'name': n}),
  ];

  @override
  Future<String> createCentre({
    required String name,
    required String district,
    required String sector,
    String? callNumber,
  }) async {
    centreNames.add(name.trim());
    lastCall = callNumber;
    return 'hc${centreNames.length - 1}';
  }
}

void main() {
  Future<void> pump(WidgetTester tester, Widget home, List overrides) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 0.55;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overrides],
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: home),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }
