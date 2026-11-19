# Architecture & Design Notes

This document explains how IronPath is structured, how its design system and procedural animation engine work, and key engineering conventions for contributors.

## Core Concept

One **session player** engine, two front doors:
- **Beginners** follow structured built-in programs across three difficulty tiers (beginner / intermediate / advanced).
- **Experienced lifters** build and edit custom workout plans.

Logging happens as a byproduct of completing sets. Everything runs locally in `SharedPreferences` as JSON blobs (`lib/store.dart`) — zero accounts, zero cloud, zero tracking.

---

## Project Layout

```text
lib/
  main.dart                 App entry, theme & font license registration, system observers
  theme.dart                Design tokens (Iron), contrast solver, shared components
  models.dart               Exercise / Plan / PlanItem / SessionLog / SetLog / AppSettings
  store.dart                Local-only persistence (SharedPreferences JSON blobs)
  l10n.dart                 Bilingual (en/zh) dictionary
  utils.dart                Date, duration, and number formatting
  training_stats.dart       Rep targets, volume, sets per muscle, records, trends, streaks
  weekly_program.dart       Weekly schedule expansion & unified plan recommendation score
  system_colors.dart        Material You / desktop accent color reader (dynamic_color)
  motion.dart               Spring curves, Pressable feedback, RollingText
  widget_bridge.dart        Feeds native Android & iOS home-screen widgets after every save
  data/
    exercises_seed.dart     Aggregates seed files and exposes exerciseMap
    exercises_seed_bw.dart  54 bodyweight exercises (bilingual coaching copy)
    exercises_seed_db.dart  41 dumbbell exercises
    exercises_seed_gym.dart 47 barbell / machine / cable exercises
    substitutions.dart      Joint-friendly swap map for contraindicated movements
    plans_seed.dart         17 built-in sessions across 3 tiers
    exercise_motions.dart   Parametric 2D motion definitions for all 142 exercises
    tips.dart               Bilingual rest & recovery tips
  screens/
    root.dart               4-tab shell (Today / Plans / Exercises / History)
    onboarding_screen.dart  4-question functional personalization wizard
    home_screen.dart        Today: hero workout card, week strip, weekly muscle map
    library_screen.dart     Recommended plan, tier overview, custom & built-in plans
    exercises_screen.dart   Searchable, filterable 2-column exercise catalog
    plan_detail.dart        Plan breakdown, muscle map, start / duplicate / edit / delete
    plan_editor.dart        Custom plan builder + searchable exercise picker
    session_screen.dart     Core workout player: set table -> rest timer -> summary
    exercise_detail_screen.dart  Animated demo, bento metadata, coaching copy, records
    history_screen.dart     Bento stats, 8-week chart, 30-day muscle map, swipe-to-delete log
    settings_screen.dart    Appearance, color theme, language, feedback, reminders, licenses
  widgets/
    bento.dart              BentoRow / BentoSplit / BentoTile / BentoStat
    body_paint.dart         Anatomical limb/torso profiles & shaded body painter
    exercise_motion.dart    2D rig, two-bone IK solver, props, animation controller
    muscle_glyph.dart       Static anatomy glyph & front/back MuscleMap heat map
    ios_chrome.dart         Adaptive Apple / Material chrome & frosted glass surfaces
    plan_card.dart          Tier cards, plan rows, tier icons & labels
    theme_crossfade.dart    Snapshot cross-fade for theme/appearance/language switches
    weekly_chart.dart       Interactive 8-week bar chart with goal hairline
    weekly_program_card.dart  Today hero card & weekly schedule sheet
    zoom_route.dart         Card-to-page zoom transition (iOS zoom / Material container)
android/                    Android app + native WeekWidgetProvider.kt
ios/IronPathWidget/         iOS WidgetKit extension sources (SwiftUI)
```

---

## Programming & Personalization

### Built-in Library
- **142 exercises** across bodyweight (54), dumbbell (41), and gym/barbell/cable/machine (47) categories, each with bilingual coaching copy and primary/secondary muscle keys (`chest`, `back`, `shoulders`, `traps`, `biceps`, `triceps`, `forearms`, `core`, `lower_back`, `glutes`, `quads`, `hamstrings`, `adductors`, `abductors`, `calves`, `cardio`, `full_body`).
- **17 built-in plans** across three tiers:
  - **Tier 1 (Beginner)** uses dumbbells, bodyweight, and guided machines — never barbells — so beginners can train safely without a spotter.
  - **Tier 2 (Intermediate)** introduces self-rescuing barbell lifts (squat with rack safeties, deadlift, overhead press). Barbell bench press stays in the exercise library for custom plans rather than built-in rotations.
  - **Tier 3 (Advanced)** includes full bodyweight + dumbbell coverage so dumbbell-only lifters retain a complete progression track at every tier.

### Onboarding Rules & Weekly Derivation
First-launch onboarding asks four functional questions (skippable and re-runnable from Settings):
1. **Training experience (tier)** — guides recommended difficulty tier.
2. **Available equipment** (`none` / `dumbbell` / `gym`) — flags unavailable movements (`Needs {equipment}`) and biases plan recommendations toward executable workouts.
3. **Age band** (`55+` adds +30 s to rest intervals in the session player and surfaces periodic deload reminders on Tier 2/3 plans).
4. **Joints to protect** (`knee` / `shoulder` / `lower_back`) — displays caution chips on contraindicated exercises and offers a one-tap swap (`lib/data/substitutions.dart`) into a custom copy of the plan.

