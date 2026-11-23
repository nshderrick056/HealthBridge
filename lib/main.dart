import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() => runApp(const HealthBridgeApp());

class HealthBridgeApp extends StatelessWidget {
  const HealthBridgeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HealthBridge',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const LoginScreen(),
  );
}
