import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'forgot_screen.dart';
import 'login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _id;
  final _secret = TextEditingController();

  static const _errorOnGreen = Color(0xFFFFD7D2);

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(
      text: ref.read(settingsProvider).savedLoginId ?? '',
    );
  }

  @override
  void dispose() {
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  LoginController get _controller => ref.read(loginControllerProvider.notifier);

  void _submit(LoginState login) {
    if (login.busy) return;
    if (!_form.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    switch (login.method) {
      case LoginMethod.pin:
      case LoginMethod.email:
        _controller.submit(_id.text.trim(), _secret.text);
      case LoginMethod.smsCode:
        if (login.awaitingCode) {
          _controller.confirmCode(_id.text.trim(), _secret.text.trim());
        } else {
          _controller.sendCode(_id.text.trim());
        }
    }
  }

  void _choose(LoginMethod method, LoginState login) {
    if (login.busy || login.method == method) return;

    final switchingIdentifier =
        (login.method == LoginMethod.email) != (method == LoginMethod.email);

    if (switchingIdentifier) {
      _id.clear();
    }

    _secret.clear();
    _form.currentState?.reset();

    FocusScope.of(context).unfocus();
    _controller.choose(method);
  }

  void _changeNumber() {
    _secret.clear();
    _controller.changeNumber();
  }

  void _openRecovery() {
    FocusScope.of(context).unfocus();

    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ForgotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginControllerProvider);

    return _layout(login);
  }

  String _instructions(LoginState login) {
    if (login.method == LoginMethod.email) {
      return 'Sign in with your registered email address.';
    }

    if (login.awaitingCode) {
      return 'Enter the verification code sent to your phone.';
    }

    return 'Use the phone number registered with your account.';
  }

  List<Widget> _fields(LoginState login) {
    final busy = login.busy;

    final (idField, secretField, action, busyLabel) = switch (login.method) {
      LoginMethod.pin => (
        HbTextField(
          key: const ValueKey('login-phone-pin'),
          label: 'Phone number',
          hint: 'e.g. 0788 123 456',
          controller: _id,
          keyboardType: TextInputType.phone,
          validator: validatePhone,
          labelColor: Colors.white,
        ),
        HbTextField(
          key: const ValueKey('login-pin'),
          label: 'PIN',
          hint: '4 to 6 digits',
          controller: _secret,
          obscure: true,
          keyboardType: TextInputType.number,
          validator: validatePin,
          labelColor: Colors.white,
        ),
        'Sign in',
        'Signing in...',
      ),
      LoginMethod.email => (
        HbTextField(
          key: const ValueKey('login-email'),
          label: 'Email',
          hint: 'you@example.org',
          controller: _id,
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
          labelColor: Colors.white,
        ),
        HbTextField(
          key: const ValueKey('login-password'),
          label: 'Password',
          hint: 'Enter your password',
          controller: _secret,
          obscure: true,
          validator: validatePassword,
          labelColor: Colors.white,
        ),
        'Sign in',
        'Signing in...',
      ),
      LoginMethod.smsCode => (
        HbTextField(
          key: const ValueKey('login-phone-sms'),
          label: 'Phone number',
          hint: 'e.g. 0788 123 456',
          controller: _id,
          keyboardType: TextInputType.phone,
          validator: validatePhone,
          labelColor: Colors.white,
        ),
        login.awaitingCode
            ? HbTextField(
                key: const ValueKey('login-sms-code'),
                label: 'Verification code',
                hint: '6 digits',
                controller: _secret,
                keyboardType: TextInputType.number,
                validator: validateCode,
                labelColor: Colors.white,
              )
            : null,
        login.awaitingCode ? 'Verify and sign in' : 'Send code',
        login.awaitingCode ? 'Verifying...' : 'Sending code...',
      ),
    };

    return [
      idField,
      if (secretField != null) ...[const SizedBox(height: 18), secretField],
      if (login.error != null) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            login.error!,
            style: HbText.bodyMedium.copyWith(
              color: _errorOnGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      const SizedBox(height: 24),
      HbButton.light(
        busy ? busyLabel : action,
        onPressed: busy ? null : () => _submit(login),
      ),
      const SizedBox(height: 4),
      if (login.awaitingCode)
        _Link(
          'Change number or request another code',
          onTap: busy ? null : _changeNumber,
        ),
      _Link('Forgot PIN or password?', onTap: busy ? null : _openRecovery),
    ];
  }

  Widget _layout(LoginState login) => Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: HbColors.brandDeep,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: HbGradients.deep),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              24,
              40,
              24,
              28 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HealthBridge',
                    style: HbText.headingMedium.copyWith(color: HbColors.lime),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Sign in',
                    style: HbText.display.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _instructions(login),
                    style: HbText.bodyMedium.copyWith(color: HbColors.onBrand),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final (method, label) in const [
                        (LoginMethod.pin, 'PIN'),
                        (LoginMethod.smsCode, 'SMS code'),
                        (LoginMethod.email, 'Email'),
                      ])
                        _MethodChip(
                          label,
                          selected: login.method == method,
                          enabled: !login.busy,
                          onTap: () => _choose(method, login),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ..._fields(login),
                  const SizedBox(height: 32),
                  Text(
                    'Your visits are stored on this phone and synced when you have a connection.',
                    style: HbText.bodySmall.copyWith(color: HbColors.onBrand),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MethodChip extends StatelessWidget {
  const _MethodChip(
    this.label, {
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    enabled: enabled,
    child: Material(
      color: selected ? Colors.white : Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            style: HbText.bodyMedium.copyWith(
              color: selected ? HbColors.ink : HbColors.onBrand,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Link extends StatelessWidget {
  const _Link(this.label, {required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    enabled: onTap != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: HbText.bodyMedium.copyWith(
            color: HbColors.lime,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: HbColors.lime,
          ),
        ),
      ),
    ),
  );
}
