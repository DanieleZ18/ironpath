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

142 exercises (54 bodyweight + 41 dumbbell + 47 gym; expanded 2026-10-29
with bodyweight pulling, rear delts, glute/hinge work, core and cable
moves, and 2026-11-04 with 41 leg, hip, adductor, calf and forearm moves)
and **17 builtin plans**
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

**Muscle keys** (2026-11-04): chest, back, shoulders, traps, biceps,
triceps, forearms, core, lower_back, glutes, quads, hamstrings, adductors
(inner thighs), abductors (outer hips), calves, cardio, full_body. The
first muscle is the primary: it picks the body figure's view and the demo's
strong highlight. Labels live in `L10n.muscle`; `test/widget_test.dart`
rejects unknown keys.

## Flow (2026-11-04)

Four tabs — **Today · Plans · Exercises · History** — and settings behind
the gear on Today.
- Today (`home_screen.dart`): the one workout to do now (`TodayCard`, its
  first move demonstrated) and `WeekStrip`, seven columns with a check per
  day trained, a dot on today and rings on the sessions left; tap for the
  day-by-day plan as a sheet.
- Plans (`library_screen.dart`): the level that fits the onboarding answers
  full width, the other two as half tiles, then my plans, then every
  built-in plan by tier.
- Exercises (`exercises_screen.dart`): search + muscle chips + equipment
  chips over a two-column grid of `ExerciseTile`s (static figure, name,
  muscles); tap → the exercise sheet with the demo.
- History: stats bento, 8-week chart, the log.

## Home-screen widget (2026-11-04)

"This week" on the home screen, built with `home_widget` (native widgets,
fed from Dart). `lib/widget_bridge.dart` computes the week after every
`Store.save()` and at launch — done / total, a 7-flag string of days
trained, the next workout's title, and the labels already localised — and
writes it to the shared store, then asks both widgets to redraw. The
widgets reset to a fresh week on their own when `updated_at` is older
than this week's Monday, and redraw at midnight so "today" moves. They
draw with the app's own accent (`Iron.accentFor`, light and dark, sent as
signed 32-bit ARGB); on Android 12+ both values go to the launcher
(`setColorInt`) so it switches with the system's dark mode by itself.
- Android: `WeekWidgetProvider.kt` (RemoteViews, `res/layout/week_widget.xml`,
  dot drawables, `res/xml/week_widget_info.xml`, 4×2 default, launcher
  corner radius on Android 12+, light/dark colours). Registered in the
  manifest; nothing else to do.
- iOS: `ios/IronPathWidget/IronPathWidget.swift` (WidgetKit, SwiftUI;
  small, medium, lock-screen circular + rectangular; Liquid Glass tinting
  via `widgetAccentable`). One-time Xcode setup, since a target can't be
  added from here: File ▸ New ▸ Target ▸ Widget Extension → name
  `IronPathWidget` (uncheck the configuration intent), replace the
  generated Swift with this file and drop its `Info.plist` /
  entitlements in, then add the App Group `group.com.daniele.ironpath` to
  both Runner and the extension (Signing & Capabilities). The group id is
  `WidgetBridge.appGroup`; keep the three in sync. `Runner.entitlements`
  already carries it.
- Tests: `test/widget_bridge_test.dart` checks the payload (both
  languages) and the channel calls through a mocked `home_widget`.

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

**Colour themes** (2026-11-01, Settings → Theme colour): surfaces stay beige
(米色) / charcoal (黑色); a theme supplies the accent + three tier hues
(`ThemeSpec`), and leans the page a few percent toward its accent. Six
presets, each drawn from where training happens — Sage (default, the values
above, unchanged), Plates (tiers follow bumper-plate colours: yellow 15 kg →
blue 20 kg → red 25 kg), Chalk (graphite greys), Trail, Pool, Dawn — plus
Custom: any hue on a slider, from which `ThemeSpec.custom` derives the whole
set (tiers at +120°/+180°/+240°), solving each tone for a contrast target so
every hue is equally legible. A safety clamp keeps all fills ≥3:1 against
their tints; `inkOf` keeps text ≥4.5:1. `test/theme_test.dart` checks every
preset and a 15° sweep of custom hues in both appearances. Stored as
`AppSettings.themeId` / `customHue`.

