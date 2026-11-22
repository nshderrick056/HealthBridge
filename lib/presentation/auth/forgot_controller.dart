
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../data/providers.dart';

enum ForgotStep { who, code, newSecret, done }

class ForgotState {
  const ForgotState({
    this.step = ForgotStep.who,
    this.busy = false,
    this.error,
    this.byEmail = false,
    this.id = '',
    this.resetToken,
  });

  final ForgotStep step;
  final bool busy;
  final String? error;
  final bool byEmail;
  final String id;
  final String? resetToken;

  ForgotState copyWith({
    ForgotStep? step,
    bool? busy,
    String? Function()? error,
    bool? byEmail,
    String? id,
    String? Function()? resetToken,
  }) {
    return ForgotState(
      step: step ?? this.step,
      busy: busy ?? this.busy,
      error: error != null ? error() : this.error,
      byEmail: byEmail ?? this.byEmail,
      id: id ?? this.id,
      resetToken: resetToken != null
          ? resetToken()
          : this.resetToken,
    );
  }
}

class ForgotController extends Notifier<ForgotState> {
  @override
  ForgotState build() => const ForgotState();

  AuthService get _auth => ref.read(authServiceProvider);

  void useEmail(bool byEmail) {
    if (state.busy || state.step != ForgotStep.who) return;
    if (state.byEmail == byEmail) return;

    state = ForgotState(byEmail: byEmail);
  }

  Future<void> request(String id) async {
    if (state.busy || state.step != ForgotStep.who) return;

    final identifier = id.trim();

    if (identifier.isEmpty) {
      _setError('Enter your phone number or email.');
      return;
    }

    final byEmail = state.byEmail;

    await _run(() async {
      await _auth.requestReset(
        phone: byEmail ? null : identifier,
        email: byEmail ? identifier : null,
      );

      return state.copyWith(
        step: ForgotStep.code,
        id: identifier,
        resetToken: () => null,
      );
    });
  }

  Future<void> verify(String code) async {
    if (state.busy || state.step != ForgotStep.code) return;

    final verificationCode = code.trim();

    if (verificationCode.isEmpty) {
      _setError('Enter the verification code.');
      return;
    }

    final identifier = state.id;
    final byEmail = state.byEmail;

    await _run(() async {
      final token = await _auth.verifyResetCode(
        phone: byEmail ? null : identifier,
        email: byEmail ? identifier : null,
        code: verificationCode,
      );

      return state.copyWith(
        step: ForgotStep.newSecret,
        resetToken: () => token,
      );
    });
  }

  Future<void> complete({
    String? pin,
    String? password,
  }) async {
    if (state.busy || state.step != ForgotStep.newSecret) {
      return;
    }

    final token = state.resetToken;

    if (token == null || token.isEmpty) {
      _setError(
        'Your reset session is missing. Start again.',
      );
      return;
    }

    if (state.byEmail && password == null) {
      _setError('Enter your new password.');
      return;
    }

    if (!state.byEmail && pin == null) {
      _setError('Enter your new PIN.');
      return;
    }

    await _run(() async {
      await _auth.completeReset(
        token,
        pin: state.byEmail ? null : pin,
        password: state.byEmail ? password : null,
      );

      return state.copyWith(
        step: ForgotStep.done,
        resetToken: () => null,
      );
    });
  }

  Future<void> _run(
    Future<ForgotState> Function() action,
  ) async {
    if (state.busy) return;

    state = state.copyWith(
      busy: true,
      error: () => null,
    );

    try {
      final next = await action();

      if (!ref.mounted) return;

      state = next.copyWith(
        busy: false,
        error: () => null,
      );
    } on AuthException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError(
        'Something went wrong. Check your connection and try again.',
      );
    }
  }

  void _setError(String message) {
    if (!ref.mounted) return;

    state = state.copyWith(
      busy: false,
      error: () => message,
    );
  }
}

final forgotControllerProvider =
    NotifierProvider.autoDispose<ForgotController, ForgotState>(
      ForgotController.new,
    );
