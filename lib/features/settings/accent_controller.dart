import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_accent.dart';

class AccentController extends StateNotifier<AppAccent> {
  AccentController() : super(AppAccent.purple) {
    _load();
  }

  static const key = 'family_brain.accent';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(key);
    if (stored == null) return;
    state = AppAccentColors.fromName(stored);
  }

  Future<void> setAccent(AppAccent accent) async {
    state = accent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, accent.name);
  }
}

final accentControllerProvider =
    StateNotifierProvider<AccentController, AppAccent>((ref) {
  return AccentController();
});