**System theme** (2026-11-04, the default for new installs, `themeId:
'system'`): the colours follow the phone. `lib/system_colors.dart` reads
the system accent through `dynamic_color` — Android 12+'s wallpaper
palette (tone 40 of the primary palette), a desktop's accent colour — at
launch and on every resume; `ThemeSpec.system(hue)` keeps the whole theme
in that hue like Material You: the accent plus the three tiers as light /
medium / deep shades (difficulty is ordinal, so a one-hue ramp fits), each
solved for a contrast step. No system colour (iPhone, which gives apps
none; older Android; web) → Sage, and Settings says so. Light / dark has
followed the phone since v0.3 (`appearance: 'system'`).

**High contrast**: the system's Increase Contrast / High contrast text
(`AccessibilityFeatures.highContrast`) is followed live —
`Iron.setHighContrast` lifts secondary text to 7:1, tertiary to 5.5:1,
hairlines to 22 % and `inkOf` to 7:1.

**Exercise demos** (2026-11-01, `lib/widgets/exercise_motion.dart` +
`lib/data/exercise_motions.dart`): every one of the 101 exercises is shown
as a native vector skeletal animation — the SVG / Lottie idea, drawn and
driven in code, no assets. A rounded figure in the app's palette has a 2D
rig: poses are authored as where the hips, torso, hands and feet go, and a
two-bone solver places knees and elbows (bone lengths never change).
The figure (2026-11-04, `lib/widgets/body_paint.dart`): every bone is a
`Segment` drawn from a `Profile` of half-widths on its two sides — front /
back of the limb in side view, outer / inner in front view — so limbs swell
into a muscle belly and taper to the joints; the torso is a profile from
pelvis to shoulders (belly, waist, chest; sacrum, lumbar curve, shoulder
blades), plus glutes, deltoids, hands, feet and a hair cap. Muscles are
`Segment.region`s on the anatomically right side (biceps face the forearm
they fold onto, calves face the thigh), so they stay put through any pose.
Near limbs carry a thin stage-coloured gap (none at the hip / shoulder
seams); every part has a soft shade on the side away from a top-left
light.
Motions are parametric families (squat, hinge, lunge, press, row, curl,
plank, crunch, hang…) that exercises pick with their grip, props (bench,
bar, cable, dumbbells, plate, box, wall, machine pads) and timing; side view
by default, front or top view where the move happens across the body (with
foreshortening for limbs aimed at the camera). The working muscles light up
in the difficulty hue (primary full, secondary softer). A demo plays three
reps, eases into its key pose and holds — motion that shows the move, then
settles; under Reduce Motion it is that key pose. Shown in the home hero
(the session's first move), the exercise sheet (larger, tap to replay) and
the session set card (tap to open the how-to). `test/exercise_motion_test.dart`
checks every exercise has its own demo, no joint sinks into the floor at
any moment, bones keep their length, and it paints in both appearances.

**Exercise glyphs** (`lib/widgets/muscle_glyph.dart`): list rows and the
Exercises grid keep a small static anatomy chart — the same silhouette
language as the demo figure, front or back, every muscle group drawn in a
shade off the skin (pecs, six-pack, obliques, lats, traps, delts, biceps,
triceps, forearms, erectors, glutes, outer hip, quads, adductors,
hamstrings, calves) — with the primary muscle full strength (it decides
front / back) and secondary ones lighter. The geometry is built once per
view. Below 80px the chart zooms to the upper or lower half of the body.
Lists never animate.

**Bento layouts** (2026-11-01, `lib/widgets/bento.dart`): screens are built
from tiles of different sizes that share one 10px gutter — `BentoRow`
(tiles side by side, all as tall as the tallest) and `BentoSplit` (one tall
tile beside a stack). A tile's size says how much it matters: one hero per
screen, supporting facts around it. Fill carries meaning — a tier tint is
difficulty, the accent tint is progress, the plain card is information —
and radius steps down from hero (28) to tile (24) to row (18). Rows size to
their content, so larger text grows the grid instead of clipping it (tested
at 160%).
- today: hero with the first move demonstrated · the week strip
- plans: recommended level full width, the other two as half tiles
- exercises: two-column tile grid
- plan detail: hero · what it trains (body figure, top muscles) beside
  duration / volume / equipment
- exercise sheet: the demo as hero · muscles beside target / difficulty /
  equipment
- history: workouts and total time beside this week / sets done, then an
  8-week chart (`lib/widgets/weekly_chart.dart`): one column per week, this
  week in the accent and earlier weeks quiet grey, a hairline at the weekly
  goal from onboarding; tap a column to read its week, screen readers get
  every value

**Type**: Nunito (rounded terminals, tabular digits) bundled in
`assets/fonts/` — Latin subset, 4 weights, ~130 KB, OFL-1.1 (registered on
the licenses page). CJK falls back to the system font. Hierarchy from weight
(400/600/700/800) + size.

**Geometry** (2026-11-04, after iOS 26/27): every drawn corner is Apple's
continuous curve — `Iron.squircle(r)` (a `RoundedSuperellipseBorder`) on
cards, tiles, blobs, sheets, dialogs, snackbars; radii 28/24/18/12; a
nested corner is concentric with its parent via `Iron.inner(outer, gap)`
(outer radius minus the gap, never below 12); every control is a capsule
(`Iron.capsule`): buttons, pills, chips, the tab bar. Use `ShapeDecoration`
/ `Material(shape:)`, not `BorderRadius`, when adding surfaces.

**Liquid glass** (Apple only, `GlassSurface` in `ios_chrome.dart`): blur
of what's behind under a translucent card tint, a bright edge toward the
light and a darkened rim away from it (iOS 27's legibility pass). Used for
the floating tab bar (capsule, 18 pt in from the sides, a pill sliding to
the selected tab — `IronTabBar`), round bar buttons (`GlassIconButton`:
back, settings) and sheet bar buttons (`BarTextButton`: the one primary
action is a filled accent capsule, the rest glass). Android keeps its
translucent bar and Material buttons.

**iOS-style interaction** (2026-10-29, `lib/widgets/ios_chrome.dart`; look
stays Morandi + Nunito, only structure and gestures follow iOS). Everything
with a platform convention is adaptive via `isApple(context)`: Apple devices
get the Cupertino version, Android (and everything else) the Material one —
bottom sheet instead of iOS card sheet, dialog / overflow / popup menus
instead of action sheets and the context menu, SegmentedButton, Material
switch and clock time picker, arrow back / close icons. Large titles, the
frosted bars and swipe-to-delete are shared.
- tab pages: collapsing large titles (`largeTitleBar`, Cupertino sliver nav
  bar) and a translucent frosted tab bar (`IronTabBar`, `extendBody`)
- pushed pages (`IronPage`): transparent nav bar that frosts once content
  scrolls under it; detail titles fade in after the hero scrolls away
- page transitions are native per platform: iPhone slides in from the
  right with edge swipe-back (`CupertinoPageTransitionsBuilder`), Android
  keeps predictive back / fade-forwards (manifest opts into
  `enableOnBackInvokedCallback`); the session screen's PopScope blocks
  leaving mid-workout on both
- card sheets that push the page behind back (`showIronSheet`, drag to
  dismiss): exercise picker, exercise details
- action sheets for destructive choices (quit workout, delete plan, plan
  "…" menu); iOS alert for editing reps
- sliding segmented controls, iOS switches, wheel time picker in Settings
- history: swipe left to delete, with undo; library: long-press a plan for
  a context menu (start / details / copy / edit / delete)

**Motion** (2026-11-01, `lib/motion.dart`): motion answers what the user
did — press, open, confirm, change — and goes quiet under the system's
Reduce Motion. Springs are parameterised like SwiftUI
(`SpringCurve(response, dampingFraction)`; tokens `Motion.snappy / smooth /
bouncy`).
- press feedback: cards, buttons, choice tiles, tappable pills and weekly
  rows sink slightly and spring back (`Pressable`, raw pointers, so it never
  steals taps); on Apple devices presses dim instead of rippling
- card → plan detail: the page zooms out of the exact card tapped and back
  into it on close (`lib/widgets/zoom_route.dart` — iOS 18 zoom / Material
  container transform), the page behind recedes and dims; dismiss by iOS
  edge swipe or pull-down, or Android predictive back, all scrubbing the
  same animation; Reduce Motion → cross-fade
- workouts present as full-screen modals (slide up on iOS)
- numbers roll instead of jumping (`RollingText`): rest countdown, history
  stats, week progress
- session: completing a set taps a light haptic and pops its dot; the rest
  ring draws itself in and sweeps continuously; the last three seconds turn
  to the accent
- the one orchestrated moment: finishing a workout — ring sweeps closed,
  check draws, title rises, stats count up, success haptic as the check
  closes (one controller, `_FinishView`)
- tabs cross-fade with a slight drift; tab icons bounce on selection;
  onboarding questions slide in the direction of travel
- theme, appearance and language changes cross-fade like iOS appearance
  switches (`ThemeCrossfade`: snapshot the frame, apply, dissolve); the
  app follows the phone's dark mode live

**Shared components** (`lib/theme.dart`): `IronCard` (white or tinted,
tappable), `IronButton`, `IronPill`, `IconBlob` (icon on a soft tint), `SetDots` (● ● ○ ○), `BarbellProgress`,
`RestRing` (thick 16px ring), `ChoiceTile`, `StatTile`, `SectionTitle`.
Screens compose these instead of hand-rolling boxes.

Signatures: home hero "today's workout" card in the tier hue with the
session's first move demonstrated; session set card with the live demo,
dots per set and ±2.5 kg weight buttons; rest clock = thick green ring
around a 64px `M:SS`; finish screen with stat tiles.

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
    exercise_motions.dart   the 101 exercise demos as parametric motion families
  screens/
    root.dart               4-tab shell (today / plans / exercises / history)
    home_screen.dart        Today: hero + week strip (+ weekly plan sheet)
    exercises_screen.dart   the library: search, muscle/equipment chips, tile grid
    library_screen.dart     builtin plans by tier + my plans
    plan_detail.dart        plan view, start, duplicate-to-edit, delete
    plan_editor.dart        custom plan editor + searchable exercise picker
    session_screen.dart     THE CORE: exercise -> rest -> finished state machine
    exercise_detail_screen.dart  demo hero + bento facts + coaching copy
    history_screen.dart     bento stats + 8-week chart + swipe-to-delete log
    settings_screen.dart    pushed from Today's gear: appearance, theme, language, …
  widgets/plan_card.dart    tier cards + plan cards, tier labels/icons
  widgets/weekly_program_card.dart  home "today" hero + weekly day list
  widgets/exercise_motion.dart      demo rig: pose, IK solver, props, painter
  widgets/bento.dart        BentoRow / BentoSplit / BentoTile / BentoStat
  widgets/weekly_chart.dart workouts-per-week chart tile
  widgets/muscle_glyph.dart static muscle figure for list rows
  widgets/zoom_route.dart   card → page zoom transition
  widgets/ios_chrome.dart   adaptive iOS / Material chrome, glass surfaces
  widget_bridge.dart        feeds the home-screen widget after every save
android/.../WeekWidgetProvider.kt + res/layout|xml|drawable  the Android widget
ios/IronPathWidget/        the iOS widget extension sources (add the target in Xcode)
```

## Conventions

- Exercise names use canonical English (`bench press` is `bench press`); copy is
  written as terse 2-3 sentence blocks so the bilingual cost stays manageable.
- Every exercise needs a demo in `lib/data/exercise_motions.dart` (a test
  fails otherwise). Add it to an existing family where one fits; render it
  at a few moments of the cycle and look at it before shipping — the tests
  catch broken geometry, not a pose that reads wrong.
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
