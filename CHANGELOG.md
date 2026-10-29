# Changelog

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