`lib/weekly_program.dart` scores plans using `unavailable * 100 + freqDistance * 10 + tierDistance` and expands the selected rotation (full-body A/B, upper/lower, PPL, or 5-day split) into day-by-day slots for the week, tracking completion from `SessionLog` history.

---

## Logging & Progress Maths

`lib/training_stats.dart` contains all pure training calculations (covered by `test/training_stats_test.dart`):
- **Set prefill**: each set starts from this workout's previous set, falling back to the corresponding set from the previous session, then the bottom of the target rep range.
- **Double progression**: when every planned set reached the top of its target rep range last session, the session card prompts the user to add load (or progress to a harder variant).
- **Records & volume**: tracks total volume (`kg × reps`, or total reps for bodyweight sessions), personal records (heaviest load or highest bodyweight reps), best set per exercise, top-set trend lines, and weekly streaks.
- **Muscle maps**: `MuscleMap` shades front and back muscle groups by working sets (1.0 credit for primary muscle, 0.5 for secondary muscles).

---

## Procedural Exercise Animation Engine

Every one of the 142 exercises has a native vector skeletal animation written purely in Dart (`lib/widgets/exercise_motion.dart`, `lib/widgets/body_paint.dart`, `lib/data/exercise_motions.dart`) — zero raster sprites or Lottie files.

- **2D Rig & Two-Bone IK**: poses specify hips, torso, hands, and feet; a two-bone inverse kinematics solver places knees and elbows so bone lengths remain constant across frames.
- **Anatomical Shading**: each limb is a `Segment` built from a `Profile` of front/back or outer/inner half-widths so limbs taper realistically into joints, with soft directional shading and stage-colored overlap separation gaps.
- **Muscle Regions**: working muscles render on anatomically accurate sides of each limb segment (biceps on the folding side of the upper arm, triceps behind, quads in front, hamstrings and calves behind) and highlight in the plan's tier hue.
- **Parametric Families**: exercises pick from reusable motion families (squat, hinge, lunge, press, row, curl, plank, crunch, hang, etc.) with configurable grip, props (bench, bar, cable, dumbbells, plate, box, wall, machine pads), camera view (side/front/top), and timing.
- **Reduce Motion**: plays 3 reps and settles into the key pose; under system Reduce Motion, holds the key pose directly.
- **Automated Verification**: `test/exercise_motion_test.dart` asserts every exercise has a registered motion, no joint sinks below the floor, bone lengths stay invariant, and painting succeeds in light and dark modes.

See also [docs/illustration_system.md](illustration_system.md) for the anatomy visual language notes.

---

## Design System & Adaptive Platform Chrome

- **Morandi Dual Palette** (`lib/theme.dart`): warm beige paper (`#F4F2EE`) in light mode, soft charcoal (`#191A19`) in dark mode, with dusty semantic tier hues (beginner mist blue, intermediate grey violet, advanced clay rose) and a single action accent.
- **Dynamic & Custom Color Themes**: ships with **System** (Material You wallpaper accent via `dynamic_color` on Android 12+ / desktop, gracefully falling back to Sage on platforms without system accent colors), 6 curated presets (Sage, Plates, Chalk, Trail, Pool, Dawn), and a full-spectrum **Custom** hue slider. Contrast math enforces `>= 3:1` on tinted fills and `>= 4.5:1` on text (`>= 7:1` under system High Contrast). Verified across all presets and a 15° hue sweep in `test/theme_test.dart`.
- **Continuous Geometry & Adaptive Chrome**: uses rounded superellipse corners (`Iron.squircle`), concentric nested radii (`Iron.inner`), and capsule controls. `lib/widgets/ios_chrome.dart` adapts navigation, sheets, dialogs, switches, segmented controls, and frosted glass surfaces to Apple vs. Material conventions via `isApple(context)`.
- **Motion** (`lib/motion.dart`, `lib/widgets/zoom_route.dart`): SwiftUI-style `SpringCurve` tokens, `Pressable` pointer feedback, card-to-page zoom transitions, rolling number counters (`RollingText`), and snapshot `ThemeCrossfade` transitions — all respecting `AccessibilityFeatures.disableAnimations`.

---

## Home-Screen Widgets

`lib/widget_bridge.dart` syncs weekly progress (done/total, 7-day completion mask, next workout title, localized labels, and light/dark theme accents as signed 32-bit ARGB) via `home_widget` on launch and after every `Store.save()`.
- **Android**: `android/app/src/main/kotlin/io/github/danielez18/ironpath/WeekWidgetProvider.kt` (`RemoteViews`, light/dark accent support via Android 12+ `setColorInt`).
- **iOS**: `ios/IronPathWidget/IronPathWidget.swift` (SwiftUI WidgetKit: small, medium, and lock-screen circular/rectangular widgets). Requires adding the Widget Extension target in Xcode and enabling App Group `group.io.github.danielez18.ironpath` on both `Runner` and `IronPathWidget`.

---

## Development Notes

- **Tab state refresh**: All four tab screens stay alive inside `RootShell`'s `Stack` (`lib/screens/root.dart`). When a modal workout or pushed page mutates `Store`, callers refresh the active screen via `.then((_) => refresh())`. Re-tapping the active tab scrolls it to the top.
- **Kotlin incremental compilation**: `android/gradle.properties` sets `kotlin.incremental=false` to avoid Gradle/Kotlin incremental cache lock errors on Windows paths containing spaces.
