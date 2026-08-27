import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/appearance.dart';

class AppearanceController extends StateNotifier<AppearanceMode> {
  AppearanceController() : super(AppearanceMode.colorful) {
    _load();
  }

  static const key = 'family_brain.appearance';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(key);
    if (stored == AppearanceMode.professional.name) {
      state = AppearanceMode.professional;
    } else if (stored == AppearanceMode.colorful.name) {
      state = AppearanceMode.colorful;
    }
  }

  Future<void> setMode(AppearanceMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, mode.name);
  }
}

final appearanceControllerProvider =
    StateNotifierProvider<AppearanceController, AppearanceMode>((ref) {
  return AppearanceController();
});
