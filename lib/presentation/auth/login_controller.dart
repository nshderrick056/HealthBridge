
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/settings/settings.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_owner.dart';

enum LoginMethod { pin, smsCode, email }

class LoginState {
  const LoginState({
    this.method = LoginMethod.pin,
    this.busy = false,
    this.error,
    this.verificationId,
  });

  final LoginMethod method;
  final bool busy;
  final String? error;
  final String? verificationId;

  bool get awaitingCode => verificationId != null;

  LoginState copyWith({
    bool? busy,
    String? Function()? error,
    String? Function()? verificationId,
  }) {
    return LoginState(
      method: method,
      busy: busy ?? this.busy,
      error: error != null ? error() : this.error,
      verificationId: verificationId != null
          ? verificationId()
          : this.verificationId,
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  AuthService get _auth => ref.read(authServiceProvider);

  void choose(LoginMethod method) {
    if (state.busy || state.method == method) return;
    state = LoginState(method: method);
  }

  Future<void> submit(String id, String secret) async {
    if (state.busy) return;

    final method = state.method;

    await _run(
      id,
      () => method == LoginMethod.email
          ? _auth.signInWithEmail(id.trim(), secret)
          : _auth.signInWithPin(normalizePhone(id), secret),
    );
  }

  Future<void> sendCode(String phone) async {
    if (state.busy) return;

    state = state.copyWith(
      busy: true,
      error: () => null,
    );

    try {
      final sent = await _auth.sendPhoneCode(normalizePhone(phone));

      if (!ref.mounted) return;

      if (sent.signedIn) {
        final session = await _auth.restore();

        if (!ref.mounted) return;

        if (session == null) {
          throw AuthException(
            'Could not complete sign in. Please try again.',
          );
        }

        await _done(phone, session);
      } else {
        final verificationId = sent.verificationId;

        if (verificationId == null || verificationId.isEmpty) {
          throw AuthException(
            'Verification could not be started. Please try again.',
          );
        }

        state = state.copyWith(
          busy: false,
          verificationId: () => verificationId,
        );
      }
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError(
        'Unable to send the verification code. Please try again.',
      );
    }
  }

  Future<void> confirmCode(String phone, String code) async {
    if (state.busy) return;

    final verificationId = state.verificationId;

    if (verificationId == null || verificationId.isEmpty) {
      _setError('Request a verification code first.');
      return;
    }

    await _run(
      phone,
      () => _auth.confirmPhoneCode(
        verificationId,
        code.trim(),
      ),
    );
  }

  void changeNumber() {
    if (state.busy) return;

    state = const LoginState(
      method: LoginMethod.smsCode,
    );
  }

  Future<void> _run(
    String id,
    Future<Session> Function() signIn,
  ) async {
    if (state.busy) return;

    state = state.copyWith(
      busy: true,
      error: () => null,
    );

    try {
      final session = await signIn();

      if (!ref.mounted) return;

      await _done(id, session);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError(
        'Sign in failed. Check your connection and try again.',
      );
    }
  }

  Future<void> _done(String id, Session? session) async {
    if (session == null) {
      throw AuthException(
        'Could not complete sign in. Please try again.',
      );
    }

    if (!ref.mounted) return;

    if (session.role == 'chw') {
      try {
        await LocalOwner(
          ref.read(databaseProvider),
        ).claim(session.userId);
      } on LocalDataInUse catch (e) {
        await _auth.logout();
        throw AuthException(e.toString());
      }
    }

    if (!ref.mounted) return;

    await ref.read(settingsProvider.notifier).loggedInAs(id);

    if (!ref.mounted) return;

    ref.read(sessionProvider.notifier).state = session;

    state = state.copyWith(
      busy: false,
      error: () => null,
    );
  }

  void _setError(String message) {
    if (!ref.mounted) return;

    state = state.copyWith(
      busy: false,
      error: () => message,
    );
  }
}

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );

String? requiredField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String? validatePin(String? value) {
  final error = requiredField(value);
  if (error != null) return error;

  return RegExp(r'^\d{4,6}$').hasMatch(value!.trim())
      ? null
      : 'PIN is 4 to 6 digits';
}

String? validatePhone(String? value) {
  final error = requiredField(value);
  if (error != null) return error;

  final phone = value!.replaceAll(RegExp(r'[\s\-()]'), '');

  return RegExp(r'^\+?\d{9,15}$').hasMatch(phone)
      ? null
      : 'Enter a phone number, e.g. 0788 123 456';
}

String? validateEmail(String? value) {
  final error = requiredField(value);
  if (error != null) return error;

  return RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(value!.trim())
      ? null
      : 'Enter a valid email address';
}

String? validatePassword(String? value) {
  final error = requiredField(value);
  if (error != null) return error;

  return value!.length >= 8
      ? null
      : 'Password is at least 8 characters';
}

String? validateCode(String? value) {
  final error = requiredField(value);
  if (error != null) return error;

  return RegExp(r'^\d{6}$').hasMatch(value!.trim())
      ? null
      : 'The code has 6 digits';
}
