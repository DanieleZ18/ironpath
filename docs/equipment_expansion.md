# Equipment Expansion Blueprint (v1.1)

Decision (2026-08-31): expand the library from 40 → 60-70 by adding gym-machine
exercises. The 26 below are ranked by usefulness for general strength training;
pick the ones you actually coach/perform before writing coaching copy.

## Chest
| id | name | muscles |
|---|---|---|
| bb_bench_press | Barbell Bench Press / 杠铃卧推 | chest, triceps, shoulders |
| bb_incline_press | Incline Barbell Press / 上斜杠铃卧推 | chest, shoulders, triceps |
| chest_press_machine | Machine Chest Press / 坐姿推胸机 | chest, triceps |
| dip_bar | Parallel Bar Dip / 双杠臂屈伸 | chest, triceps, shoulders |
| cable_fly_high | Cable Fly (High) / 龙门架飞鸟（高位） | chest |

## Back
| id | name | muscles |
|---|---|---|
| lat_pulldown | Lat Pulldown / 高位下拉 | back, biceps |
| bb_row | Barbell Bent-Over Row / 杠铃俯身划船 | back, biceps |
| seated_cable_row | Seated Cable Row / 坐姿绳索划船 | back, biceps |
| t_bar_row | T-Bar Row / T杠划船 | back, biceps |
| straight_arm_pulldown | Straight-Arm Pulldown / 直臂下拉 | back, triceps |

## Shoulders
| id | name | muscles |
|---|---|---|
| bb_overhead_press | Barbell Overhead Press / 杠铃肩上推举 | shoulders, triceps |
| bb_shrug | Barbell Shrug / 杠铃耸肩 | traps |
| reverse_fly_machine | Reverse Fly Machine / 反向飞鸟机 | shoulders, back |

## Legs
| id | name | muscles |
|---|---|---|
| bb_squat | Barbell Back Squat / 杠铃深蹲 | legs, glutes, core |
| bb_deadlift | Barbell Deadlift / 杠铃硬拉 | legs, glutes, lower_back, core |
| leg_press | Leg Press / 腿举机 | legs, glutes |
| leg_curl | Leg Curl Machine / 腿弯举机 | legs |
| leg_extension | Leg Extension Machine / 腿伸展机 | legs |
| calf_raise_machine | Calf Raise Machine / 提踵机 | calves |

## Arms
| id | name | muscles |
|---|---|---|
| bb_curl | Barbell Curl / 杠铃弯举 | biceps |
| rope_pushdown | Rope Triceps Pushdown / 绳索臂屈伸下压 | triceps |
| overhead_rope_ext | Overhead Rope Extension / 颈后绳索臂屈伸 | triceps |

## Core
| id | name | muscles |
|---|---|---|
| hanging_leg_raise | Hanging Leg Raise / 悬垂举腿 | core |
| ab_machine | Ab Crunch Machine / 卷腹机 | core |


## Rule for writing copy
- Tier these exercises honestly: only include machines you know how to do
  correctly. An exercise you write wrong does harm.
- Every new entry gets the same four fields (cue, mistake, progression,
  regression) with bilingual copy, same tone as the existing 40.
- The plan editor picker will show them automatically once they are added to
  `exercisesSeed`.
