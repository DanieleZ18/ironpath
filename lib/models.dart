// Plain-Dart models with manual JSON serialization. Zero codegen on purpose:
// data volume is tiny for MVP; migrate to Drift only if queries get complex.

class Exercise {
  final String id;
  final String nameEn;
  final String nameZh;
  final String category; // 'bodyweight' | 'dumbbell' | 'barbell' | 'machine' | 'cable'
  final List<String> muscles; // english keys, see L10n.muscle
  final int difficulty; // 1 beginner .. 3 advanced
  final String descEn;
  final String descZh;
  final List<String> cuesEn;
  final List<String> cuesZh;
  final List<String> mistakesEn;
  final List<String> mistakesZh;
  final String progEn; // how to make it harder
  final String progZh;
  final String regEn; // how to make it easier
  final String regZh;
  final List<String>
      contraindications; // 'knee' | 'shoulder' | 'lower_back' — empty = safe
  final int defSets;
  final String defReps; // "8-12" or "30-45s"
  final int defRest; // seconds

  const Exercise({
    required this.id,
    required this.nameEn,
    required this.nameZh,
    required this.category,
    required this.muscles,
    required this.difficulty,
    required this.descEn,
    required this.descZh,
    required this.cuesEn,
    required this.cuesZh,
    required this.mistakesEn,
    required this.mistakesZh,
    required this.progEn,
    required this.progZh,
    required this.regEn,
    required this.regZh,
    this.contraindications = const [],
    required this.defSets,
    required this.defReps,
    required this.defRest,
  });

  String name(bool zh) => zh ? nameZh : nameEn;
  String desc(bool zh) => zh ? descZh : descEn;
  List<String> cues(bool zh) => zh ? cuesZh : cuesEn;
  List<String> mistakes(bool zh) => zh ? mistakesZh : mistakesEn;
  String prog(bool zh) => zh ? progZh : progEn;
  String reg(bool zh) => zh ? regZh : regEn;

  /// Equipment requirement derived from category: 'bodyweight' needs none,
  /// 'dumbbell' needs dumbbells, barbell/machine/cable need a gym.
  String requiredEquipment() => switch (category) {
        'bodyweight' => 'none',
        'dumbbell' => 'dumbbell',
        _ => 'gym',
      };

  /// Whether the user's available equipment covers this exercise.
  /// userEquipment: null (skipped onboarding) | 'none' | 'dumbbell' | 'gym'.
  bool availableFor(String? userEquipment) {
    final req = requiredEquipment();
    if (req == 'none' || userEquipment == null) return true;
    if (userEquipment == 'gym') return true;
    return userEquipment == req;
  }

  /// Whether any of the user's flagged body issues contraindicate this
  /// exercise. issues: subset of {'knee','shoulder','lower_back'}.
  bool contraindicatedFor(List<String> issues) => issues
      .any((issue) => contraindications.contains(issue));
}

class PlanItem {
  final String exerciseId;
  final int sets;
  final String reps;
  final int restSeconds;

  const PlanItem({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  PlanItem copyWith(
          {String? exerciseId, int? sets, String? reps, int? restSeconds}) =>
      PlanItem(
        exerciseId: exerciseId ?? this.exerciseId,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        restSeconds: restSeconds ?? this.restSeconds,
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
      };

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        exerciseId: j['exerciseId'] as String,
        sets: (j['sets'] as num).toInt(),
        reps: j['reps'] as String,
        restSeconds: (j['restSeconds'] as num).toInt(),
      );
}

class Plan {
  final String id;
  final String titleEn;
  final String titleZh;
  final String descEn;
  final String descZh;
  final int tier; // 1 beginner, 2 intermediate, 3 advanced
  final bool builtin;
  final int daysMin; // intended weekly training days (inclusive)
  final int daysMax;
  final List<int>
      idealDays; // weekly day-counts this split is DESIGNED for (e.g. PPL [3,6]);
  // empty = any day-count within [daysMin, daysMax]
  final List<PlanItem> items;

  const Plan({
    required this.id,
    required this.titleEn,
    required this.titleZh,
    required this.descEn,
    required this.descZh,
    required this.tier,
    required this.builtin,
    required this.daysMin,
    required this.daysMax,
    this.idealDays = const [],
    required this.items,
  });

  String title(bool zh) => zh ? titleZh : titleEn;
  String desc(bool zh) => zh ? descZh : descEn;

  /// Rough estimate: each set ~ 40s of work + rest between sets.
  int estimatedMinutes() {
    var seconds = 0;
    for (final it in items) {
      seconds += it.sets * (40 + it.restSeconds);
    }
    return (seconds / 60).round();
  }

