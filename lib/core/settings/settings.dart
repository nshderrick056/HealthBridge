
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'SharedPreferences must be initialized at startup',
  ),
);

enum TextSize {
  normal(1.0, 'Normal'),
  large(1.15, 'Large'),
  extraLarge(1.3, 'Extra large');

  const TextSize(this.scale, this.label);

  final double scale;
  final String label;
}

class AppSettings {
  const AppSettings({
    this.textSize = TextSize.normal,
    this.defaultVisitType = VisitType.maternal,
    this.rememberLogin = false,
    this.savedLoginId,
  });

  final TextSize textSize;
  final VisitType defaultVisitType;
  final bool rememberLogin;
  final String? savedLoginId;
}

class SettingsController extends Notifier<AppSettings> {
  static const _textSizeKey = 'settings.textSize';
  static const _visitTypeKey = 'settings.defaultVisitType';
  static const _rememberKey = 'settings.rememberLogin';
  static const _loginIdKey = 'settings.loginId';

  SharedPreferences get _prefs =>
      ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final rememberLogin = prefs.getBool(_rememberKey) ?? false;

    return AppSettings(
      textSize: TextSize.values.asNameMap()[
              prefs.getString(_textSizeKey)] ??
          TextSize.normal,
      defaultVisitType: VisitType.values.asNameMap()[
              prefs.getString(_visitTypeKey)] ??
          VisitType.maternal,
      rememberLogin: rememberLogin,
      savedLoginId: rememberLogin
          ? prefs.getString(_loginIdKey)
          : null,
    );
  }

  AppSettings _copyWith({
    TextSize? textSize,
    VisitType? defaultVisitType,
    bool? rememberLogin,
    String? Function()? savedLoginId,
  }) {
    return AppSettings(
      textSize: textSize ?? state.textSize,
      defaultVisitType: defaultVisitType ?? state.defaultVisitType,
      rememberLogin: rememberLogin ?? state.rememberLogin,
      savedLoginId: savedLoginId != null
          ? savedLoginId()
          : state.savedLoginId,
    );
  }

  Future<void> setTextSize(TextSize size) async {
    await _prefs.setString(_textSizeKey, size.name);

    if (!ref.mounted) return;
    state = _copyWith(textSize: size);
  }

  Future<void> setDefaultVisitType(VisitType type) async {
    await _prefs.setString(_visitTypeKey, type.name);

    if (!ref.mounted) return;
    state = _copyWith(defaultVisitType: type);
  }

  Future<void> setRememberLogin(bool enabled) async {
    await _prefs.setBool(_rememberKey, enabled);

    if (!enabled) {
      await _prefs.remove(_loginIdKey);
    }

    if (!ref.mounted) return;

    state = _copyWith(
      rememberLogin: enabled,
      savedLoginId: enabled ? null : () => null,
    );
  }

  Future<void> loggedInAs(String id) async {
    if (!state.rememberLogin) return;

    final loginId = id.trim();
    if (loginId.isEmpty) return;

    await _prefs.setString(_loginIdKey, loginId);

    if (!ref.mounted) return;

    state = _copyWith(
      savedLoginId: () => loginId,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );
