import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  String _language = 'English';
  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign-in is not connected yet.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 184,
                        color: AppColors.mint,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        alignment: Alignment.topLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.medical_services_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HealthBridge',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    'RWANDA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                        child: AutofillGroup(
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 32,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Log in to continue your community health work.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                AppTextField(
                                  label: 'CHW ID or phone number',
                                  hint: 'Enter your ID or phone',
                                  icon: Icons.badge_outlined,
                                  controller: _identity,
                                  autofillHints: const [AutofillHints.username],
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline,
                                  controller: _password,
                                  isPassword: true,
                                  obscureText: _hidden,
                                  autofillHints: const [AutofillHints.password],
                                  onSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    tooltip: _hidden
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () =>
                                        setState(() => _hidden = !_hidden),
                                    icon: Icon(
                                      _hidden
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                AppButton(label: 'Log in', onPressed: _submit),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Language',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _language,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: AppColors.muted,
                                  ),
                                  items:
                                      const [
                                            'English',
                                            'Kinyarwanda',
                                            'Français',
                                          ]
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) =>
                                      setState(() => _language = value!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
