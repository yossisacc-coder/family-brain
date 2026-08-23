import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/providers.dart';

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._ref) : super(const Locale('en')) {
    _load();
  }

  final Ref _ref;
  static const _key = 'family_brain.locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      await _ref.read(userRepositoryProvider).saveUser(
            user.copyWith(language: locale.languageCode),
          );
    }
  }
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController(ref);
});
