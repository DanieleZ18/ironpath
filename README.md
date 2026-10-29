# IronPath (gym_app)

Offline-first, no-login workout trainer. One "session player" engine, two front
doors: beginners follow built-in plans (beginner / intermediate / advanced),
experienced users build custom queues. Logging is a byproduct of completing
sets. Bilingual (zh/en), zero accounts, zero cloud.

## Weekly program (2026-09-09)

After onboarding, home shows **"你的每周计划"** — the user's rotation expanded
into day-by-day slots for the week (`lib/weekly_program.dart`, pure and
unit-tested): pairs alternate (barbell/bodyweight/full A-B, upper/lower ×2 —
odd-day weeks flip the starting session so A/B stay balanced), PPL cycles at
3/6 days, the five-way split runs chest→back→shoulders→arms→legs at exactly 5.
Per-day done state derives from this week's logs (`completedThisWeek`); the
next unfinished day is highlighted "今天练这个". `recommendationScore` lives in
the same file and is shared by home, tier cards and the weekly derivation.
Skipped-onboarding users don't see the card.

## Library (2026-09-09)

101 exercises (40 bodyweight + 28 dumbbell + 33 gym; expanded 2026-10-29 with bodyweight pulling, rear delts, glute/hinge work, core and cable moves) and **17 builtin plans**
across three tiers. **Beginners train with dumbbells and machines, never
barbells** (2026-09-09): tier-1 gym track is Beginner · Gym A/B (goblet squat,
machine chest press, lat pulldown, leg press, DB rows/press/RDL — machines
guide the path, dumbbells fail safe, so no spotter is needed). Barbells enter
at tier 2, and only the three self-rescuing lifts: squat (rack safeties, empty
bar), deadlift (miss = drop it), overhead press (miss = step back) — barbell
bench press is out of all builtin rotations because a failed rep needs a
handout (still in the library for custom plans). Tier 2 gym upper leads with
dumbbell bench; tier 3 stays bodyweight+dumbbell so dumbbell-only users keep a
complete track at every tier. Training tips (`lib/data/tips.dart`, 9 bilingual
entries) rotate on the rest screen; a recovery tip shows on the finish screen.

## Design — soft & friendly, Morandi palette (2026-10-29, v4.1)

Two palettes sharing one token API (`lib/theme.dart`, `Iron` class — screens
never hardcode colors). Switch via Settings → Appearance (auto/light/dark);
persisted in settings, applied at launch and live.

**Colour carries meaning, quietly.** Each tier owns a dusty hue — beginner
mist blue, intermediate grey violet, advanced clay rose — shown as soft tinted
blocks (`Iron.tint(hue)`), and the plan's hue follows it into plan detail and
the session player. One sage accent marks actions and progress; custom plans
use the accent. The hues are *fill* tones (dots, rings, blocks, glyphs):
wherever one is used as text or behind white text, `Iron.inkOf(hue)` derives a
deeper shade of the same hue that clears 4.5:1 — the text helpers
(`Iron.body/caption/hero/eyebrow`) apply it automatically.

**Light**: grey-beige paper `#F4F2EE`, white cards + soft shadow, ink
`#2E302E`, sage `#5E7F6A`, tiers `#6F8BA6/#8A7AA0/#B07A6A`, tints at 14%.

**Dark**: grey charcoal `#191A19`, cards `#232523`, sage `#8FB09A`, tiers
`#9DB3C9/#B4A8C8/#D0A595`, tints at 18%.

**Exercise glyphs** (`lib/widgets/muscle_glyph.dart`): until illustrations
land, each exercise shows a small body figure with its muscles highlighted —
primary muscle full strength (decides front/back view), secondary lighter.
Below 80px the figure zooms to the upper or lower half of the body so list
rows stay legible.

**Type**: Nunito (rounded terminals, tabular digits) bundled in
`assets/fonts/` — Latin subset, 4 weights, ~130 KB, OFL-1.1 (registered on
the licenses page). CJK falls back to the system font. Hierarchy from weight
(400/600/700/800) + size.

**Geometry**: radius 28/24/18/12, 56px pill-ish buttons, stadium chips.

