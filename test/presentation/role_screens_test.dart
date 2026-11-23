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
