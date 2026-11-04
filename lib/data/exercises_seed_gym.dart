import '../models.dart';

/// Gym exercises: barbell, machine, cable. These require gym access
/// (`requiredEquipment()` maps every non-bodyweight/dumbbell category to
/// 'gym'). Written mainstream-first: the barbell compounds are the spine of
/// the gym track.

const List<Exercise> gymSeed = [
  // ---------------------------------------------------------------- barbell
  Exercise(
    id: 'bb_squat',
    nameEn: 'Barbell Back Squat',
    nameZh: '杠铃深蹲',
    category: 'barbell',
    muscles: ['quads', 'glutes', 'core'],
    difficulty: 2,
    contraindications: ['knee'],
    descEn:
        'The king of lower-body lifts. Start with the empty bar and add weight only when every rep stays clean.',
    descZh: '下肢训练之王。从空杆开始，只有每一下都标准才加重。',
    cuesEn: [
      'Brace hard, sit between the heels, hips and chest rise together.',
      'Bar stays over mid-foot the whole way down.'
    ],
    cuesZh: ['核心锁紧，往脚跟之间坐下，髋和胸一起起来。', '杠铃全程压在脚掌中点正上方。'],
    mistakesEn: [
      'Knees caving inward under load.',
      'Heels lifting or the bar drifting forward.'
    ],
    mistakesZh: ['负重下膝盖内扣。', '脚跟离地或杠铃前移。'],
    progEn: 'Add 2.5kg per session while all reps stay clean.',
    progZh: '每次加重 2.5kg，只要动作全程标准。',
    regEn: 'Squat to a box, or switch to goblet squats to learn the pattern.',
    regZh: '蹲到箱子上，或先练高脚杯深蹲掌握模式。',
    defSets: 3,
    defReps: '5-8',
    defRest: 180,
  ),
  Exercise(
    id: 'bb_bench_press',
    nameEn: 'Barbell Bench Press',
    nameZh: '杠铃卧推',
    category: 'barbell',
    muscles: ['chest', 'triceps', 'shoulders'],
    difficulty: 2,
    contraindications: ['shoulder'],
    descEn:
        'The main horizontal press. Shoulder blades pinned, bar to mid-chest, press slightly back.',
    descZh: '水平推的主项。肩胛骨锁死，杠落在胸口中部，略微向后推起。',
    cuesEn: [
      'Pin the shoulder blades back and down, feet planted.',
      'Bar touches mid-chest, elbows about 45 degrees from torso.'
    ],
    cuesZh: ['肩胛骨后收下沉压在凳上，双脚踩实。', '杠落在胸口中部，手肘与躯干约 45 度。'],
    mistakesEn: [
      'Bouncing the bar off the chest.',
      'Flaring elbows to 90 degrees and grinding the shoulders.'
    ],
    mistakesZh: ['杠铃砸胸口借弹力。', '手肘外展 90 度，肩关节受挤压。'],
    progEn: 'Add 2.5kg when every rep is clean; use a spotter or safeties.',
    progZh: '动作全程标准后加重 2.5kg；务必有保护或安全销。',
    regEn: 'Switch to dumbbell bench or push-ups.',
    regZh: '换成哑铃卧推或俯卧撑。',
    defSets: 3,
    defReps: '5-8',
    defRest: 180,
  ),
  Exercise(
    id: 'bb_overhead_press',
    nameEn: 'Barbell Overhead Press',
    nameZh: '杠铃肩上推举',
    category: 'barbell',
    muscles: ['shoulders', 'triceps'],
    difficulty: 2,
    contraindications: ['shoulder'],
    descEn:
        'Standing barbell press. The strictest test of upper-body pressing strength.',
    descZh: '站姿杠铃推举。上肢推力量最严格的试金石。',
    cuesEn: [
      'Squeeze glutes and brace — no lean-back.',
      'Press up and slightly back, finishing with the bar over the ears.'
    ],
    cuesZh: ['收紧臀部绷住核心——不许后仰。', '向上并略微向后推，顶端杠铃停在耳朵正上方。'],
    mistakesEn: [
      'Turning it into an incline press by arching the back.',
      'Flaring the elbows out wide.'
    ],
    mistakesZh: ['塌腰变成上斜推。', '手肘完全外展。'],
    progEn: 'Add 2.5kg when all sets hit the top of the range.',
    progZh: '所有组到区间上限后加重 2.5kg。',
    regEn: 'Use dumbbells, seated with back support.',
    regZh: '改用哑铃，坐姿靠背完成。',
    defSets: 3,
    defReps: '5-8',
    defRest: 180,
  ),
  Exercise(
    id: 'bb_deadlift',
    nameEn: 'Barbell Deadlift',
    nameZh: '杠铃硬拉',
    category: 'barbell',
    muscles: ['hamstrings', 'glutes', 'lower_back', 'back'],
    difficulty: 2,
    contraindications: ['lower_back'],
    descEn:
        'The hip hinge under load — nothing trains the whole posterior chain like it. Keep it a hinge, never a squat.',
    descZh: '负重屈髋——整个后链没有动作能替代它。始终是髋铰链，不是深蹲。',
    cuesEn: [
      'Bar over mid-foot, shins almost touching, pull the slack out first.',
      'Hips back, flat back, stand tall by driving the floor away.'
    ],
    cuesZh: ['杠贴脚掌中点，胫骨几乎贴杠，先拉出杠的松弛。', '臀部后推、背部放平，蹬地把身体带直。'],
    mistakesEn: [
      'Yanking the bar with a rounded lower back.',
      'Squatting the pull and shooting the hips early.'
    ],
    mistakesZh: ['弓着下背猛拽。', '把硬拉做成蹲拉， hips 先起飞。'],
    progEn: 'Add 2.5-5kg while the back stays flat every rep.',
    progZh: '只要每一把背部都平，就加重 2.5-5kg。',
    regEn: 'Switch to Romanian deadlifts or glute bridges to learn the hinge.',
    regZh: '改练罗马尼亚硬拉或臀桥学习屈髋模式。',
    defSets: 1,
    defReps: '5',
    defRest: 180,
  ),
  Exercise(
    id: 'bb_row',
    nameEn: 'Barbell Bent-Over Row',
    nameZh: '杠铃俯身划船',
    category: 'barbell',
    muscles: ['back', 'biceps', 'lower_back'],
    difficulty: 2,
    contraindications: ['lower_back'],
    descEn:
        'The barbell row builds back thickness. Hinge to 45 degrees and hold it there for every rep.',
    descZh: '杠铃划船练背部厚度。俯身 45 度，全程保持这个角度。',
    cuesEn: [
      'Hinge and hold; the torso does not rise with the bar.',
      'Row to the lower ribs, elbows brush the sides.'
    ],
    cuesZh: ['俯身固定；躯干不随杠铃上抬。', '拉到下肋位置，手肘擦身侧走。'],
    mistakesEn: [
      'Using hips to cheat each rep.',
      'Bouncing the torso up as fatigue builds.'
    ],
    mistakesZh: ['靠甩髋借力。', '疲劳后躯干越翘越高。'],
    progEn: 'Add 2.5kg when all reps pause at the top.',
    progZh: '所有次都能顶端停顿后加重 2.5kg。',
    regEn: 'Switch to one-arm dumbbell rows with bench support.',
    regZh: '换成有支撑的单臂哑铃划船。',
    defSets: 3,
    defReps: '6-10',
    defRest: 150,
  ),
  Exercise(
    id: 'bb_curl',
    nameEn: 'Barbell Curl',
    nameZh: '杠铃弯举',
    category: 'barbell',
    muscles: ['biceps'],
    difficulty: 1,
    descEn: 'Straight-bar curl. Elbows pinned, strict reps.',
    descZh: '直杆弯举。手肘锁死，动作严格。',
    cuesEn: [
      'Elbows stay by the ribs; only the forearms move.',
      'Squeeze hard at the top, lower in control.'
    ],
    cuesZh: ['手肘贴肋，只有小臂在动。', '顶端用力收紧，缓慢下放。'],
    mistakesEn: [
      'Swinging the hips to start each rep.',
      'Cutting the bottom half of the range.'
    ],
    mistakesZh: ['靠晃髋带起杠铃。', '只做行程上半段。'],
    progEn: 'Add 2.5kg once form stays strict for all sets.',
    progZh: '全程严格后加重 2.5kg。',
    regEn: 'Use an EZ bar or dumbbells.',
    regZh: '换曲杆或哑铃。',
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'bb_shrug',
    nameEn: 'Barbell Shrug',
    nameZh: '杠铃耸肩',
    category: 'barbell',
    muscles: ['traps'],
    difficulty: 1,
    descEn: 'Straight-up shrug with a barbell. Simple and easy to load heavy.',
    descZh: '杠铃垂直耸肩，简单好上重量。',
    cuesEn: [
      'Shrug straight up toward the ears, hold 1s.',
      'Arms stay long, no elbow bending.'
    ],
    cuesZh: ['垂直向耳朵方向耸起，顶端停 1 秒。', '手臂伸长，不要弯肘。'],
    mistakesEn: [
      'Rolling the shoulders in circles.',
      'Turning it into an upright row.'
    ],
    mistakesZh: ['肩部画圆滚动。', '弯肘变成直立划船。'],
    progEn: 'Heavier weight with a full 1s top hold.',
    progZh: '顶端停满 1 秒的前提下加重。',
    regEn: 'Use dumbbells at the sides.',
    regZh: '改用哑铃自然下垂完成。',
    defSets: 4,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'bb_incline_press',
    nameEn: 'Incline Barbell Press',
    nameZh: '上斜杠铃卧推',
    category: 'barbell',
    muscles: ['chest', 'shoulders', 'triceps'],
    difficulty: 2,
    descEn:
        'Bench press on a 30-degree incline for the upper chest. Use a rack with safeties or a spotter.',
    descZh: '在 30 度上斜凳上卧推，重点练上胸。请在带保护杆的架子里做，或有人保护。',
    cuesEn: [
      'Shoulder blades back and down, feet planted.',
      'Touch the bar to the upper chest, just below the collarbones.'
    ],
    cuesZh: ['肩胛后收下沉，双脚踩实。', '杠铃触碰上胸，锁骨略下方。'],
    mistakesEn: [
      'Bouncing the bar off the chest.',
      'Hips lifting off the bench.'
    ],
    mistakesZh: ['杠铃在胸口弹起借力。', '臀部离开凳面。'],
    progEn: 'Add 2.5 kg when all sets hit the top of the rep range.',
    progZh: '所有组都达到次数上限时加 2.5 kg。',
    regEn: 'Incline dumbbell press.',
    regZh: '上斜哑铃卧推。',
    contraindications: ['shoulder'],
    defSets: 3,
    defReps: '6-10',
    defRest: 150,
  ),
  Exercise(
    id: 'bb_hip_thrust',
    nameEn: 'Barbell Hip Thrust',
    nameZh: '杠铃臀推',
    category: 'barbell',
    muscles: ['glutes', 'hamstrings'],
    difficulty: 2,
    descEn:
        'Upper back on a bench, padded bar across the hips. Lets the glutes handle far more load than bridges allow.',
    descZh: '上背靠凳，杠铃加护垫横在髋部。让臀部承受远超臀桥的重量。',
    cuesEn: [
      'Chin tucked, ribs down; finish with hips level, not over-arched.',
      'Shins vertical at the top; drive through the heels.'
    ],
    cuesZh: ['收下巴、肋骨下沉；顶端髋部水平，不过度挺腰。', '顶端小腿垂直，脚跟发力。'],
    mistakesEn: [
      'Hyper-extending the lower back at the top.',
      'Bar rolling toward the stomach.'
    ],
    mistakesZh: ['顶端过度挺腰。', '杠铃往腹部滚。'],
    progEn: 'Add load steadily; pause 1-2 seconds at the top.',
    progZh: '稳步加重；顶端停 1-2 秒。',
    regEn: 'Dumbbell hip thrust or glute bridge.',
    regZh: '哑铃臀推或臀桥。',
    defSets: 3,
    defReps: '8-12',
    defRest: 120,
  ),
  Exercise(
    id: 'close_grip_bench',
    nameEn: 'Close-Grip Bench Press',
    nameZh: '窄距卧推',
    category: 'barbell',
    muscles: ['triceps', 'chest'],
    difficulty: 2,
    descEn:
        'Bench press with hands about shoulder-width. The heaviest way to load the triceps. Use safeties or a spotter.',
    descZh: '双手约与肩同宽的卧推。给三头肌上最大重量的方式。请使用保护杆或有人保护。',
    cuesEn: [
      'Hands shoulder-width — not touching.',
      'Elbows tucked close to the ribs; touch the lower chest.'
    ],
    cuesZh: ['握距与肩同宽——不要两手相碰。', '手肘贴近肋骨，杠铃触及下胸。'],
    mistakesEn: [
      'Grip so narrow the wrists bend.',
      'Flaring the elbows like a regular bench.'
    ],
    mistakesZh: ['握距太窄导致手腕弯折。', '像普通卧推一样外展手肘。'],
    progEn: 'Add 2.5 kg once all sets hit the top of the range.',
    progZh: '所有组都达到次数上限时加 2.5 kg。',
    regEn: 'Diamond push-ups or rope pushdowns.',
    regZh: '钻石俯卧撑或绳索下压。',
    contraindications: ['shoulder'],
    defSets: 3,
    defReps: '6-10',
    defRest: 120,
  ),
  // ---------------------------------------------------------------- machine
  Exercise(
    id: 'chest_press_machine',
    nameEn: 'Machine Chest Press',
    nameZh: '坐姿推胸机',
    category: 'machine',
    muscles: ['chest', 'triceps'],
    difficulty: 1,
    descEn: 'Guided pressing path — a safe way to push hard without a spotter.',
    descZh: '固定轨迹推举——没有保护也能放心上强度的安全选择。',
    cuesEn: [
      'Set the seat so handles line up with mid-chest.',
      'Push to full lockout without slamming the stack.'
    ],
    cuesZh: ['调座椅让把手与胸口中部对齐。', '推到完全锁定，别砸配重片。'],
    mistakesEn: [
      'Butt lifting off the seat.',
      'Half reps that never reach lockout.'
    ],
    mistakesZh: ['屁股离开座垫。', '半程不锁定。'],
    progEn: 'Move the pin up one plate when all reps are clean.',
    progZh: '所有次都标准就加一片。',
    regEn: 'Lighter pin, slower tempo.',
    regZh: '减轻配重放慢节奏。',
    defSets: 3,
    defReps: '8-12',
    defRest: 120,
  ),
  Exercise(
    id: 'lat_pulldown',
    nameEn: 'Lat Pulldown',
    nameZh: '高位下拉',
    category: 'machine',
    muscles: ['back', 'biceps'],
    difficulty: 1,
    descEn:
        'The pull-up machine in reverse. Perfect for building vertical pulling before you can do pull-ups.',
    descZh: '引体向上的最佳前置动作——还做不了引体时，用它把垂直拉建立起来。',
    cuesEn: [
      'Chest tall, pull the bar to the collarbone, elbows down.',
      'Control the way up; the stretch at the top matters.'
    ],
    cuesZh: ['挺胸，把杠拉到锁骨位置，手肘向下。', '回放要有控制，顶端拉伸很重要。'],
    mistakesEn: [
      'Leaning way back and rowing to the belly.',
      'Letting the stack yank the arms up.'
    ],
    mistakesZh: ['过度后仰把杠拉到腹部。', '回放时被配重扯着走。'],
    progEn: 'Add weight; graduate to real pull-ups when strong enough.',
    progZh: '逐步加重；够强了就换成真引体向上。',
    regEn: 'Lighter weight, strict torso angle.',
    regZh: '减轻重量保持躯干角度。',
    defSets: 3,
    defReps: '8-12',
    defRest: 120,
  ),
  Exercise(
    id: 'seated_cable_row',
    nameEn: 'Seated Cable Row',
    nameZh: '坐姿绳索划船',
    category: 'machine',
    muscles: ['back', 'biceps'],
    difficulty: 1,
    descEn:
        'Constant-tension horizontal pull. Great for controlled back volume.',
    descZh: '持续张力的水平拉，堆背部容量的利器。',
    cuesEn: [
      'Sit tall, pull to the belt, squeeze the blades 1s.',
      'Let the shoulders travel forward slightly on the return — then pull.'
    ],
    cuesZh: ['坐直，拉到腹部位置，肩胛骨收紧 1 秒。', '回放时让肩胛随之前送，再拉回来。'],
    mistakesEn: [
      'Rocking the torso for momentum.',
      'Shrugging the shoulders into the ears.'
    ],
    mistakesZh: ['靠摇晃躯干借力。', '肩耸到耳朵上。'],
    progEn: 'Add a plate when every rep has a 1s squeeze.',
    progZh: '每次都能顶端停 1 秒就加配重。',
    regEn: 'Lighter weight, zero torso swing.',
    regZh: '减轻重量，躯干零晃动。',
    defSets: 3,
    defReps: '10-12',
    defRest: 120,
  ),
  Exercise(
    id: 'leg_press',
    nameEn: 'Leg Press',
    nameZh: '腿举机',
    category: 'machine',
    muscles: ['quads', 'glutes'],
    difficulty: 1,
    contraindications: ['knee'],
    descEn:
        'Heavy squats minus the balance demand. Great for hard leg work with zero spine load.',
    descZh: '深蹲的重量、没有平衡要求、零脊柱负荷——堆腿容量的主力。',
    cuesEn: [
      'Feet mid-platform, lower until thighs hit the torso — no butt lift.',
      'Press through the whole foot; never lock the knees hard.'
    ],
    cuesZh: ['脚在踏板中部，下放到大腿贴躯干——臀部不离开。', '全脚掌发力；不要狠狠锁死膝盖。'],
    mistakesEn: [
      'Butt curling off the seat at depth.',
      'Slamming into full lockout under load.'
    ],
    mistakesZh: ['下到底臀部卷离座垫。', '负重下猛然锁死膝盖。'],
    progEn: 'Add a plate per side when depth stays full.',
    progZh: '幅度不缩水就每侧加一片。',
    regEn: 'Higher foot position and shallower depth.',
    regZh: '脚位调高、幅度减小。',
    defSets: 3,
    defReps: '10-12',
    defRest: 150,
  ),
  Exercise(
    id: 'leg_curl',
    nameEn: 'Leg Curl Machine',
    nameZh: '腿弯举机',
    category: 'machine',
    muscles: ['hamstrings'],
    difficulty: 1,
    descEn: 'Hamstring isolation. Do it — nobody curls enough by accident.',
    descZh: '腘绳肌孤立动作。主动安排它，没人会"顺便"练到腘绳肌。',
    cuesEn: [
      'Hips stay glued to the pad, curl to full contraction.',
      'Lower in 3 seconds; do not let the stack drop.'
    ],
    cuesZh: ['髋部压紧垫子，卷到完全收缩。', '3 秒回放，不许配重块砸底。'],
    mistakesEn: ['Hips popping up every rep.', 'Fast half-range swings.'],
    mistakesZh: ['每次髋都弹起来。', '快速半程甩动。'],
    progEn: 'Add weight once all reps are 3s-down strict.',
    progZh: '全程 3 秒下放严格后加重。',
    regEn: 'Lighter pin, full range.',
    regZh: '减轻配重做全程。',
    defSets: 3,
    defReps: '10-12',
    defRest: 90,
  ),
  Exercise(
    id: 'leg_extension',
    nameEn: 'Leg Extension Machine',
    nameZh: '腿伸展机',
    category: 'machine',
    muscles: ['quads'],
    difficulty: 1,
    contraindications: ['knee'],
    descEn:
        'Quad isolation. High control, light weight — the quad squeeze is the point.',
    descZh: '股四头肌孤立。轻重量高控制——四头收紧的感觉才是重点。',
    cuesEn: [
      'Extend fully, squeeze 1s at the top.',
      'Lower slowly; never swing the weight up.'
    ],
    cuesZh: ['完全伸直，顶端收紧 1 秒。', '缓慢下放，不许甩起。'],
    mistakesEn: [
      'Kicking the weight with momentum.',
      'Buttocks lifting off the seat.'
    ],
    mistakesZh: ['借惯性踢腿。', '臀部离座。'],
    progEn: 'Add weight only when the top squeeze is honest.',
    progZh: '顶端收紧到位才许加重。',
    regEn: 'Reduce range to the pain-free zone if knees complain.',
    regZh: '膝盖不适就缩短到无痛范围。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'calf_raise_machine',
    nameEn: 'Calf Raise Machine',
    nameZh: '提踵机',
    category: 'machine',
    muscles: ['calves'],
    difficulty: 1,
    descEn:
        'Loaded calf raise with a full stretch at the bottom — the part everyone skips.',
    descZh: '负重提踵，底部充分拉伸——人人都跳过的那一半行程。',
    cuesEn: [
      'Full stretch at the bottom, 1s squeeze at the top.',
      'Straight knees, no bouncing.'
    ],
    cuesZh: ['底部完全拉伸，顶端收紧 1 秒。', '膝盖伸直，不许弹跳。'],
    mistakesEn: [
      'Tiny bounce reps with zero range.',
      'Bending the knees to cheat.'
    ],
    mistakesZh: ['幅度极小的弹动。', '弯膝借力。'],
    progEn: 'Add weight when every rep is full-range.',
    progZh: '全程完整才加重。',
    regEn: 'Bodyweight raises on a step.',
    regZh: '台阶上自重提踵。',
    defSets: 4,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'pec_deck',
    nameEn: 'Pec Deck Fly',
    nameZh: '蝴蝶机夹胸',
    category: 'machine',
    muscles: ['chest'],
    difficulty: 1,
    descEn:
        'Machine fly: the path is fixed, so you can focus purely on squeezing the chest.',
    descZh: '器械飞鸟：轨迹固定，可以专心夹紧胸肌。',
    cuesEn: [
      'Seat height so handles sit at mid-chest.',
      'Bring the hands together, squeeze, open slowly.'
    ],
    cuesZh: ['调座椅让把手在胸部中段高度。', '双手合拢、夹紧，再缓慢打开。'],
    mistakesEn: [
      'Opening so far the shoulders feel stretched hard.',
      'Shoulders rolling forward at the squeeze.'
    ],
    mistakesZh: ['打开过度，肩膀感到强烈拉扯。', '夹胸时肩膀向前扣。'],
    progEn: 'More weight, or a 2-second squeeze.',
    progZh: '加重，或夹紧停 2 秒。',
    regEn: 'Lighter stack, shorter range.',
    regZh: '减轻重量、缩小幅度。',
    contraindications: ['shoulder'],
    defSets: 3,
    defReps: '10-15',
    defRest: 60,
  ),
  Exercise(
    id: 'machine_shoulder_press',
    nameEn: 'Machine Shoulder Press',
    nameZh: '坐姿推肩机',
    category: 'machine',
    muscles: ['shoulders', 'triceps'],
    difficulty: 1,
    descEn:
        'Guided overhead press. A safe way to load the shoulders before free-weight pressing.',
    descZh: '有轨迹引导的推举。在自由重量推举之前安全地给肩部加负荷。',
    cuesEn: [
      'Back flat on the pad, handles at about chin height to start.',
      'Press up without locking hard; lower under control.'
    ],
    cuesZh: ['背部贴紧靠垫，起始把手约在下巴高度。', '向上推但不要用力锁死，控制下放。'],
    mistakesEn: [
      'Arching off the pad to push heavier.',
      'Letting the stack slam between reps.'
    ],
    mistakesZh: ['挺腰离开靠垫去推更重。', '配重片在次与次之间砸下。'],
    progEn: 'Add weight once all sets reach the top of the range.',
    progZh: '所有组都到次数上限时加重。',
    regEn: 'Lighter stack, or lateral raises.',
    regZh: '减轻重量，或做侧平举。',
    contraindications: ['shoulder'],
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'hack_squat',
    nameEn: 'Hack Squat',
    nameZh: '哈克深蹲',
    category: 'machine',
    muscles: ['quads', 'glutes'],
    difficulty: 2,
    descEn:
        'Machine squat with your back on a sled. Heavy quad work with no balance or bar position to worry about.',
    descZh: '背靠滑板的器械深蹲。大重量练股四头肌，不用操心平衡和杠铃位置。',
    cuesEn: [
      'Feet shoulder-width, mid-platform; knees track over toes.',
      'Lower until thighs are at least parallel, then drive up.'
    ],
    cuesZh: ['双脚与肩同宽放在踏板中部，膝盖对准脚尖。', '下蹲到大腿至少水平，再发力推起。'],
    mistakesEn: [
      'Heels lifting off the platform.',
      'Locking the knees hard at the top.'
    ],
    mistakesZh: ['脚跟离开踏板。', '顶端膝盖用力锁死。'],
    progEn: 'Add weight, or pause at the bottom.',
    progZh: '加重，或在底部停顿。',
    regEn: 'Leg press or goblet squat.',
    regZh: '腿举机或高脚杯深蹲。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '8-12',
    defRest: 120,
  ),
  Exercise(
    id: 'reverse_fly_machine',
    nameEn: 'Reverse Fly Machine',
    nameZh: '反向飞鸟机',
    category: 'machine',
    muscles: ['shoulders', 'back'],
    difficulty: 1,
    descEn:
        'Sit facing the pec deck and open the arms backward. Rear delts and upper back, perfect for posture.',
    descZh: '面朝蝴蝶机坐，双臂向后打开。练三角肌后束和上背，改善体态。',
    cuesEn: [
      'Chest against the pad, arms nearly straight.',
      'Sweep back to shoulder level, pause, return slowly.'
    ],
    cuesZh: ['胸口贴紧靠垫，手臂接近伸直。', '向后打开到与肩平齐，停顿，缓慢回位。'],
    mistakesEn: [
      'Shrugging the shoulders up.',
      'Jerking the handles with momentum.'
    ],
    mistakesZh: ['耸肩。', '用惯性猛拉把手。'],
    progEn: 'More weight or a longer pause.',
    progZh: '加重或延长停顿。',
    regEn: 'Bent-over dumbbell reverse fly with light weight.',
    regZh: '轻重量的俯身哑铃反向飞鸟。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'back_extension',
    nameEn: 'Back Extension',
    nameZh: '山羊挺身',
    category: 'machine',
    muscles: ['lower_back', 'glutes', 'hamstrings'],
    difficulty: 1,
    descEn:
        'On a 45-degree hyperextension bench, hinge down and rise back to a straight line. Builds the lower back and glutes.',
    descZh: '在 45 度罗马椅上屈髋下放，再起身成一条直线。练下背和臀部。',
    cuesEn: [
      'Pad just below the hip bones so you can hinge freely.',
      'Rise to a straight body line — no further.'
    ],
    cuesZh: ['靠垫放在髋骨略下方，方便屈髋。', '起到身体成一条直线即可，不要再往后。'],
    mistakesEn: [
      'Swinging up and over-arching at the top.',
      'Pad too high, blocking the hinge.'
    ],
    mistakesZh: ['甩上来并在顶端过度后仰。', '靠垫太高，挡住了屈髋。'],
    progEn: 'Hold a plate at the chest, or pause at the top.',
    progZh: '胸前抱杠铃片，或顶端停顿。',
    regEn: 'Bird dogs or supermans on the floor.',
    regZh: '地面鸟狗式或俯卧背伸展。',
    contraindications: ['lower_back'],
    defSets: 3,
    defReps: '10-15',
    defRest: 60,
  ),
  Exercise(
    id: 'hip_abduction',
    nameEn: 'Hip Abduction Machine',
    nameZh: '髋外展机',
    category: 'machine',
    muscles: ['abductors', 'glutes'],
    difficulty: 1,
    descEn:
        'Seated, push the pads apart with your knees. Targets the side glutes that stabilise the knee and pelvis.',
    descZh: '坐姿，用膝盖把垫子向外推开。练臀部外侧，稳定膝盖和骨盆。',
    cuesEn: [
      'Sit tall or lean slightly forward for more glute.',
      'Push out, pause, return slowly without letting the stack touch.'
    ],
    cuesZh: ['坐直，或略微前倾以更多练到臀部。', '向外推、停顿，缓慢回位，配重片不要落下。'],
    mistakesEn: [
      'Bouncing the pads with momentum.',
      'Using a tiny range of motion.'
    ],
    mistakesZh: ['靠惯性弹动垫子。', '幅度太小。'],
    progEn: 'More weight, or a 2-second hold at the widest point.',
    progZh: '加重，或在最大幅度处保持 2 秒。',
    regEn: 'Side-lying leg raises or donkey kicks.',
    regZh: '侧卧抬腿或跪姿后踢腿。',
    defSets: 3,
    defReps: '12-20',
    defRest: 60,
  ),
  // ------------------------------------------------------------------ cable
  Exercise(
    id: 'cable_fly_high',
    nameEn: 'Cable Fly',
    nameZh: '龙门架飞鸟',
    category: 'cable',
    muscles: ['chest'],
    difficulty: 1,
    contraindications: ['shoulder'],
    descEn: 'Chest isolation with constant tension. Lighter than you think.',
    descZh: '持续张力的胸部孤立。重量比你以为的要轻。',
    cuesEn: [
      'Fixed slight elbow bend, hug a big tree.',
      'Squeeze 1s where the hands meet, control the return.'
    ],
    cuesZh: ['肘弯固定，像抱一棵大树。', '双手并拢处收紧 1 秒，回放要控制。'],
    mistakesEn: [
      'Turning it into a press by bending elbows.',
      'Going heavy until shoulders pinch.'
    ],
    mistakesZh: ['肘部越弯越多变成推。', '重量大到肩前侧挤压。'],
    progEn: 'Add a plate once the 1s squeeze is clean.',
    progZh: '顶端停顿到位后加一片。',
    regEn: 'Lower the pulleys and reduce range.',
    regZh: '滑轮调低、幅度减小。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'rope_pushdown',
    nameEn: 'Rope Triceps Pushdown',
    nameZh: '绳索下压',
    category: 'cable',
    muscles: ['triceps'],
    difficulty: 1,
    descEn:
        'Triceps isolation. Elbows pinned to the ribs, rope split at the bottom.',
    descZh: '三头孤立动作。手肘贴肋，底部把绳撑开。',
    cuesEn: [
      'Only the forearms move; split the rope at full extension.',
      'Control the return to keep tension on.'
    ],
    cuesZh: ['只有小臂在动；完全伸直时把绳向外撑开。', '回放控制住，保持张力。'],
    mistakesEn: [
      'Leaning body weight onto the rope.',
      'Elbows drifting away from the ribs.'
    ],
    mistakesZh: ['把体重压在绳上。', '手肘离开肋骨飘起来。'],
    progEn: 'Add weight when every rep splits the rope.',
    progZh: '每次都能撑开绳子就加重。',
    regEn: 'Lighter weight, stricter elbows.',
    regZh: '减轻重量，手肘更贴身。',
    defSets: 3,
    defReps: '10-12',
    defRest: 60,
  ),
  Exercise(
    id: 'straight_arm_pulldown',
    nameEn: 'Straight-Arm Pulldown',
    nameZh: '直臂下拉',
    category: 'cable',
    muscles: ['back'],
    difficulty: 1,
    descEn:
        'Lat isolation without elbow flexion — teaches what "pulling with the lats" means.',
    descZh: '不用屈肘的背阔肌孤立——专门教会你什么叫"用背阔肌拉"。',
    cuesEn: [
      'Arms straight, sweep the bar down to the thighs.',
      'Think of pushing the bar back with the armpits, not the hands.'
    ],
    cuesZh: ['手臂伸直，把杠扫到腿侧。', '想象用腋窝把杠往后推，而不是用手。'],
    mistakesEn: [
      'Bending the elbows into a pushdown.',
      'Standing too far from the machine.'
    ],
    mistakesZh: ['屈肘变成了三头下压。', '站得离器械太远。'],
    progEn: 'Add weight once the armpit-sweep feel is solid.',
    progZh: '腋窝发力感觉稳定后加重。',
    regEn: 'Lighter weight, focus on the lat stretch.',
    regZh: '减轻重量专注背阔拉伸感。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'face_pull',
    nameEn: 'Face Pull',
    nameZh: '绳索面拉',
    category: 'cable',
    muscles: ['shoulders', 'back', 'traps'],
    difficulty: 1,
    descEn:
        'Rope at face height, pull it toward your eyes and spread the ends apart. The best shoulder-health exercise in the gym.',
    descZh: '绳索调到脸部高度，拉向眼睛并把两端分开。健身房里最好的肩部健康动作。',
    cuesEn: [
      'Thumbs point back, elbows high and wide.',
      'Finish with hands beside the ears, like a double-biceps pose.'
    ],
    cuesZh: ['拇指朝后，手肘抬高向外。', '结束时双手在耳侧，像双臂展示肱二头肌。'],
    mistakesEn: [
      'Going heavy and leaning back to row it.',
      'Elbows dropping so it becomes a row.'
    ],
    mistakesZh: ['重量太大，身体后仰去划。', '手肘下沉，变成了划船。'],
    progEn: 'Slow 2-second hold at the face.',
    progZh: '在脸前保持 2 秒。',
    regEn: 'Bent-over reverse fly with light dumbbells.',
    regZh: '轻哑铃俯身反向飞鸟。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'cable_lateral_raise',
    nameEn: 'Cable Lateral Raise',
    nameZh: '绳索侧平举',
    category: 'cable',
    muscles: ['shoulders'],
    difficulty: 1,
    descEn:
        'One-arm lateral raise from a low pulley. The cable keeps tension on the side delt even at the bottom.',
    descZh: '低位滑轮单臂侧平举。绳索让三角肌中束在底部也保持张力。',
    cuesEn: [
      'Stand side-on, cable crossing in front of the body.',
      'Lift to shoulder height, lead with the elbow.'
    ],
    cuesZh: ['侧身站立，绳索从身体前方交叉。', '抬到与肩同高，用手肘带动。'],
    mistakesEn: ['Leaning away and swinging.', 'Shrugging the shoulder up.'],
    mistakesZh: ['身体远离滑轮并摆动。', '耸肩。'],
    progEn: 'Slower lowering, or a lean-away version.',
    progZh: '放慢下放，或做身体外倾版本。',
    regEn: 'Light dumbbell lateral raises.',
    regZh: '轻哑铃侧平举。',
    contraindications: ['shoulder'],
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'overhead_rope_ext',
    nameEn: 'Overhead Rope Extension',
    nameZh: '绳索过头臂屈伸',
    category: 'cable',
    muscles: ['triceps'],
    difficulty: 1,
    descEn:
        'Face away from the pulley and extend the rope overhead. Stretches and trains the long head of the triceps.',
    descZh: '背对滑轮，把绳索向头顶上方伸直。拉伸并练到三头肌长头。',
    cuesEn: [
      'Staggered stance, lean slightly forward, elbows by the ears.',
      'Only the forearms move; spread the rope at the end.'
    ],
    cuesZh: ['前后脚站立，身体略前倾，手肘贴近耳侧。', '只有小臂在动，结束时分开绳索。'],
    mistakesEn: ['Elbows flaring wide.', 'Arching the lower back.'],
    mistakesZh: ['手肘向外散开。', '腰部反弓。'],
    progEn: 'More weight, slower stretch.',
    progZh: '加重，拉伸阶段放慢。',
    regEn: 'Rope pushdowns.',
    regZh: '绳索下压。',
    contraindications: ['shoulder'],
    defSets: 3,
    defReps: '10-15',
    defRest: 60,
  ),
  Exercise(
    id: 'cable_curl',
    nameEn: 'Cable Curl',
    nameZh: '绳索弯举',
    category: 'cable',
    muscles: ['biceps'],
    difficulty: 1,
    descEn:
        'Curl a straight bar or rope from a low pulley. Constant tension from bottom to top.',
    descZh: '在低位滑轮上用直杆或绳索弯举。从底到顶持续张力。',
    cuesEn: [
      'Elbows pinned at the sides.',
      'Squeeze at the top, lower until the arms are straight.'
    ],
    cuesZh: ['手肘固定在身体两侧。', '顶端收紧，下放到手臂伸直。'],
    mistakesEn: ['Rocking the torso to lift.', 'Elbows drifting forward.'],
    mistakesZh: ['晃动身体借力。', '手肘向前移。'],
    progEn: 'More weight or a slower lowering.',
    progZh: '加重或放慢下放。',
    regEn: 'Dumbbell curls with lighter weight.',
    regZh: '更轻的哑铃弯举。',
    defSets: 3,
    defReps: '10-12',
    defRest: 60,
  ),
  Exercise(
    id: 'pallof_press',
    nameEn: 'Pallof Press',
    nameZh: '帕洛夫推',
    category: 'cable',
    muscles: ['core'],
    difficulty: 1,
    descEn:
        'Stand side-on to a cable and press the handle straight out without letting it twist you. Anti-rotation core training.',
    descZh: '侧对绳索站立，把把手向前推直，不让它把身体拉转。抗旋转核心训练。',
    cuesEn: [
      'Feet shoulder-width, glutes and abs tight.',
      'Press out, hold 2 seconds, bring it back to the chest.'
    ],
    cuesZh: ['双脚与肩同宽，收紧臀部和腹部。', '向前推出，保持 2 秒，再收回胸前。'],
    mistakesEn: [
      'Letting the torso rotate toward the machine.',
      'Standing too close so there is no tension.'
    ],
    mistakesZh: ['躯干被拉向器械一侧转动。', '站得太近，没有张力。'],
    progEn: 'Step further away, or use a split stance.',
    progZh: '站得更远，或改为分腿站姿。',
    regEn: 'Lighter weight; kneeling version.',
    regZh: '减轻重量，或跪姿版本。',
    defSets: 3,
    defReps: '10-12',
    defRest: 45,
  ),
  // ------------------------------------------------------------- bodyweight+
  Exercise(
    id: 'dip_bar',
    nameEn: 'Parallel Bar Dip',
    nameZh: '双杠臂屈伸',
    category: 'bodyweight',
    muscles: ['chest', 'triceps', 'shoulders'],
    difficulty: 2,
    contraindications: ['shoulder'],
    descEn:
        'The upper-body squat. Needs parallel bars — a dipping station or sturdy rails.',
    descZh: '上肢的深蹲。需要双杠—— dips 架或结实的栏杆。',
    cuesEn: [
      'Slight forward lean for chest, upright for triceps.',
      'Descend until the upper arms are parallel to the floor, no deeper.'
    ],
    cuesZh: ['略前倾偏胸，直立偏三头。', '下放到大臂与地面平行即止，不要更深。'],
    mistakesEn: [
      'Dropping too deep and pinching the shoulders.',
      'Kipping with the legs.'
    ],
    mistakesZh: ['下放过深挤压肩部。', '蹬腿借力。'],
    progEn: 'Add reps, then hang weight from a belt or backpack.',
    progZh: '先加次数，再挂负重腰带或背包。',
    regEn: 'Bench dips or machine chest press.',
    regZh: '凳上臂屈伸或坐姿推胸机。',
    defSets: 3,
    defReps: '8-12',
    defRest: 120,
  ),
  Exercise(
    id: 'hanging_leg_raise',
    nameEn: 'Hanging Leg Raise',
    nameZh: '悬垂举腿',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 2,
    descEn:
        'The strongest core move in this library — needs a bar to hang from.',
    descZh: '库里最硬核的核心动作——需要一根能悬垂的单杠。',
    cuesEn: [
      'Hang with active shoulders, curl the pelvis up — do not just swing the legs.',
      'Lower slowly; zero swing between reps.'
    ],
    cuesZh: ['肩胛激活悬垂，靠卷骨盆把腿带上来——不是甩腿。', '缓慢下放，次与次之间零晃动。'],
    mistakesEn: [
      'Swinging momentum between reps.',
      'Arching the lower back at the bottom.'
    ],
    mistakesZh: ['靠摆动惯性凑次数。', '底部塌腰。'],
    progEn: 'Straight legs, then ankle weights.',
    progZh: '直腿，再上脚踝负重。',
    regEn: 'Lying leg raises or knee raises first.',
    regZh: '先做仰卧举腿或屈膝举腿。',
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),

  // ------------------------------------------------- legs & forearms (v0.4)
  Exercise(
    id: 'bb_front_squat',
    nameEn: 'Barbell Front Squat',
    nameZh: '杠铃前蹲',
    category: 'barbell',
    muscles: ['quads', 'core', 'glutes'],
    difficulty: 3,
    descEn:
        'Bar racked on the front of the shoulders, elbows high. Forces an upright torso, so the quads do more and the lower back less than a back squat.',
    descZh: '杠铃架在肩膀前侧，手肘抬高。迫使躯干直立，比后蹲更多股四头、更少下背负担。',
    cuesEn: [
      'Elbows up the whole way; the bar rests on the shoulders, not the hands.',
      'Sit straight down between the heels, knees forward.'
    ],
    cuesZh: ['手肘全程抬高，杠铃压在肩膀上而不是手上。', '垂直坐到脚跟之间，膝盖往前。'],
    mistakesEn: [
      'Elbows dropping and the bar rolling forward.',
      'Leaning forward out of the bottom.'
    ],
    mistakesZh: ['手肘下掉导致杠铃前滚。', '从底部起身时前倾。'],
    progEn: 'Add 2.5kg when every rep stays upright.',
    progZh: '每一下都保持直立后加重 2.5kg。',
    regEn: 'Goblet squat, or a cross-arm grip.',
    regZh: '高脚杯深蹲，或交叉手握法。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '5-8',
    defRest: 180,
  ),
  Exercise(
    id: 'bb_rdl',
    nameEn: 'Barbell Romanian Deadlift',
    nameZh: '杠铃罗马尼亚硬拉',
    category: 'barbell',
    muscles: ['hamstrings', 'glutes', 'lower_back'],
    difficulty: 2,
    descEn:
        'Hip hinge with the bar sliding down the thighs. The best heavy hamstring builder; the bar never touches the floor.',
    descZh: '杠铃贴着大腿下滑的髋屈伸。最好的大重量腘绳肌动作；杠铃不触地。',
    cuesEn: [
      'Push the hips back, soft knees, bar brushing the legs.',
      'Lower to just below the knee, then drive the hips through.'
    ],
    cuesZh: ['髋往后推、膝微屈，杠铃贴腿。', '降到膝盖下方一点，然后髋部向前顶。'],
    mistakesEn: [
      'Rounding the lower back.',
      'Bending the knees and squatting the weight.'
    ],
    mistakesZh: ['下背弯曲。', '屈膝变成深蹲。'],
    progEn: 'Add 2.5kg while the back stays flat on every rep.',
    progZh: '每一下背部都平直时加重 2.5kg。',
    regEn: 'Dumbbell RDL.',
    regZh: '哑铃罗马尼亚硬拉。',
    contraindications: ['lower_back'],
    defSets: 3,
    defReps: '6-10',
    defRest: 150,
  ),
  Exercise(
    id: 'bb_good_morning',
    nameEn: 'Barbell Good Morning',
    nameZh: '杠铃早安式',
    category: 'barbell',
    muscles: ['hamstrings', 'lower_back', 'glutes'],
    difficulty: 3,
    descEn:
        'Hinge forward with the bar on the upper back. Keep it light: the long lever makes every kilo count.',
    descZh: '杠铃扛在上背向前做髋屈伸。重量要轻：力臂很长，每公斤都算数。',
    cuesEn: [
      'Hips back, soft knees, back flat; stop when the hamstrings pull.',
      'Stand up by driving the hips forward, not by lifting the chest.'
    ],
    cuesZh: ['髋后推、膝微屈、背平直，腘绳肌绷紧时停住。', '靠髋向前顶起身，不是靠抬胸。'],
    mistakesEn: ['Going too deep with a rounded back.', 'Too much weight.'],
    mistakesZh: ['弓着背下得太深。', '重量过大。'],
    progEn: 'Small jumps only; add reps first.',
    progZh: '只小幅加重，先加次数。',
    regEn: 'Dumbbell good morning or RDL.',
    regZh: '哑铃早安式或罗马尼亚硬拉。',
    contraindications: ['lower_back'],
    defSets: 3,
    defReps: '8-10',
    defRest: 120,
  ),
  Exercise(
    id: 'bb_sumo_deadlift',
    nameEn: 'Barbell Sumo Deadlift',
    nameZh: '杠铃相扑硬拉',
    category: 'barbell',
    muscles: ['glutes', 'adductors', 'hamstrings', 'quads'],
    difficulty: 3,
    descEn:
        'Deadlift with a wide stance and the hands inside the knees. Upright torso, shorter pull, and a lot of inner thigh and glute.',
    descZh: '宽站距、双手在膝盖内侧的硬拉。躯干更直、行程更短，大腿内侧和臀部参与很多。',
    cuesEn: [
      'Knees out over the toes, shins vertical, chest up.',
      'Spread the floor and push the knees out as the bar leaves the ground.'
    ],
    cuesZh: ['膝盖推向脚尖方向，小腿垂直，胸口挺起。', '杠铃离地时双脚向外撑开地面、膝盖外推。'],
    mistakesEn: [
      'Hips shooting up first.',
      'Knees caving as the bar passes them.'
    ],
    mistakesZh: ['髋先飞起来。', '杠铃过膝时膝盖内扣。'],
    progEn: 'Add 2.5kg per session while the hips and chest rise together.',
    progZh: '髋和胸同步起来时每次加重 2.5kg。',
    regEn: 'Dumbbell sumo deadlift.',
    regZh: '哑铃相扑硬拉。',
    contraindications: ['lower_back'],
    defSets: 3,
    defReps: '3-6',
    defRest: 180,
  ),
  Exercise(
    id: 'bb_lunge',
    nameEn: 'Barbell Reverse Lunge',
    nameZh: '杠铃后撤弓步',
    category: 'barbell',
    muscles: ['quads', 'glutes'],
    difficulty: 3,
    descEn:
        'Reverse lunges with the bar on the back. Heavy single-leg work with the knee-friendly step direction.',
    descZh: '杠铃扛背的后撤弓步。用对膝盖友好的后撤方向做大重量单腿训练。',
    cuesEn: [
      'Step back far; the front shin stays vertical.',
      'Stay tall under the bar and drive through the front heel.'
    ],
    cuesZh: ['后撤要远，前小腿保持垂直。', '杠下保持挺直，前脚跟发力。'],
    mistakesEn: [
      'Torso pitching forward under the bar.',
      'Short steps that drive the front knee forward.'
    ],
    mistakesZh: ['杠下上身前倾。', '步幅太短，前膝冲前。'],
    progEn: 'Add 2.5kg when both legs match for reps.',
    progZh: '两腿次数相同后加重 2.5kg。',
    regEn: 'Dumbbell reverse lunge.',
    regZh: '哑铃后撤弓步。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '6-8',
    defRest: 120,
  ),
  Exercise(
    id: 'bb_wrist_curl',
    nameEn: 'Barbell Wrist Curl',
    nameZh: '杠铃腕弯举',
    category: 'barbell',
    muscles: ['forearms'],
    difficulty: 1,
    descEn:
        'Seated, forearms on the thighs, palms up, bar rolling to the fingertips and curling back. Both forearms at once with a stable load.',
    descZh: '坐姿，前臂放大腿上、掌心朝上，杠铃滚到指尖再弯起。双前臂同时训练，负荷稳定。',
    cuesEn: [
      'Forearms stay down; only the wrists move.',
      'Full stretch at the bottom, squeeze at the top.'
    ],
    cuesZh: ['前臂不动，只有手腕动。', '底部完全拉伸，顶端夹紧。'],
    mistakesEn: ['Elbows lifting.', 'Too heavy to reach the fingertips.'],
    mistakesZh: ['手肘抬起。', '太重导致杠铃滚不到指尖。'],
    progEn: 'Add reps to 20, then weight.',
    progZh: '先加到 20 次再加重。',
    regEn: 'Dumbbell wrist curl.',
    regZh: '哑铃腕弯举。',
    defSets: 3,
    defReps: '12-20',
    defRest: 45,
  ),
  Exercise(
    id: 'bb_reverse_curl',
    nameEn: 'Barbell Reverse Curl',
    nameZh: '杠铃反握弯举',
    category: 'barbell',
    muscles: ['forearms', 'biceps'],
    difficulty: 2,
    descEn:
        'Curl with an overhand grip. Thick forearms and a bulletproof grip; keep the weight honest.',
    descZh: '正握做弯举。粗壮的前臂和扎实的握力；重量要老实。',
    cuesEn: [
      'Elbows at the sides, wrists straight.',
      'Three seconds down on every rep.'
    ],
    cuesZh: ['手肘贴体侧，手腕伸直。', '每一下用 3 秒下放。'],
    mistakesEn: ['Wrists flexing up.', 'Swinging the bar with the hips.'],
    mistakesZh: ['手腕上勾。', '用髋把杠铃甩起来。'],
    progEn: 'Small plates only; add reps first.',
    progZh: '只加小片，先加次数。',
    regEn: 'Dumbbell reverse curl.',
    regZh: '哑铃反握弯举。',
    defSets: 3,
    defReps: '10-12',
    defRest: 60,
  ),
  // ---------------------------------------------------------------- machine
  Exercise(
    id: 'hip_adduction',
    nameEn: 'Hip Adduction Machine',
    nameZh: '内收肌机',
    category: 'machine',
    muscles: ['adductors'],
    difficulty: 1,
    descEn:
        'Seated, pads inside the knees; squeeze the legs together. Direct inner-thigh work that supports squats and protects the groin.',
    descZh: '坐姿，挡板在膝盖内侧，双腿向内夹。直接练大腿内侧，既帮助深蹲也保护腹股沟。',
    cuesEn: [
      'Set the start wide enough to feel a stretch, not pain.',
      'Squeeze together slowly, pause, and resist on the way out.'
    ],
    cuesZh: ['起始位开到有拉伸感但不疼。', '慢慢夹拢、停顿，向外打开时也要顶住阻力。'],
    mistakesEn: [
      'Slamming the pads together.',
      'Leaning forward or lifting the hips off the seat.'
    ],
    mistakesZh: ['挡板猛撞到一起。', '身体前倾或臀部离开座位。'],
    progEn: 'Add a plate when 15 reps are controlled.',
    progZh: '15 次都能控制后加一片。',
    regEn: 'Frog pumps or Copenhagen plank from the knee.',
    regZh: '蛙式臀桥或膝盖支撑的哥本哈根侧撑。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'seated_leg_curl',
    nameEn: 'Seated Leg Curl',
    nameZh: '坐姿腿弯举',
    category: 'machine',
    muscles: ['hamstrings'],
    difficulty: 1,
    descEn:
        'Seated, pad on the back of the ankles; curl the heels under the seat. The seated position stretches the hamstrings at the hip, which makes it grow them better than the lying version.',
    descZh: '坐姿，挡板在脚踝后方，把脚跟弯向座椅下方。坐姿让腘绳肌在髋部处于拉长状态，增肌效果好于俯卧版。',
    cuesEn: [
      'Thigh pad snug; back against the seat.',
      'Curl all the way, then take 3 s to return.'
    ],
    cuesZh: ['大腿挡板压紧，背靠座椅。', '弯到底，然后用 3 秒回放。'],
    mistakesEn: ['Hips lifting off the seat.', 'Half reps with a heavy stack.'],
    mistakesZh: ['臀部离开座位。', '大重量做半程。'],
    progEn: 'Add a plate when all reps reach full flexion.',
    progZh: '所有次数都能弯到底后加一片。',
    regEn: 'Sliding leg curls.',
    regZh: '滑行腿弯举。',
    defSets: 3,
    defReps: '10-12',
    defRest: 75,
  ),
  Exercise(
    id: 'seated_calf_raise_machine',
    nameEn: 'Seated Calf Raise Machine',
    nameZh: '坐姿提踵机',
    category: 'machine',
    muscles: ['calves'],
    difficulty: 1,
    descEn:
        'Pads on the knees, balls of the feet on the platform. With the knees bent the soleus does the work — the part of the calf standing raises miss.',
    descZh: '挡板压在膝盖上，前脚掌踩踏板。屈膝时由比目鱼肌发力——站姿提踵练不到的那部分小腿。',
    cuesEn: [
      'Heels all the way down, pause, then all the way up.',
      'Slow and steady; no bouncing.'
    ],
    cuesZh: ['脚跟完全下落、停顿，再完全踮起。', '慢而稳，不借弹力。'],
    mistakesEn: [
      'Short bounces at the top.',
      'Pad set too high, so the heels never stretch.'
    ],
    mistakesZh: ['顶端小幅弹跳。', '挡板太高，脚跟始终拉伸不到。'],
    progEn: 'Add weight when 15 slow reps are easy.',
    progZh: '15 次慢速动作轻松后加重。',
    regEn: 'Dumbbell seated calf raise.',
    regZh: '哑铃坐姿提踵。',
    defSets: 3,
    defReps: '12-15',
    defRest: 45,
  ),
  // ------------------------------------------------------------------ cable
  Exercise(
    id: 'cable_pull_through',
    nameEn: 'Cable Pull-Through',
    nameZh: '绳索髋屈伸',
    category: 'cable',
    muscles: ['glutes', 'hamstrings'],
    difficulty: 2,
    descEn:
        'Face away from a low pulley, rope between the legs, and hinge back and forth. The cable pulls the hips back for you, so the glutes have to drive them through.',
    descZh: '背对低位滑轮，绳索从两腿之间穿过，前后做髋屈伸。绳索把髋往后拉，臀部必须把它顶回去。',
    cuesEn: [
      'Step forward until the stack is lifted; hinge with soft knees.',
      'Snap the hips forward and squeeze the glutes at the top; arms stay straight.'
    ],
    cuesZh: ['向前走到配重离架，膝微屈做髋屈伸。', '髋部快速向前顶，顶端夹紧臀部，手臂全程伸直。'],
    mistakesEn: ['Pulling with the arms.', 'Leaning back at the top.'],
    mistakesZh: ['用手臂拉。', '顶端后仰。'],
    progEn: 'Add weight or a 2 s squeeze at the top.',
    progZh: '加重，或顶端夹紧 2 秒。',
    regEn: 'Glute bridge or dumbbell RDL.',
    regZh: '臀桥或哑铃罗马尼亚硬拉。',
    contraindications: ['lower_back'],
    defSets: 3,
    defReps: '10-15',
    defRest: 75,
  ),
  Exercise(
    id: 'cable_kickback',
    nameEn: 'Cable Glute Kickback',
    nameZh: '绳索后踢腿',
    category: 'cable',
    muscles: ['glutes'],
    difficulty: 1,
    descEn:
        'Ankle cuff on a low pulley; drive the leg straight back from the hip. Isolates the glute with the load exactly where it wants it.',
    descZh: '脚踝套在低位滑轮上，从髋部把腿向后直直蹬出。孤立刺激臀部，阻力方向刚刚好。',
    cuesEn: [
      'Hold the frame, lean slightly forward, squeeze the glute to move the leg.',
      'Stop when the hip is straight; do not arch the back for extra height.'
    ],
    cuesZh: ['扶住架子、略微前倾，用夹臀的力量带动腿。', '髋伸直就停，别为了踢更高而塌腰。'],
    mistakesEn: [
      'Swinging the leg with momentum.',
      'Arching the lower back at the top.'
    ],
    mistakesZh: ['靠惯性甩腿。', '顶端腰部反弓。'],
    progEn: 'Add weight only while the back stays still.',
    progZh: '只有背部能保持不动时才加重。',
    regEn: 'Donkey kicks.',
    regZh: '跪姿后踢腿。',
    defSets: 3,
    defReps: '12-15',
    defRest: 45,
  ),
  Exercise(
    id: 'cable_hip_adduction',
    nameEn: 'Cable Hip Adduction',
    nameZh: '绳索髋内收',
    category: 'cable',
    muscles: ['adductors'],
    difficulty: 1,
    descEn:
        'Ankle cuff on a low pulley, standing side-on; sweep the leg across the body against the cable. The standing version of the adductor machine, with balance work thrown in.',
    descZh: '脚踝套在低位滑轮上侧身站立，把腿横向拉过身体中线。站姿版的内收肌机，顺便练平衡。',
    cuesEn: [
      'Stand tall, hold the frame, leg straight.',
      'Pull the leg across slowly and let it return under control.'
    ],
    cuesZh: ['站直、扶架、腿伸直。', '慢慢把腿拉过中线，再有控制地回放。'],
    mistakesEn: ['Leaning away to swing the leg.', 'Bending the working knee.'],
    mistakesZh: ['身体歪向反侧借力甩腿。', '工作腿屈膝。'],
    progEn: 'Add weight or a pause at the midline.',
    progZh: '加重，或在中线处停顿。',
    regEn: 'Lighter weight, hand firmly on the frame.',
    regZh: '减重，手牢牢扶住架子。',
    defSets: 3,
    defReps: '12-15',
    defRest: 45,
  ),
  Exercise(
    id: 'reverse_hyper',
    nameEn: 'Reverse Hyperextension',
    nameZh: '反向背屈伸',
    category: 'machine',
    muscles: ['glutes', 'hamstrings', 'lower_back'],
    difficulty: 2,
    descEn:
        'Lie face down on a bench or machine with the hips at the edge and lift the straight legs to body height. Glutes and hamstrings with the spine unloaded.',
    descZh: '俯卧在凳子或器械上，髋部在边缘，把伸直的双腿抬到与身体齐平。脊柱不受压的臀和腘绳肌训练。',
    cuesEn: [
      'Squeeze the glutes to lift; stop at horizontal.',
      'Lower slowly — no swinging under the bench.'
    ],
    cuesZh: ['夹臀抬腿，到水平就停。', '慢慢放下——别在凳子下面荡。'],
    mistakesEn: ['Arching above horizontal.', 'Using momentum.'],
    mistakesZh: ['抬过水平线导致腰反弓。', '借惯性。'],
    progEn: 'Hold a light dumbbell between the feet.',
    progZh: '双脚之间夹一只轻哑铃。',
    regEn: 'Bird dog or superman.',
    regZh: '鸟狗式或超人式。',
    contraindications: ['lower_back'],
    defSets: 3,
    defReps: '10-15',
    defRest: 75,
  ),
];