  Plan copyAsCustom(String newId, {String? titleEn, String? titleZh}) => Plan(
        id: newId,
        titleEn: titleEn ?? '${this.titleEn} (copy)',
        titleZh: titleZh ?? '${this.titleZh}（副本）',
        descEn: descEn,
        descZh: descZh,
        tier: tier,
        builtin: false,
        daysMin: daysMin,
        daysMax: daysMax,
        idealDays: idealDays,
        items: List.of(items),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleEn': titleEn,
        'titleZh': titleZh,
        'descEn': descEn,
        'descZh': descZh,
        'tier': tier,
        'builtin': builtin,
        'daysMin': daysMin,
        'daysMax': daysMax,
        'idealDays': idealDays,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'] as String,
        titleEn: j['titleEn'] as String,
        titleZh: j['titleZh'] as String,
        descEn: (j['descEn'] ?? '') as String,
        descZh: (j['descZh'] ?? '') as String,
        tier: (j['tier'] as num).toInt(),
        builtin: (j['builtin'] ?? false) as bool,
        // old serialized plans predate the fields; assume a flexible range
        daysMin: j['daysMin'] == null ? 2 : (j['daysMin'] as num).toInt(),
        daysMax: j['daysMax'] == null ? 5 : (j['daysMax'] as num).toInt(),
        idealDays: ((j['idealDays'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        items: ((j['items'] ?? []) as List)
            .map((e) => PlanItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class SetLog {
  final int index; // 0-based within the item
  final bool done;
  final double? weight; // kg, optional

  const SetLog({required this.index, required this.done, this.weight});

  Map<String, dynamic> toJson() => {'index': index, 'done': done, 'weight': weight};

  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(
        index: (j['index'] as num).toInt(),
        done: (j['done'] ?? true) as bool,
        weight: j['weight'] == null ? null : (j['weight'] as num).toDouble(),
      );
}

class ItemLog {
  final String exerciseId;
  final List<SetLog> sets;

  const ItemLog({required this.exerciseId, required this.sets});

  int get doneCount => sets.where((s) => s.done).length;

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets.map((e) => e.toJson()).toList(),
      };

  factory ItemLog.fromJson(Map<String, dynamic> j) => ItemLog(
        exerciseId: j['exerciseId'] as String,
        sets: ((j['sets'] ?? []) as List)
            .map((e) => SetLog.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class SessionLog {
  final String id;
  final String planId;
  final String planTitleEn; // snapshot: builtin seeds may change across versions
  final String planTitleZh;
  final DateTime startedAt;
  final int durationSeconds;
  final List<ItemLog> items;

  const SessionLog({
    required this.id,
    required this.planId,
    required this.planTitleEn,
    required this.planTitleZh,
    required this.startedAt,
    required this.durationSeconds,
    required this.items,
  });

  String planTitle(bool zh) => zh ? planTitleZh : planTitleEn;

  int totalSets() => items.fold(0, (a, i) => a + i.sets.length);
  int doneSets() => items.fold(0, (a, i) => a + i.doneCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'planTitleEn': planTitleEn,
        'planTitleZh': planTitleZh,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'durationSeconds': durationSeconds,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory SessionLog.fromJson(Map<String, dynamic> j) => SessionLog(
        id: j['id'] as String,
        planId: (j['planId'] ?? '') as String,
        planTitleEn: (j['planTitleEn'] ?? '') as String,
        planTitleZh: (j['planTitleZh'] ?? '') as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch((j['startedAt'] as num).toInt()),
        durationSeconds: (j['durationSeconds'] as num).toInt(),
        items: ((j['items'] ?? []) as List)
            .map((e) => ItemLog.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class AppSettings {
  String lang; // 'system' | 'en' | 'zh'
  String appearance; // 'system' | 'dark' | 'light'
  bool remindersOn;
  int reminderHour; // 0-23
  int reminderMinute;
  bool feedbackOn; // rest-end alert sound + countdown beeps + haptics
  bool onboardingDone; // first-launch questionnaire shown/skipped
  int? userTier; // 1/2/3 from onboarding, null if skipped
  String? userEquipment; // 'none' | 'dumbbell' | 'gym', null if skipped
  String? ageBand; // 'young' | 'mid' | 'older', null if skipped
  List<String> bodyIssues; // subset of knee/shoulder/lower_back
  int? userDays; // planned weekly training days: 2/3/4/5 (5 = 5+)

  AppSettings({
    this.lang = 'system',
    this.appearance = 'system',
    this.remindersOn = false,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.feedbackOn = true,
    this.onboardingDone = false,
    this.userTier,
    this.userEquipment,
    this.ageBand,
    List<String>? bodyIssues,
    this.userDays,
  }) : bodyIssues = bodyIssues ?? const [];

  Map<String, dynamic> toJson() => {
        'lang': lang,
        'appearance': appearance,
        'remindersOn': remindersOn,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'feedbackOn': feedbackOn,
        'onboardingDone': onboardingDone,
        'userTier': userTier,
        'userEquipment': userEquipment,
        'ageBand': ageBand,
        'bodyIssues': bodyIssues,
        'userDays': userDays,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        lang: (j['lang'] ?? 'system') as String,
        appearance: (j['appearance'] ?? 'system') as String,
        remindersOn: (j['remindersOn'] ?? false) as bool,
        reminderHour: (j['reminderHour'] ?? 19) as int,
        reminderMinute: (j['reminderMinute'] ?? 0) as int,
        feedbackOn: (j['feedbackOn'] ?? true) as bool,
        onboardingDone: (j['onboardingDone'] ?? false) as bool,
        userTier: j['userTier'] == null ? null : (j['userTier'] as num).toInt(),
        userEquipment: j['userEquipment'] as String?,
        ageBand: j['ageBand'] as String?,
        bodyIssues: ((j['bodyIssues'] ?? []) as List)
            .map((e) => e as String)
            .toList(),
        userDays: j['userDays'] == null ? null : (j['userDays'] as num).toInt(),
      );
}
