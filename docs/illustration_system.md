# Illustration System Template (v1, locked 2026-08-31)

Locked decisions:
- Subject: muscle/skeleton anatomy style, no realistic face
- Style: clean vector-like anatomical illustration
- Palette: dark background `#15171A`, accent green `#4EBB8A` for the target
  muscle group; supporting anatomy in desaturated gray
- Perspective: fixed 3/4 side view (45 degrees), chest-to-knee framing
- Character: generate ONE lead reference image first, then reuse it across all
  exercises (same body shape, same clothing, same style)
- Size: 512×512 px minimum, PNG with no background compression
- Review: YOU check each image before use (form accuracy: start/end posture,
  joint angles, grip/placement, highlighted muscle group)

## Step 1 — Generate the lead character reference

```
A clean anatomical illustration of a single figure standing in profile view
(3/4 side angle, 45 degrees) with visible muscle structure, no facial features
detailed, wearing dark athletic clothing (#2A2A2F), on a dark background
(#15171A), sharp vector style, no text, no labels, no background elements.
Body proportion: average adult athletic build, neutral stance, arms slightly
flexed at sides.
```

Generate 4-6 candidates. Pick the ONE you like most. Save it as
`assets/illustrations/_ref_lead.png` — every subsequent image references this.

## Step 2 — Exercise illustration prompt template

For each exercise (one at a time), use:

```
A clean anatomical illustration in the exact same style as the reference image
showing the figure performing [EXERCISE NAME], viewed from a 3/4 side angle
(45 degrees), with the [TARGET MUSCLE GROUP] highlighted in fresh green
(#4EBB8A) against neutral gray anatomy, on the same dark background (#15171A).
Show the correct starting posture, joint angles, and movement path clearly.
No text, no labels, no background elements. Match the reference character's
body shape, clothing, and overall style exactly.
```

Replace [EXERCISE NAME] with the English name (e.g. "bodyweight squat",
"dumbbell bench press"). Replace [TARGET MUSCLE GROUP] with the primary muscle
highlighted (e.g. "quadriceps and glutes", "chest and triceps").

Attach the lead reference image every time so the AI can match style.

## Step 3 — Review checklist (one image ≈ 5-10 min)

- ✅ Start posture matches the exercise's "How to do it"
- ✅ Joint angles look correct (knees over toes, elbows tracking, etc.)
- ✅ The highlighted muscle group matches the exercise's primary target
- ✅ No anatomical impossibilities (extra limbs, twisted spine)
- ⛔ If the pose is wrong, regenerate with a more specific description or
  mark it as "示意" and move on

## Output naming

`assets/images/<exercise_id>.png` — the app's `exerciseById()` loader
already expects this exact path. Current placeholders: icon tiles.