**Motion**: pages use the platform transition (Android predictive back /
fade-forwards, iOS swipe-back), tabs cross-fade with a slight drift (220ms),
onboarding questions slide in the direction of travel, session phases fade
and rise (280ms), the rest ring sweeps continuously. Theme switches apply in
one frame (`themeAnimationDuration: zero`) because widgets read the palette
directly.

**Shared components** (`lib/theme.dart`): `IronCard` (white or tinted,
tappable), `IronButton`, `IronPill`, `IconBlob` (icon on a soft tint), `SetDots` (● ● ○ ○), `BarbellProgress`,
`RestRing` (thick 16px ring), `ChoiceTile`, `StatTile`, `SectionTitle`.
Screens compose these instead of hand-rolling boxes.

Signatures: home hero "today's workout" card in the tier hue with week dots;
session set card with dots per set and ±2.5 kg weight buttons; rest clock =
thick green ring around a 64px `M:SS`; finish screen with stat tiles.

## Status (2026-08-30)

- Flutter 3.47.2 stable installed at `D:\flutter` (not on PATH by default:
  `export PATH="/d/flutter/bin:$PATH"` in Git Bash).
- `flutter analyze` clean, seed-consistency tests pass, `flutter build web` OK.
- Android toolchain: the SDK already existed at `C:\Users\Daniele\android-tools\android-sdk`
  (left over from the Capacitor bookkeeping app in `D:\Project-1` — its
  `frontend/android/local.properties` recorded the path). `ANDROID_HOME` /
  `ANDROID_SDK_ROOT` are now set permanently (user env vars), and Flutter is
  pointed at the Temurin JDK 21 next to it via `flutter config --jdk-dir`.
  `flutter doctor` is fully green; a reusable AVD `jianji-test` exists.
- Web preview works today: `flutter run -d chrome`.

## Layout

```
lib/
  main.dart                 app entry, theme + font license registration
  theme.dart                design tokens + shared components (see Design)
  models.dart               Exercise / Plan / PlanItem / SessionLog / SetLog / AppSettings
  store.dart                local-only persistence (SharedPreferences JSON blobs)
  l10n.dart                 hand-rolled zh/en dictionary (upgrade path: gen-l10n)
  utils.dart                date/duration formatting
  data/
    exercises_seed.dart     combines the seed files, exposes exerciseMap
    exercises_seed_bw.dart  40 bodyweight exercises (bilingual, full coaching copy)
    exercises_seed_db.dart  28 dumbbell exercises
    exercises_seed_gym.dart 33 barbell / machine / cable exercises
    substitutions.dart      injury-aware swap map
    plans_seed.dart         17 builtin sessions across 3 tiers
  screens/
    root.dart               4-tab shell (home / plans / history / settings)
    home_screen.dart        last-workout line + tier quick-start cards
    library_screen.dart     builtin plans by tier + my plans
    plan_detail.dart        plan view, start, duplicate-to-edit, delete
    plan_editor.dart        custom plan editor + searchable exercise picker
    session_screen.dart     THE CORE: exercise -> rest -> finished state machine
    exercise_detail_screen.dart
    history_screen.dart
    settings_screen.dart    language, reminder time (stub), disclaimer
  widgets/plan_card.dart    tier cards + plan cards, tier labels/icons
  widgets/weekly_program_card.dart  home "today" hero + weekly day list
```

## Conventions

- Exercise names use canonical English (`bench press` is `bench press`); copy is
  written as terse 2-3 sentence blocks so the bilingual cost stays manageable.
- Exercise images belong at `assets/images/<id>.png` (AI-generated with one
  locked style prompt, each image reviewed for form accuracy). Until they land,
  screens show icon placeholders.
- Builtin plans are `const` seeds; user plans are deep-copied into
  `Store.customPlans` and serialized. Custom plan titles are stored once and
  shown in both languages.

## Roadmap (from the 8-10 week plan)

1. W2-3 (done 08-31): screen-on during workouts, rest-end beep+vibration,
   last-weight prefill. Next in this bucket: countdown beeps at 3-2-1,
   sound/vibration toggle in settings.
2. W4: plan programming review — the three tiers' splits and progression rules
   are written by the owner from their own training experience.
