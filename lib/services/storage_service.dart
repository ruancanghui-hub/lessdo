import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._(this._preferences);

  final SharedPreferences _preferences;

  static Future<StorageService> create() async {
    return StorageService._(await SharedPreferences.getInstance());
  }

  List<Map<String, Object?>> readList(String key) {
    final raw = _preferences.getString(key);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .map((item) => Map<String, Object?>.from(item! as Map))
        .toList();
  }

  Map<String, Object?>? readMap(String key) {
    final raw = _preferences.getString(key);
    if (raw == null) return null;
    return Map<String, Object?>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeList(String key, List<Map<String, Object?>> value) {
    return _preferences.setString(key, jsonEncode(value));
  }

  Future<void> writeMap(String key, Map<String, Object?> value) {
    return _preferences.setString(key, jsonEncode(value));
  }
}
