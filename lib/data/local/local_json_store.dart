import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// On-device JSON document store used by the development/demo backend.
///
/// Phone/OTP + Firebase repositories are unchanged. This store is only wired
/// when [AppConfig.useLocalDemo] is true.
class LocalJsonStore {
  LocalJsonStore({
    SharedPreferences? preferences,
    this.persist = true,
  }) : _preferences = preferences;

  static const storageKey = 'family_brain_local_store_v1';

  final bool persist;
  SharedPreferences? _preferences;
  final _changes = StreamController<void>.broadcast();

  String? sessionUid;
  final Map<String, Map<String, dynamic>> users = {};
  final Map<String, Map<String, dynamic>> families = {};
  final Map<String, Map<String, dynamic>> tasks = {};
  final Map<String, Map<String, dynamic>> notifications = {};

  Stream<void> get changes => _changes.stream;

  Future<void> load() async {
    if (!persist) return;
    final prefs = await _prefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return;
    final data = jsonDecode(raw);
    if (data is! Map) return;
    sessionUid = data['sessionUid'] as String?;
    users
      ..clear()
      ..addAll(_asDocMap(data['users']));
    families
      ..clear()
      ..addAll(_asDocMap(data['families']));
    tasks
      ..clear()
      ..addAll(_asDocMap(data['tasks']));
    notifications
      ..clear()
      ..addAll(_asDocMap(data['notifications']));
  }

  Future<void> _write = Future.value();

  Future<void> commit() async {
    _changes.add(null);
    if (!persist) return;
    _write = _write.then((_) async {
      final prefs = await _prefs();
      await prefs.setString(storageKey, jsonEncode(toMap()));
    });
    await _write;
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionUid': sessionUid,
      'users': users,
      'families': families,
      'tasks': tasks,
      'notifications': notifications,
    };
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Map<String, Map<String, dynamic>> _asDocMap(dynamic value) {
    final raw = value as Map? ?? const {};
    return raw.map((key, doc) {
      return MapEntry(
        key.toString(),
        Map<String, dynamic>.from(doc as Map),
      );
    });
  }
}