3. W5: real reminders via `flutter_local_notifications` (settings screen already
   stores the time).
4. W6-7: AdMob — home banner + post-session interstitial, Android only (the web
   build carries no ads in MVP). Then the one-time remove-ads IAP.
5. W8: Play listing (privacy policy URL, Data Safety form declares the AdMob
   device identifiers), health disclaimer is already in Settings.

Package name `com.daniele.gym_app` and the title "IronPath" are placeholders —
the app name is still an open decision.

## Onboarding & personalization (2026-08-31, v2 — four questions)

First-launch questionnaire: four functional questions — training experience
(tier), available equipment, age band, body areas to be careful with
(multi-select). Skippable, once only, re-runnable from Settings. Every
answer executes a rule:

- **tier** → home "Recommended for you" badge
- **equipment** → "Needs {equipment}" tags in plan detail and the exercise
  picker (`Exercise.requiredEquipment()`/`availableFor()`; category →
  equipment: bodyweight→none, dumbbell→dumbbell, machine/barbell→gym)
- **ageBand 'older' (55+)** → all rest times +30s in the session player; a
  deload-hint card on tier-2/3 plan pages ("every 4-6 weeks at 55+")
- **bodyIssues (knee/shoulder/lower_back)** → "Careful: {area}" warning chips
  on contraindicated exercises (`Exercise.contraindications`, 15 exercises
  tagged) plus a one-tap "Swap to {alternative}" chip
  (`lib/data/substitutions.dart`) that duplicates builtin plans into My
  plans with the item replaced

Deliberately NOT asked: body weight. Age is a band, not a number. Silent
auto-substitution inside the session player remains v1.1 scope.

**Equipment-aware recommendation**: home quick-start offers the plan with the
fewest unavailable exercises in the tier (`unavailableCount`); with no
equipment at all, the recommendation falls back to the two bodyweight-only
plans (`Beginner · Bodyweight A/B`) — their descriptions honestly flag the
missing pulling movements. Plans with unavailable items show "N moves need
{equipment}" on cards and detail pages.

**Frequency-aware recommendation**: every plan declares its intended weekly
rhythm (`Plan.daysMin`/`daysMax` plus `idealDays` — the exact day-counts the
split is designed for), the questionnaire asks planned weekly days
(`settings.userDays`, 2-6), and a unified score picks the recommendation
across ALL plans:
`unavailable*100 + freqDistance*10 + tierDistance`. Rotations shipped:
full-body (2-4d), upper/lower (2-5d), PPL (3 or 6d), five-way bro split
(exactly 5d — Chest/Back/Shoulder/Arm + the shared Legs day). Frequency
labels appear on cards and plan detail.

## Verified end to end (2026-08-30/31)

Built, installed and exercised on the `jianji-test` emulator: full session
(15 sets), rest timer, finish screen, home "last workout" line, history (logs
persist across app restarts), settings/language/appearance switch, dual theme.
Session player polish (2026-08-31): screen stays on during workouts
(`wakelock_plus`), rest-end natural expiry plays `SystemSound.alert` +
medium haptic, and the weight field prefills from the current session's
earlier sets, falling back to the most recent logged weight from history
(`Store.lastWeightFor`) with a "上次: X kg" helper line.
`flutter analyze` clean.

## Troubleshooting

- `kotlin.incremental=false` is set in `android/gradle.properties`: Kotlin
  incremental compilation fails with "Could not close incremental caches" when
  the project path contains a space (`D:\Projects\3 Gym`). Non-incremental
  compiles are fine at this project size. Remove it only if the project moves
  to a space-free path.
- If a build fails with Kotlin cache errors after an aborted build:
  `cd android && gradlew.bat --stop`, kill stray `KotlinCompileDaemon` processes
  (see them with `jps -l`), then `flutter clean`.
- Tab screens (home/library/history/settings) all stay alive in one Stack
  (`RootShell`, cross-faded by `_FadeThroughTab`) and must be refreshed
  manually when data changes elsewhere — see `RootShell._select` and the
  `.then((_) => refresh())` pattern after pushing the session screen.
  Re-tapping the active tab scrolls it to the top (one ScrollController per
  tab).
