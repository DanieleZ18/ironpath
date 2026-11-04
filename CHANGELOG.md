# Changelog

## 0.4.0 — 2026-11-04

### Logging and progress, the way strength apps do it
- The workout now logs every set as a row, like Strong and Hevy: set,
  last time, kg, reps (seconds for holds), done. The demo stays on top;
  the kg and reps steppers and Complete set are pinned at the bottom, in
  reach of a thumb. Bodyweight moves log reps only, with an "add weight"
  option.
- Each set starts where the last one left off: this workout's previous
  set, then the same set last time, then the bottom of the target range.
- When every set reached the top of the range last time, the card says
  it's time to add weight (or try a harder variant).
- Rest has −15 s, +15 s and skip.
- The list button shows the whole workout: tap an exercise to go to it.
  Leaving early now offers Finish and save (the sets you did are kept) or
  Discard, instead of losing everything.
- The finish screen sums the workout up: time, sets, volume (kg × reps),
  a muscle map of what it worked, and new records (heavier than ever, or
  more reps at bodyweight).
- Today: the lineup of the day's moves under the hero, the first move drawn
  straight on the card, your weekly streak on the week strip, and a muscle
  map of the week so far.
- History: a weekly streak tile, the last 30 days as a muscle map, and
  workout cards that show duration, sets, volume and each exercise's best
  set.
- Exercises: every tile shows the move in its key position. The exercise
  sheet adds "Your records": best set, last time, how often, and a trend
  line of your top set.
- Plans: each plan row shows the move it opens with.
- The ad placeholders no longer show in release builds.

### A more detailed figure
- The exercise figure now has a real body: limbs taper from a muscle
  belly to slimmer joints, the torso has a chest, waist and back curve,
  plus glutes, hands, feet and hair, and a soft shade on the side away from
  the light. Overlapping parts are separated by a thin line of the
  background, and limbs grow out of the body without seams.
- Muscles light up as muscle shapes where they actually are: biceps on the
  front of the upper arm and triceps on the back (no longer one "arm"
  colour), quads on the front of the thigh and hamstrings behind, calves on
  the back of the shin, adductors on the inner thigh, pecs, a six-pack,
  lats, traps and the outer hip.
- The small body chart in lists and the Exercises grid is now an anatomy
  figure, front or back, with every muscle group drawn in and the trained
  ones lit.

### Colours follow the phone
- New default colour theme, System (跟随系统): on Android 12+ the app takes
  its colour from your wallpaper, the way Material You does, and changes
  when the wallpaper does (picked up when you come back to the app). The
  whole theme stays in that one hue in the app's soft tones; the three
  levels become light, medium and deep shades of it.
- iPhone doesn't let apps read a system colour, so there System uses Sage;
  light and dark mode keep following the phone as before. Settings says
  which of the two is happening.
- The system's Increase Contrast (iOS) / High contrast text (Android)
  setting is followed live: secondary text steps up to 7:1, tertiary to
  5.5:1, hairlines get stronger, coloured text clears 7:1.
- The home-screen widgets now use the app's own accent (whatever theme
  you picked, System included) in light and dark, instead of fixed Sage.
- Fix: a fill's contrast against its own tinted block is now solved
  against the adjusted colour's tint, so it can't land just under 3:1.

### Home-screen widget
- "This week" widget on Android and iOS: your workouts this week day by
  day (a check on each day trained, a dot on today, rings on the sessions
  still to come), the count against your weekly goal, and the next
  workout. Updates after every workout, follows the app's language and
  appearance, resets with the new week even if the app stays closed,
  and opens the app on tap. iPhone also gets lock-screen versions (a
  gauge and a row).

### iOS 26/27 shape language
- Corners are now Apple's continuous curve (rounded superellipse) on every
  card, tile, sheet, dialog and blob; nested corners stay concentric with
  their parent; every button is a capsule.
