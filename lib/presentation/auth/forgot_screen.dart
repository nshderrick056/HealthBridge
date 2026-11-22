
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'forgot_controller.dart';
import 'login_controller.dart';

class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});

  @override
  ConsumerState<ForgotScreen> createState() =>
      _ForgotScreenState();
}

class _ForgotScreenState extends ConsumerState<ForgotScreen> {
  final _form = GlobalKey<FormState>();

  final _id = TextEditingController();
  final _code = TextEditingController();
  final _pin = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _code.dispose();
    _pin.dispose();
    _password.dispose();
    super.dispose();
  }

  ForgotController get _controller =>
      ref.read(forgotControllerProvider.notifier);

  void _next(ForgotState state) {
    if (state.busy) return;

    if (state.step == ForgotStep.done) {
      Navigator.of(context).pop();
      return;
    }

    if (!_form.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    switch (state.step) {
      case ForgotStep.who:
        _controller.request(_id.text.trim());

      case ForgotStep.code:
        _controller.verify(_code.text.trim());

      case ForgotStep.newSecret:
        _controller.complete(
          pin: state.byEmail ? null : _pin.text.trim(),
          password: state.byEmail ? _password.text : null,
        );

      case ForgotStep.done:
        break;
    }
  }

  void _changeMethod(bool byEmail) {
    final state = ref.read(forgotControllerProvider);

    if (state.busy || state.byEmail == byEmail) return;

    _id.clear();
    _code.clear();
    _pin.clear();
    _password.clear();

    _form.currentState?.reset();

    FocusScope.of(context).unfocus();
    _controller.useEmail(byEmail);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotControllerProvider);

    final (title, intro, action) = switch (state.step) {
      ForgotStep.who => (
          'Forgot PIN or password?',
          'Enter your registered phone number or email. '
              'Your administrator will review the reset request.',
          'Send request',
        ),

      ForgotStep.code => (
          'Enter verification code',
          'Once your administrator approves the request, '
              'you will receive a 6-digit code by SMS. '
              'The code is valid for 30 minutes.',
          'Verify code',
        ),

      ForgotStep.newSecret => (
          state.byEmail ? 'Create new password' : 'Create new PIN',
          state.byEmail
              ? 'Choose a new password with at least 8 characters.'
              : 'Choose a new PIN containing 4 to 6 digits.',
          'Save changes',
        ),

      ForgotStep.done => (
          'All set',
          state.byEmail
              ? 'Your password has been updated. '
                  'You can now sign in with your new password.'
              : 'Your PIN has been updated. '
                  'You can now sign in with your new PIN.',
          'Back to sign in',
        ),
    };

    return Scaffold(
      backgroundColor: HbColors.canvas,
      appBar: AppBar(
        backgroundColor: HbColors.canvas,
        foregroundColor: HbColors.ink,
        elevation: 0,
        toolbarHeight: 52,
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              32,
            ),
            children: [
              PageHeader(
                title: title,
                subtitle: intro,
              ),

              const SizedBox(height: 24),

              if (state.step == ForgotStep.who) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HbChoice(
                      'Phone',
                      selected: !state.byEmail,
                      onTap: () => _changeMethod(false),
                    ),
                    HbChoice(
                      'Email',
                      selected: state.byEmail,
                      onTap: () => _changeMethod(true),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                HbTextField(
                  key: ValueKey(
                    state.byEmail
                        ? 'recovery-email'
                        : 'recovery-phone',
                  ),
                  label: state.byEmail
                      ? 'Email address'
                      : 'Phone number',
                  hint: state.byEmail
                      ? 'you@example.org'
                      : 'e.g. 0788 123 456',
                  controller: _id,
                  keyboardType: state.byEmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  validator: state.byEmail
                      ? validateEmail
                      : validatePhone,
                ),
              ],

              if (state.step == ForgotStep.code) ...[
                HbTextField(
                  label: 'Verification code',
                  hint: 'Enter your 6-digit code',
                  controller: _code,
                  keyboardType: TextInputType.number,
                  validator: validateCode,
                ),
              ],

              if (state.step == ForgotStep.newSecret) ...[
                if (state.byEmail)
                  HbTextField(
                    label: 'New password',
                    hint: 'At least 8 characters',
                    controller: _password,
                    obscure: true,
                    validator: validatePassword,
                  )
                else
                  HbTextField(
                    label: 'New PIN',
                    hint: '4 to 6 digits',
                    controller: _pin,
                    obscure: true,
                    keyboardType: TextInputType.number,
                    validator: validatePin,
                  ),
              ],

              if (state.error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.error!,
                    style: HbText.bodyMedium.copyWith(
                      color: HbColors.red,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              HbButton.primary(
                state.busy ? 'Please wait...' : action,
                onPressed: state.busy
                    ? null
                    : () => _next(state),
              ),

              if (state.step == ForgotStep.code) ...[
                const SizedBox(height: 16),
                Text(
                  'Haven’t received a code? Your request '
                  'may still be awaiting administrator approval.',
                  textAlign: TextAlign.center,
                  style: HbText.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
