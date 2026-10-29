library;

/// Injury-aware substitution map: flagged exercise → suggested alternative
/// from the library, same movement family where possible, chosen to avoid
/// the flagged joint and never needing more equipment than the original. Alternatives with no clean
/// in-library substitute are absent (warning-only, no auto-suggestion).

const Map<String, Map<String, String>> substitutions = {
  // ---- knee
  'jump_squat': {'knee': 'squat_bw'},
  'lunge_bw': {'knee': 'glute_bridge'},
  'db_lunge': {'knee': 'glute_bridge'},
  'bulgarian_split_squat': {'knee': 'glute_bridge'},
  'db_stepup': {'knee': 'glute_bridge'},
  'reverse_lunge': {'knee': 'glute_bridge'},
  'lateral_lunge': {'knee': 'glute_bridge'},
  'pistol_squat': {'knee': 'single_leg_bridge'},
  'nordic_curl': {'knee': 'single_leg_bridge'},
  'db_split_squat': {'knee': 'db_hip_thrust'},
  'hack_squat': {'knee': 'db_hip_thrust'},
  // ---- shoulder
  'pike_pushup': {'shoulder': 'pushup'},
  'db_shoulder_press': {'shoulder': 'pushup'},
  'arnold_press': {'shoulder': 'pushup'},
  'bench_dip': {'shoulder': 'knee_pushup'},
  'db_overhead_ext': {'shoulder': 'pushup'},
  'db_fly': {'shoulder': 'pushup'},
  'bb_bench_press': {'shoulder': 'db_floor_press'},
  'bb_incline_press': {'shoulder': 'db_floor_press'},
  'close_grip_bench': {'shoulder': 'rope_pushdown'},
  'overhead_rope_ext': {'shoulder': 'rope_pushdown'},
  'pec_deck': {'shoulder': 'chest_press_machine'},
  // lateral_raise / cable_lateral_raise / db_front_raise /
  // machine_shoulder_press: no clean delt substitute without shoulder load
  // ---- lower back
  'db_rdl': {'lower_back': 'glute_bridge'},
  'db_bentover_row': {'lower_back': 'db_row_onearm'},
  'superman': {'lower_back': 'bird_dog'},
  'back_extension': {'lower_back': 'bird_dog'},
  'db_swing': {'lower_back': 'db_hip_thrust'},
};

/// First matching alternative for an exercise given the user's flagged
/// issues, or null when no clean substitute exists.
String? substituteFor(String exerciseId, List<String> issues) {
  final byCondition = substitutions[exerciseId];
  if (byCondition == null) return null;
  for (final issue in issues) {
    final alt = byCondition[issue];
    if (alt != null) return alt;
  }
  return null;
}