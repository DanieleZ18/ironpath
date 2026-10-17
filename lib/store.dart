import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data/exercises_seed.dart';
import 'data/plans_seed.dart';
import 'models.dart';

/// Local-only persistence. Everything lives in SharedPreferences as JSON —
/// fine for MVP volume (a few hundred records). Swap for Drift/Isar only if
/// history queries ever get heavy.

class Store {
  Store._();

  static final Store instance = Store._();

  List<Plan> customPlans = [];
  List<SessionLog> logs = [];
  AppSettings settings = AppSettings();

  List<Plan> get builtin => builtinPlans;
  List<Exercise> get exercises => exercisesSeed;
  Exercise? exerciseById(String id) => exerciseMap[id];

  List<Plan> get allPlans => [...builtinPlans, ...customPlans];

  Plan? planById(String id) {
    for (final p in allPlans) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Most recent logged weight for an exercise (logs are newest-first).
  /// Used to prefill the weight field at the start of an exercise.
  double? lastWeightFor(String exerciseId) {
    for (final log in logs) {
      for (final item in log.items) {
        if (item.exerciseId != exerciseId) continue;
        for (var i = item.sets.length - 1; i >= 0; i--) {
          final w = item.sets[i].weight;
          if (w != null) return w;
        }
      }
    }
    return null;
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    customPlans = _decodeList(sp.getString('customPlans'))
        .map((j) => Plan.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    logs = _decodeList(sp.getString('logs'))
        .map((j) => SessionLog.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    logs.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final rawSettings = sp.getString('settings');
    settings = rawSettings == null
        ? AppSettings()
        : AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(rawSettings)));
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        'customPlans', jsonEncode(customPlans.map((e) => e.toJson()).toList()));
    await sp.setString('logs', jsonEncode(logs.map((e) => e.toJson()).toList()));
    await sp.setString('settings', jsonEncode(settings.toJson()));
  }

  static List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final v = jsonDecode(raw);
    if (v is! List) return [];
    return v.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