- iPhone: the tab bar floats as a capsule of glass over the content, with a
  pill that slides to the selected tab; back, settings and sheet buttons
  are glass circles and capsules with the brighter edge highlight and
  darkened rim iOS 27 gave Liquid Glass. Android keeps its own bar and
  buttons.

### A clearer flow
- Four tabs: Today · Plans · Exercises · History. Settings moved behind
  the gear on Today.
- Today shows one thing: the workout to do now (with its first move
  demonstrated) and a seven-day strip of the week — a check on each day
  trained, a dot on today, rings on the sessions still to come. Tap the
  strip for the day-by-day plan.
- Plans opens with the levels (the one that fits you full width, the
  other two as half tiles), then your plans, then every built-in plan.
- New Exercises tab: the whole library, searchable, filtered by muscle and
  by equipment, as a grid of tiles; tap one for the demo and the how-to.

### Library: 101 → 142 exercises
- "Legs" split into quads, hamstrings, inner thighs (adductors), outer
  hips (abductors) and calves; forearms added. Every existing exercise
  re-tagged, the body figures and demos know the new regions.
- 41 new moves, each with bilingual coaching copy and an animated demo:
  Cossack squat, Copenhagen plank, sumo squat, curtsy and walking lunges,
  sissy squat, reverse Nordic, clamshell, fire hydrant, side-lying leg
  raise, frog pump, sliding leg curl, single-leg and seated calf raises,
  tibialis raise; dumbbell sumo deadlift, lateral / curtsy / walking /
  reverse lunges, good morning, Bulgarian split squat, wrist curls,
  reverse curl, suitcase carry; barbell front squat, RDL, good morning,
  sumo deadlift, reverse lunge, wrist and reverse curls; hip adduction
  machine, seated leg curl, seated calf raise, cable pull-through,
  kickback and hip adduction, reverse hyperextension.
- Injury-aware swaps cover the new moves.

### Exercise demos
- Every exercise (all 101) now shows how it moves: a vector figure
  animated in code, with the working muscles lit in the difficulty colour.
  Side, front or top view per move, with the bench, bar, cable, dumbbells
  or machine it needs.
- A demo plays three reps, then eases into the move's key position and
  holds. With Reduce Motion on, it shows that position only.
- Where they appear: the home hero (the workout's first move), the exercise
  sheet (larger; tap it to watch again) and the workout's set card (tap it
  for the full how-to).

### Bento layouts
- Home, plan detail, the exercise sheet and history are laid out as bento
  grids: one large tile per screen, with the supporting facts in smaller
  tiles around it.
- Home: this week's progress and your last workout side by side; the
  recommended level full width, the other two levels as half tiles.
- Plan detail: what the plan trains (body figure and top muscles) next to
  duration, total sets and the equipment needed.
- Exercise sheet: muscles next to target sets × reps, difficulty and
  equipment.
- History: workouts and total training time next to this week and sets
  done, plus a chart of workouts per week over the last 8 weeks, with your
  weekly goal marked. Tap a week to read it.
- Tiles grow with larger text sizes instead of cutting text off.

### Colour themes
- Settings → Theme colour: six presets — Sage (default, unchanged),
  Plates (difficulty colours follow bumper plates: yellow 15 kg, blue
  20 kg, red 25 kg), Chalk, Trail, Pool, Dawn — plus Custom: drag a hue
  slider and the whole palette retunes live.
- Beige and black remain the two backgrounds ("Light / Dark" are now
  labelled 米色 / 黑色 · Beige / Black); themes only lean them slightly.
- Every theme keeps text at WCAG 4.5:1 and fills at 3:1 in both
  appearances (tested for all presets and a sweep of custom hues).

### Motion
- Tapping a plan card zooms its detail page out of that card (iOS 18 zoom /
  Material container transform); closing zooms it back. Close by edge swipe
  or pull-down on iPhone, predictive back on Android — the gesture scrubs
  the animation.
