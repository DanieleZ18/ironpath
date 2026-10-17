library;

/// Injury-aware substitution map: flagged exercise → suggested alternative
/// from the existing 40-exercise library, same movement family where
/// possible, chosen to avoid the flagged joint. Alternatives with no clean
/// in-library substitute are absent (warning-only, no auto-suggestion).

const Map<String, Map<String, String>> substitutions = {
  // ---- knee
  'jump_squat': {'knee': 'squat_bw'},
  'lunge_bw': {'knee': 'glute_bridge'},
  'db_lunge': {'knee': 'glute_bridge'},
  'bulgarian_split_squat': {'knee': 'glute_bridge'},
  'db_stepup': {'knee': 'glute_bridge'},
  // ---- shoulder
  'pike_pushup': {'shoulder': 'pushup'},
  'db_shoulder_press': {'shoulder': 'pushup'},
  'arnold_press': {'shoulder': 'pushup'},
  'bench_dip': {'shoulder': 'knee_pushup'},
  'db_overhead_ext': {'shoulder': 'pushup'},
  'db_fly': {'shoulder': 'pushup'},
  // lateral_raise: no clean side-delt substitute without shoulder involvement
  // ---- lower back
  'db_rdl': {'lower_back': 'glute_bridge'},
  'db_bentover_row': {'lower_back': 'db_row_onearm'},
  'superman': {'lower_back': 'bird_dog'},
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