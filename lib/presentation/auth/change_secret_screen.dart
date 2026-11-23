
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import 'change_secret_controller.dart';
import 'login_controller.dart';

class ChangeSecretScreen extends ConsumerStatefulWidget {
  const ChangeSecretScreen({super.key});

  @override
  ConsumerState<ChangeSecretScreen> createState() =>
      _ChangeSecretScreenState();
}

class _ChangeSecretScreenState
    extends ConsumerState<ChangeSecretScreen> {
  final _form = GlobalKey<FormState>();

  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirmPin.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save({
    required bool needsPin,
    required bool needsPassword,
  }) async {
    if (!(_form.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    await ref.read(changeSecretProvider.notifier).save(
          pin: needsPin ? _pin.text.trim() : null,
          password: needsPassword ? _password.text : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final state = ref.watch(changeSecretProvider);

    final needsPin = session?.role == 'chw';
    final needsPassword =
        session?.email?.trim().isNotEmpty ?? false;

    final title = needsPin && needsPassword
        ? 'Set your PIN and password'
        : needsPin
            ? 'Set your new PIN'
            : 'Set your new password';

    return Scaffold(
      backgroundColor: HbColors.canvas,
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              20, 28, 20, 32,
            ),
            children: [
              PageHeader(
                title: title,
                subtitle:
                    'You signed in using temporary credentials. '
                    'Choose your own credentials to continue.',
              ),
              const SizedBox(height: 24),

              if (needsPin) ...[
                HbTextField(
                  label: 'New PIN',
                  hint: '4 to 6 digits',
                  controller: _pin,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  validator: validatePin,
                ),
                const SizedBox(height: 12),
                HbTextField(
                  label: 'Confirm new PIN',
                  hint: 'Enter the same PIN',
                  controller: _confirmPin,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Confirm your PIN.';
                    }
                    if (value.trim() != _pin.text.trim()) {
                      return 'The PINs do not match.';
                    }
                    return null;
                  },
                ),
              ],

              if (needsPin && needsPassword)
                const SizedBox(height: 24),

              if (needsPassword) ...[
                HbTextField(
                  label: 'New password',
                  hint: 'At least 8 characters',
                  controller: _password,
                  obscure: true,
                  validator: validatePassword,
                ),
                const SizedBox(height: 12),
                HbTextField(
                  label: 'Confirm new password',
                  hint: 'Enter the same password',
                  controller: _confirmPassword,
                  obscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password.';
                    }
                    if (value != _password.text) {
                      return 'The passwords do not match.';
                    }
                    return null;
                  },
                ),
              ],

              if (!needsPin && !needsPassword)
                Text(
                  'No credentials are available to change. '
                  'Contact your administrator.',
                  style: HbText.bodyMedium,
                ),

              if (state.error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.error!,
                    style: HbText.bodySmall.copyWith(
                      color: HbColors.red,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              if (needsPin || needsPassword)
                HbButton.primary(
                  state.busy
                      ? 'Saving changes...'
                      : 'Save and continue',
                  onPressed: state.busy
                      ? null
                      : () => _save(
                            needsPin: needsPin,
                            needsPassword: needsPassword,
                          ),
                ),

              const SizedBox(height: 12),

              HbButton.secondary(
                'Log out',
                onPressed: state.busy
                    ? null
                    : () => ref
                        .read(changeSecretProvider.notifier)
                        .logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