- Cards, buttons and tiles respond to touch with a springy press.
- Workouts open as a full-screen modal.
- Numbers roll into place (rest countdown, stats, week progress).
- Completing a set gives a light haptic and pops its dot; the rest ring
  draws itself in; the last three seconds turn to the accent.
- Finishing a workout is a single choreographed moment: the check draws
  itself, the stats count up, and a success haptic lands.
- Theme, appearance and language changes cross-fade; the app follows the
  phone's dark mode live.
- Honours Reduce Motion / Remove animations everywhere.

### Polish
- Workout: the kg and reps − / + buttons have a 48 px touch area (the
  platform minimum) while keeping their size on screen.
- Choice cards (onboarding, settings) show a clearly visible empty ring
  and tell screen readers whether they are selected.
- Plan editor: the move up, move down and remove buttons are labelled for
  screen readers.
- The exercise sheet and plan detail show the muscle map front and back,
  so muscles on the back of the body (glutes, hamstrings) light up too.
- Onboarding: each level says what it means (new or returning, 6+ months
  of regular training, years of steady training).
- "Works" is now "Muscles worked"; whole hours read "6 h" instead of
  "6 h 0 min".

### Fixes
- Tab bar labels overflowed the bar at large text sizes; they now stay
  near their designed size, as on iOS.

## 0.3.0 — 2026-10-29

### Design
- New "soft & friendly" look across every screen: rounded cards, pill
  chips, larger type hierarchy, bundled Nunito font (Latin subset, OFL-1.1,
  listed under Settings → Open-source licenses).
- Morandi palette: grey-beige / grey-charcoal surfaces, sage accent, dusty
  tier hues (beginner mist blue, intermediate grey violet, advanced clay
  rose). Every text colour clears WCAG 4.5:1 in light and dark.
- Exercises show a small body figure with the trained muscles highlighted
  (front or back view, zoomed to the relevant half at list size).
- Session player: set dots, ±2.5 kg weight buttons, thick continuous rest
  ring, stat tiles on the finish screen.

### Navigation & interaction
- iPhone: iOS patterns — collapsing large titles, frosted nav and tab bars,
  card sheets for the exercise picker and exercise details, action sheets,
  long-press context menu on plans, segmented controls, wheel time picker,
  slide-in pages with edge swipe-back.
- Android: the native equivalents — predictive back, bottom sheets,
  dialogs, overflow and popup menus, segmented buttons, clock time picker.
- Both: swipe a history entry left to delete it (with undo); tabs
  cross-fade and keep their scroll position; tapping the active tab
  scrolls to the top; onboarding has a Back button.
- System widgets (time picker, menus, tooltips) now follow the app
  language.

### Content
- Exercise library grows from 59 to 101: bodyweight pulling without a bar
  (inverted row), rear delts, glute and hinge work, more core and cable
  moves — each with full bilingual coaching copy.
- Injury-aware swaps cover the new moves (and barbell bench → floor press).

### Fixes
- The weekly A/B rotation flipped on Thursdays instead of Mondays, and ISO
  week numbers were wrong around New Year.
- "N moves need …" always said dumbbells, even when a gym was needed.
- The last set of a workout started a pointless rest; quitting during it
  discarded the whole session. The workout now saves immediately.
- An empty plan crashed the session player.
- Onboarding's "6 days" option was labelled "5 days".
- Custom plans were labelled "Advanced".
- Editing a plan dropped its `idealDays`.
- Denied screen wake lock (browsers) surfaced as an uncaught error.

### Tests
- 8 → 32 tests: week maths, equipment labels, session flow, every screen
  rendered in both themes and languages, data integrity for all exercises
  and injury swaps, and the interaction flows on both Android and iOS.

## 0.2.0

- Offline-first bilingual workout trainer: built-in plans in three tiers,
  custom plans, session player with rest timer, history, onboarding with
  equipment / frequency / age / injury-aware recommendations.
