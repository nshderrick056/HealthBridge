
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../data/providers.dart';

class ChangeSecretState {
  const ChangeSecretState({
    this.busy = false,
    this.error,
  });

  final bool busy;
  final String? error;

  ChangeSecretState copyWith({
    bool? busy,
    String? Function()? error,
  }) {
    return ChangeSecretState(
      busy: busy ?? this.busy,
      error: error != null ? error() : this.error,
    );
  }
}

class ChangeSecretController extends Notifier<ChangeSecretState> {
  @override
  ChangeSecretState build() => const ChangeSecretState();

  Future<void> save({
    String? pin,
    String? password,
  }) async {
    if (state.busy) return;

    if (pin == null && password == null) {
      state = const ChangeSecretState(
        error: 'Enter a new PIN or password.',
      );
      return;
    }

    state = const ChangeSecretState(busy: true);

    try {
      final session = await ref.read(authServiceProvider).changeOwn(
            pin: pin,
            password: password,
          );

      if (!ref.mounted) return;

      ref.read(sessionProvider.notifier).state = session;

      state = const ChangeSecretState();
    } on AuthException catch (error) {
      if (!ref.mounted) return;

      state = ChangeSecretState(error: error.message);
    } catch (_) {
      if (!ref.mounted) return;

      state = const ChangeSecretState(
        error: 'Unable to save your changes. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    if (state.busy) return;

    state = const ChangeSecretState(busy: true);

    try {
      await ref.read(authServiceProvider).logout();

      if (!ref.mounted) return;

      ref.read(sessionProvider.notifier).state = null;

      state = const ChangeSecretState();
    } on AuthException catch (error) {
      if (!ref.mounted) return;

      state = ChangeSecretState(error: error.message);
    } catch (_) {
      if (!ref.mounted) return;

      state = const ChangeSecretState(
        error: 'Could not sign out. Please try again.',
      );
    }
  }
}

final changeSecretProvider =
    NotifierProvider.autoDispose<ChangeSecretController, ChangeSecretState>(
      ChangeSecretController.new,
    );
