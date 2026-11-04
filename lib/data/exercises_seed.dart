import '../models.dart';
import 'exercises_seed_bw.dart';
import 'exercises_seed_db.dart';
import 'exercises_seed_gym.dart';

// The full exercise library: 54 bodyweight + 41 dumbbell + 47 gym = 142 entries.
// Demos: lib/data/exercise_motions.dart (every id needs one; tested).

const List<Exercise> exercisesSeed = [
  ...bodyweightSeed,
  ...dumbbellSeed,
  ...gymSeed,
];

final Map<String, Exercise> exerciseMap = {
  for (final e in exercisesSeed) e.id: e,
};
