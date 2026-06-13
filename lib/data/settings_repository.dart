import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  static const _settingsKey = 'lessdo_settings_v1';

  final SharedPreferences _preferences;

  Future<AppSettings> load() async {
    final raw = _preferences.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> save(AppSettings settings) async {
    final saved = await _preferences.setString(
      _settingsKey,
      jsonEncode(settings.toJson()),
    );
    if (!saved) {
      throw StateError('Unable to save settings.');
    }
  }
}
