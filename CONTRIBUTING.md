# Contributing to IronPath

Thank you for your interest in contributing to IronPath! Bug reports, exercise library improvements, translations, accessibility enhancements, and pull requests are all welcome.

## Development Setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>= 3.4.0`).
2. Fork and clone the repository:
   ```bash
   git clone https://github.com/<your-username>/ironpath.git
   cd ironpath
   flutter pub get
   ```
3. Verify everything passes locally before making changes:
   ```bash
   flutter analyze
   flutter test
   ```

## Conventions

- **Offline-first & zero bloat**: Keep dependencies minimal. Do not introduce analytics, telemetry, ads, or network requirements.
- **Design tokens**: Always use `Iron.*` tokens and shared components in `lib/theme.dart` instead of hardcoding colors or radii. Any theme or color change must pass contrast checks in `test/theme_test.dart`.
- **Bilingual copy (`en` / `zh`)**: Keep strings concise (2–3 sentences for coaching copy) and update both English and Chinese entries in `lib/l10n.dart` and data seed files.
- **Adding a new exercise**:
  1. Add the exercise entry to the appropriate seed file (`lib/data/exercises_seed_bw.dart`, `exercises_seed_db.dart`, or `exercises_seed_gym.dart`).
  2. Use only valid muscle keys defined in `L10n.muscle` (the first muscle is primary and determines front/back anatomy view).
  3. Add a matching motion definition in `lib/data/exercise_motions.dart` (prefer reusing an existing parametric motion family).
  4. Run `flutter test test/widget_test.dart test/exercise_motion_test.dart` to verify seed integrity, valid muscle keys, floor clearance, and invariant bone lengths — and visually inspect the rendered pose.
- **Built-in plans vs. custom plans**: Built-in plans in `lib/data/plans_seed.dart` are `const` seeds; user plans are deep-copied into `Store.customPlans`.

## Pull Request Checklist

- [ ] `flutter analyze` passes with zero warnings or errors
- [ ] `flutter test` passes completely
- [ ] New behavior or bug fixes include unit/widget tests where applicable
- [ ] Both light & dark modes and both English & Chinese strings look clean
- [ ] Changes stay focused on a single concern with a clear description

## License

By contributing to IronPath, you agree that your contributions will be licensed under the **GNU General Public License v3.0** ([LICENSE](LICENSE)).
