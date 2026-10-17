import '../models.dart';
import 'exercises_seed_bw.dart';
import 'exercises_seed_db.dart';
import 'exercises_seed_gym.dart';

// The full exercise library: 24 bodyweight + 16 dumbbell + 19 gym = 59 entries.
// Images: `assets/images/<id>.png`, AI-generated with a locked style prompt.

const List<Exercise> exercisesSeed = [
  ...bodyweightSeed,
  ...dumbbellSeed,
  ...gymSeed,
];

final Map<String, Exercise> exerciseMap = {
  for (final e in exercisesSeed) e.id: e,
};