import '../models.dart';

// Bodyweight exercises. Images land in `assets/images/<id>.png`
// (AI-generated, style-locked); until then the UI shows an icon placeholder.

const List<Exercise> bodyweightSeed = [
  Exercise(
    id: 'pushup',
    nameEn: 'Push-Up',
    nameZh: '俯卧撑',
    category: 'bodyweight',
    muscles: ['chest', 'triceps', 'shoulders'],
    difficulty: 1,
    descEn:
        'The fundamental horizontal press. Build it to 20 clean reps before chasing harder variations.',
    descZh: '最基础的水平推类动作。先把它练到 20 次标准再考虑更难的变式。',
    cuesEn: [
      'Squeeze glutes and brace so body moves as one plank.',
      'Elbows about 45 degrees from torso, chest to the floor.'
    ],
    cuesZh: ['收紧臀部和核心，全身像一块板一样整体运动。', '手肘与躯干约 45 度，胸口朝地面下降。'],
    mistakesEn: [
      'Hips sagging or piking — core is not braced.',
      'Flaring elbows out to 90 degrees and shortening the range.'
    ],
    mistakesZh: ['塌腰或撅臀——核心没有收紧。', '手肘外展到 90 度，幅度偷工减料。'],
    progEn:
        'Elevate feet, add a pause at the bottom, or move to deficit push-ups.',
    progZh: '垫高双脚、在最低点停顿，或做下斜俯卧撑。',
    regEn: 'Do them on knees or with hands on a bench.',
    regZh: '改为跪姿俯卧撑，或双手撑在凳子上做上斜俯卧撑。',
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'knee_pushup',
    nameEn: 'Knee Push-Up',
    nameZh: '跪姿俯卧撑',
    category: 'bodyweight',
    muscles: ['chest', 'triceps'],
    difficulty: 1,
    descEn:
        'Reduced-load push-up. Keep a straight line from knees to head — the cutoff to full push-ups is 15 clean reps.',
    descZh: '减轻负荷的俯卧撑。膝盖到头顶保持一条直线——能标准做 15 次就该进阶到完整俯卧撑。',
    cuesEn: [
      'Same plank rules as the full push-up.',
      'Lower with control, do not drop.'
    ],
    cuesZh: ['遵循和标准俯卧撑一样的绷直规则。', '下降要有控制，不要往下砸。'],
    mistakesEn: [
      'Only the arms move while hips stay high.',
      'Rushing reps instead of full range.'
    ],
    mistakesZh: ['只有手臂在动，臀部始终高高翘着。', '贪快凑数，动作幅度不完整。'],
    progEn: 'Add reps, then switch to full push-ups.',
    progZh: '加次数，然后换成标准俯卧撑。',
    regEn: 'Do them with hands on a wall or bench.',
    regZh: '双手撑墙或撑凳子完成。',
    defSets: 3,
    defReps: '10-15',
    defRest: 90,
  ),
  Exercise(
    id: 'wide_pushup',
    nameEn: 'Wide-Grip Push-Up',
    nameZh: '宽距俯卧撑',
    category: 'bodyweight',
    muscles: ['chest', 'shoulders'],
    difficulty: 2,
    descEn:
        'Hands wider than shoulders shifts more load to the chest and stretches it harder at the bottom.',
    descZh: '双手比肩宽，更多负荷转移到胸部，最低点牵拉更明显。',
    cuesEn: [
      'Elbows track out wider, forearms stay vertical at the bottom.',
      'Control the descent, feel the chest stretch.'
    ],
    cuesZh: ['手肘更向外打开，最低点小臂保持垂直。', '控制下降速度，感受胸部拉伸。'],
    mistakesEn: [
      'Going so wide the shoulders pinch.',
      'Bouncing out of the bottom.'
    ],
    mistakesZh: ['手距过宽导致肩部有挤压感。', '在最低点借弹力反弹。'],
    progEn: 'Add a 2s pause at the bottom or elevate the feet.',
    progZh: '最低点停 2 秒，或垫高双脚。',
    regEn: 'Return to standard hand width.',
    regZh: '回到标准肩宽手距。',
    defSets: 3,
    defReps: '10-15',
    defRest: 90,
  ),
  Exercise(
    id: 'diamond_pushup',
    nameEn: 'Diamond Push-Up',
    nameZh: '钻石俯卧撑',
    category: 'bodyweight',
    muscles: ['triceps', 'chest'],
    difficulty: 2,
    descEn:
        'Hands together under the chest in a diamond. The strongest bodyweight triceps builder.',
    descZh: '双手在胸口下方合成菱形。自重动作里最强的三头肌训练之一。',
    cuesEn: [
      'Elbows stay close to the ribs as you descend.',
      'Forearms vertical, wrists stacked under shoulders.'
    ],
    cuesZh: ['下降时手肘贴着肋骨走。', '小臂保持垂直，手腕在肩膀正下方。'],
    mistakesEn: [
      'Elbows flaring out, turning it into a shoulder move.',
      'Half reps that never touch the chest.'
    ],
    mistakesZh: ['手肘外飘，变成肩部动作。', '只做半程，胸口从不接近地面。'],
    progEn: 'Elevate the feet or add a pause at the bottom.',
    progZh: '垫高双脚或在最低点停顿。',
    regEn: 'Do it from the knees first.',
    regZh: '先从跪姿版本开始。',
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'pike_pushup',
    nameEn: 'Pike Push-Up',
    nameZh: '倒V俯卧撑',
    category: 'bodyweight',
    contraindications: ['shoulder'],
    muscles: ['shoulders', 'triceps'],
    difficulty: 2,
    descEn:
        'Hips high, torso vertical — a vertical press with bodyweight. The road to handstand push-ups.',
    descZh: '臀部抬高、躯干接近垂直——用自重做推举。这是通往倒立撑的路。',
    cuesEn: [
      'Hips form an inverted V, head travels to the floor between the hands.',
      'Elbows track slightly back, not straight out.'
    ],
    cuesZh: ['臀部呈倒V形，头顶向两手之间的地面下降。', '手肘略微向后，不要完全外展。'],
    mistakesEn: [
      'Hips too low — it becomes a normal push-up.',
      'Craning the neck to touch first instead of the crown of the head.'
    ],
    mistakesZh: ['臀部太低，变成普通俯卧撑。', '伸脖子去够地面而不是头顶向下。'],
    progEn:
        'Elevate the feet on a chair, then move toward wall handstand push-ups.',
    progZh: '双脚垫高到椅子上，再逐步过渡到靠墙倒立撑。',
    regEn: 'Reduce the hip height and range.',
    regZh: '降低臀部高度和动作幅度。',
    defSets: 3,
    defReps: '6-10',
    defRest: 90,
  ),
  Exercise(
    id: 'squat_bw',
    nameEn: 'Bodyweight Squat',
    nameZh: '自重深蹲',
    category: 'bodyweight',
    muscles: ['quads', 'glutes'],
    difficulty: 1,
    descEn:
        'Baseline squat pattern. Own a full-depth, controlled bodyweight squat before adding load.',
    descZh: '基础的深蹲模式。先掌握全幅度、有控制的自重深蹲，再谈负重。',
    cuesEn: [
      'Sit between the heels, knees track over the toes.',
      'Chest up, heels stay glued to the floor.'
    ],
    cuesZh: ['往脚跟方向坐下，膝盖对准脚尖方向。', '挺胸，脚跟全程贴地。'],
    mistakesEn: [
      'Heels lifting or weight shifting to the toes.',
      'Knees collapsing inward.'
    ],
    mistakesZh: ['脚跟离地或重心跑到脚尖。', '膝盖向内扣。'],
    progEn: 'Slow the tempo (3s down), add a pause, or move to goblet squats.',
    progZh: '放慢节奏（3 秒下蹲）、加停顿，或进阶到高脚杯深蹲。',
    regEn: 'Squat to a chair and control the sit-down.',
    regZh: '坐到椅子上再站起，控制下坐过程。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'lunge_bw',
    nameEn: 'Bodyweight Lunge',
    nameZh: '徒手箭步蹲',
    category: 'bodyweight',
    contraindications: ['knee'],
    muscles: ['quads', 'glutes'],
    difficulty: 1,
    descEn:
        'Single-leg strength and balance in one move. Step forward, drop the back knee, drive back up.',
    descZh: '单腿力量与平衡一网打尽。向前迈步，后膝下沉，蹬地回来。',
    cuesEn: [
      'Front shin roughly vertical at the bottom.',
      'Torso tall, weight through the front mid-foot.'
    ],
    cuesZh: ['最低点前侧小腿基本垂直于地面。', '躯干挺直，重心压在前脚中部。'],
    mistakesEn: [
      'Front knee shooting far past the toes with the torso falling forward.',
      'Steps too short, forcing the knee forward.'
    ],
    mistakesZh: ['前膝远超脚尖、躯干前倾。', '步幅太小，膝盖被迫前顶。'],
    progEn: 'Hold dumbbells or add a deficit (rear foot on a book).',
    progZh: '手持哑铃，或垫高后脚增加幅度。',
    regEn: 'Hold a wall or chair for balance.',
    regZh: '扶墙或椅子保持平衡。',
    defSets: 3,
    defReps: '10-12',
    defRest: 60,
  ),
  Exercise(
    id: 'bulgarian_split_squat',
    nameEn: 'Bulgarian Split Squat',
    nameZh: '保加利亚分腿蹲',
    category: 'bodyweight',
    contraindications: ['knee'],
    muscles: ['quads', 'glutes'],
    difficulty: 2,
    descEn:
        'Rear foot elevated split squat. Brutal single-leg builder for quads and glutes.',
    descZh: '后脚垫高的分腿蹲。虐但高效的单腿股四头肌和臀部训练。',
    cuesEn: [
      'Rear foot on a chair, most weight on the front leg.',
      'Drop straight down, front shin near vertical.'
    ],
    cuesZh: ['后脚搭在椅子上，大部分重量压在前腿。', '垂直向下蹲，前侧小腿接近垂直。'],
    mistakesEn: [
      'Standing too close to the chair, knee crashing forward.',
      'Pushing off the rear toe instead of the front foot.'
    ],
    mistakesZh: ['离椅子太近，前膝猛往前顶。', '靠后脚尖蹬地借力，而不是前脚发力。'],
    progEn: 'Hold dumbbells at the sides or add a front-foot deficit.',
    progZh: '双手持哑铃，或前脚下垫高增加幅度。',
    regEn: 'Lower the rear-foot elevation and reduce depth.',
    regZh: '降低后脚垫高高度、减小下蹲深度。',
    defSets: 3,
    defReps: '8-10',
    defRest: 90,
  ),
  Exercise(
    id: 'glute_bridge',
    nameEn: 'Glute Bridge',
    nameZh: '臀桥',
    category: 'bodyweight',
    muscles: ['glutes', 'hamstrings', 'core'],
    difficulty: 1,
    descEn:
        'Hip extension from the floor. Wakes the glutes up and spares the lower back.',
    descZh: '地面上的伸髋动作。唤醒臀部，同时不给下背添乱。',
    cuesEn: [
      'Drive the hips up by squeezing the glutes, ribs stay down.',
      'Full lockout: shoulders, hips, knees in one line.'
    ],
    cuesZh: ['靠收紧臀部把髋顶起来，肋骨向下压住。', '完整锁定：肩、髋、膝一条线。'],
    mistakesEn: [
      'Arching the lower back at the top instead of squeezing glutes.',
      'Feet too far away, hamstrings taking over.'
    ],
    mistakesZh: ['顶端用下背反弓代替臀部收紧。', '双脚放太远，腘绳肌代偿。'],
    progEn: 'Move to single-leg bridges or add a pause at the top.',
    progZh: '进阶到单腿臀桥，或顶端加停顿。',
    regEn: 'Reduce the range, focus on the squeeze.',
    regZh: '减小幅度，专注臀部收缩感。',
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'single_leg_bridge',
    nameEn: 'Single-Leg Glute Bridge',
    nameZh: '单腿臀桥',
    category: 'bodyweight',
    muscles: ['glutes', 'hamstrings', 'core'],
    difficulty: 2,
    descEn:
        'One leg extended, the other drives. Exposes and fixes side-to-side glute imbalances.',
    descZh: '一腿伸直、一腿发力。暴露并修正左右臀力不平衡。',
    cuesEn: [
      'Keep the pelvis level — do not let the working side drop.',
      'Squeeze the glute hard at the top for one second.'
    ],
    cuesZh: ['骨盆保持水平——工作侧不要塌下去。', '顶端用力收紧臀部保持一秒。'],
    mistakesEn: ['Hips twisting as you press up.', 'Half range reps.'],
    mistakesZh: ['上顶时骨盆跟着旋转。', '只做半程。'],
    progEn: 'Add a pause at the top or elevate the working foot.',
    progZh: '顶端加停顿，或垫高支撑脚。',
    regEn: 'Return to two-leg bridges.',
    regZh: '回到双腿臀桥。',
    defSets: 3,
    defReps: '8-12',
    defRest: 60,
  ),
  Exercise(
    id: 'plank',
    nameEn: 'Plank',
    nameZh: '平板支撑',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 1,
    descEn:
        'Isometric core brace. Quality over clock — a shaking sagging plank teaches nothing.',
    descZh: '核心等长收缩。质量比时间重要——发抖塌腰的平板毫无意义。',
    cuesEn: [
      'Squeeze glutes, tuck the ribs, push the floor away with forearms.',
      'Breathe shallow but keep bracing.'
    ],
    cuesZh: ['收紧臀部、肋骨内收，前臂向下推地。', '浅呼吸，但保持核心张力。'],
    mistakesEn: [
      'Hips sagging toward the floor.',
      'Butt in the air, resting on the structure instead of the core.'
    ],
    mistakesZh: ['腰部向地面塌陷。', '撅臀，用骨骼结构硬撑而不是核心发力。'],
    progEn:
        'Add time in 10s steps up to 60s, then try long-lever (arms further forward) planks.',
    progZh: '每次加 10 秒直到 60 秒，然后做手臂更靠前的长杠杆平板。',
    regEn: 'Drop to the knees or do shorter sets.',
    regZh: '膝盖落地，或缩短单组时间。',
    defSets: 3,
    defReps: '30-45s',
    defRest: 60,
  ),
  Exercise(
    id: 'side_plank',
    nameEn: 'Side Plank',
    nameZh: '侧平板支撑',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 1,
    descEn:
        'Anti-side-bend brace for the obliques. Do both sides; start with the weaker one.',
    descZh: '抗侧屈训练，练腹斜肌。两侧都做，从弱侧开始。',
    cuesEn: [
      'Elbow under the shoulder, body in one straight line.',
      'Push the bottom hip up and hold.'
    ],
    cuesZh: ['手肘在肩膀正下方，身体成一条直线。', '把下侧的髋顶起来并保持。'],
    mistakesEn: [
      'Hip drifting toward the floor.',
      'Rotating the chest toward the ground.'
    ],
    mistakesZh: ['髋部慢慢向地面下沉。', '胸部向地面旋转。'],
    progEn: 'Add time or lift the top leg.',
    progZh: '延长时间或抬起上侧腿。',
    regEn: 'Bend the bottom knee and support from it.',
    regZh: '下侧膝盖弯曲撑地降低难度。',
    defSets: 3,
    defReps: '30-45s',
    defRest: 60,
  ),
  Exercise(
    id: 'mountain_climber',
    nameEn: 'Mountain Climber',
    nameZh: '登山跑',
    category: 'bodyweight',
    muscles: ['core', 'cardio'],
    difficulty: 1,
    descEn:
        'Plank position with fast knee drives. Core stability plus a conditioning kick.',
    descZh: '平板姿势下的快速提膝。既练核心稳定，又练心肺。',
    cuesEn: [
      'Hips stay low and level — no piking as legs speed up.',
      'Drive knees toward the chest, shoulders over wrists.'
    ],
    cuesZh: ['髋部保持低且平——腿快了也不要撅臀。', '膝盖往胸口带，肩膀在手腕正上方。'],
    mistakesEn: [
      'Bouncing hips up and down.',
      'Hands creeping forward, shoulders behind wrists.'
    ],
    mistakesZh: ['臀部上下乱晃。', '手不断前移，肩膀跑到手腕后面。'],
    progEn: 'Increase speed or do timed rounds at max effort.',
    progZh: '提高速度，或按时间做冲刺轮。',
    regEn: 'Slow the pace, hold a solid plank between drives.',
    regZh: '放慢节奏，每次提膝之间稳住平板。',
    defSets: 3,
    defReps: '30-45s',
    defRest: 60,
  ),
  Exercise(
    id: 'crunch',
    nameEn: 'Crunch',
    nameZh: '卷腹',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 1,
    descEn:
        'Short-range spinal flexion for the abs. Slow and squeezed beats fast and flung.',
    descZh: '短程脊柱屈曲练腹肌。慢而有挤压感远胜快而甩动。',
    cuesEn: [
      'Peel the shoulder blades off the floor, ribs toward hips.',
      'Exhale hard at the top.'
    ],
    cuesZh: ['肩胛骨离开地面，肋骨往髋部方向卷。', '顶端用力呼气。'],
    mistakesEn: [
      'Yanking the neck with the hands.',
      'Using momentum from rocking.'
    ],
    mistakesZh: ['双手拉扯脖子。', '靠晃动惯性起身。'],
    progEn: 'Add a pause at the top or move to harder ab work.',
    progZh: '顶端加停顿，或换成更难的腹部动作。',
    regEn: 'Reduce range, hands across the chest.',
    regZh: '减小幅度，双手交叉抱胸。',
    defSets: 3,
    defReps: '15-20',
    defRest: 45,
  ),
  Exercise(
    id: 'leg_raise',
    nameEn: 'Lying Leg Raise',
    nameZh: '仰卧举腿',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 2,
    descEn:
        'Lower-ab focused leg lift. The lower back must stay glued to the floor the whole set.',
    descZh: '偏下腹的举腿。全程下背必须贴紧地面。',
    cuesEn: [
      'Press the lower back into the floor before the legs move.',
      'Lower slowly until just before the back arches.'
    ],
    cuesZh: ['腿动之前先把下背压进地面。', '缓慢下放，在下背即将反弓前停住。'],
    mistakesEn: [
      'Lower back arching as the legs drop — that is where pain starts.',
      'Dropping the legs fast and bouncing.'
    ],
    mistakesZh: ['下放时下背反弓——腰痛就是从这里来的。', '腿部快速下砸借弹力。'],
    progEn: 'Slow the negatives or move to hanging leg raises.',
    progZh: '放慢离心阶段，或进阶到悬垂举腿。',
    regEn: 'Bend the knees, or place hands under the hips.',
    regZh: '屈膝完成，或双手垫在臀下。',
    defSets: 3,
    defReps: '10-15',
    defRest: 60,
  ),
  Exercise(
    id: 'russian_twist',
    nameEn: 'Russian Twist',
    nameZh: '俄罗斯转体',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 1,
    descEn:
        'Seated rotation for the obliques. Rotate the ribcage, not just the arms.',
    descZh: '坐姿转体练腹斜肌。转动的是胸廓，不是只有手臂。',
    cuesEn: [
      'Sit tall, lean back to about 45 degrees.',
      'Rotate from the trunk, eyes follow the hands.'
    ],
    cuesZh: ['坐直，后倾约 45 度。', '躯干发力旋转，眼睛跟着手走。'],
    mistakesEn: [
      'Only swinging the arms side to side.',
      'Lower back rounded into a slouch.'
    ],
    mistakesZh: ['只有手臂左右摆。', '下背弓成驼背姿势。'],
    progEn: 'Hold a dumbbell or lift the feet off the floor.',
    progZh: '手持哑铃，或双脚离地。',
    regEn: 'Keep the feet down and skip the weight.',
    regZh: '双脚踩地，不加重量。',
    defSets: 3,
    defReps: '20-30',
    defRest: 45,
  ),
  Exercise(
    id: 'superman',
    nameEn: 'Superman',
    nameZh: '俯卧背伸展',
    category: 'bodyweight',
    contraindications: ['lower_back'],
    muscles: ['lower_back'],
    difficulty: 1,
    descEn:
        'Prone back extension for the spinal erectors. Small lifts, no jerking — this is not a hamstring curl.',
    descZh: '俯卧背伸练竖脊肌。小幅上抬、不要猛甩——这不是弯腿举。',
    cuesEn: [
      'Lift chest and thighs slightly, reach long, not high.',
      'Squeeze for a second at the top.'
    ],
    cuesZh: ['胸部和大腿小幅上抬，重点是向远处延伸而不是抬多高。', '顶端收紧保持一秒。'],
    mistakesEn: [
      'Cranking the neck upward.',
      'Big bouncy reps that strain the spine.'
    ],
    mistakesZh: ['脖子使劲后仰。', '大幅弹动式起伏，伤脊柱。'],
    progEn: 'Add a longer top hold.',
    progZh: '延长顶端保持时间。',
    regEn: 'Lift only the chest, keep legs down.',
    regZh: '只抬胸部，腿保持贴地。',
    defSets: 3,
    defReps: '12-15',
    defRest: 45,
  ),
  Exercise(
    id: 'bird_dog',
    nameEn: 'Bird Dog',
    nameZh: '鸟狗式',
    category: 'bodyweight',
    muscles: ['core', 'lower_back'],
    difficulty: 1,
    descEn:
        'Opposite arm and leg extend from all fours. Anti-rotation core control, kind to the spine.',
    descZh: '四点支撑下对侧手脚伸展。抗旋转的核心控制，对脊柱很友好。',
    cuesEn: [
      'Move slowly, hips and shoulders stay level.',
      'Reach long in opposite directions, then return with control.'
    ],
    cuesZh: ['动作放慢，髋和肩保持水平。', '对侧方向延伸到位，再有控制地收回。'],
    mistakesEn: [
      'Hips rotating open as the leg lifts.',
      'Rushing — it becomes a balance flail.'
    ],
    mistakesZh: ['抬腿时髋部向外旋转。', '动作太急，变成晃动的平衡游戏。'],
    progEn: 'Add a 3s hold at full extension.',
    progZh: '完全伸展位保持 3 秒。',
    regEn: 'Extend only the leg, keep both hands down.',
    regZh: '只伸腿，双手保持撑地。',
    defSets: 3,
    defReps: '10',
    defRest: 45,
  ),
  Exercise(
    id: 'pullup',
    nameEn: 'Pull-Up',
    nameZh: '引体向上',
    category: 'bodyweight',
    muscles: ['back', 'biceps'],
    difficulty: 3,
    descEn:
        'The king of upper-body pulling. Needs a bar — door frame bars count.',
    descZh: '上半身拉类动作之王。需要一根单杠——门框单杠也可以。',
    cuesEn: [
      'Start from a dead hang, pull the chest toward the bar.',
      'Drive elbows down and back, squeeze the shoulder blades.'
    ],
    cuesZh: ['从完全悬垂开始，把胸口往杠的方向拉。', '手肘向下向后压，肩胛骨收紧。'],
    mistakesEn: [
      'Kipping and half reps instead of full hang to chin over bar.',
      'Shrugging into the ears without engaging the lats.'
    ],
    mistakesZh: ['靠蹬腿借力、只做半程。', '耸肩到耳朵，背阔肌没参与。'],
    progEn: 'Add weight with a backpack, or slow the negatives.',
    progZh: '背包装重，或放慢离心阶段。',
    regEn: 'Use band assistance or do negatives only.',
    regZh: '用弹力带辅助，或只做离心下降。',
    defSets: 4,
    defReps: '6-10',
    defRest: 120,
  ),
  Exercise(
    id: 'bench_dip',
    nameEn: 'Bench Dip',
    nameZh: '凳上臂屈伸',
    category: 'bodyweight',
    contraindications: ['shoulder'],
    muscles: ['triceps', 'chest'],
    difficulty: 1,
    descEn:
        'Triceps dip with hands on a bench or chair behind you. No equipment beyond furniture.',
    descZh: '双手撑在身后的凳子或椅子上做臂屈伸。有家具就能练。',
    cuesEn: [
      'Hips close to the bench, elbows bend straight back.',
      'Shoulders stay down away from the ears.'
    ],
    cuesZh: ['臀部靠近凳子，手肘向后直直弯曲。', '肩膀下沉，远离耳朵。'],
    mistakesEn: [
      'Hips drifting away from the bench.',
      'Descending so deep the shoulders pinch.'
    ],
    mistakesZh: ['臀部越滑越远。', '下放过深导致肩前侧挤压疼痛。'],
    progEn: 'Elevate the feet or rest a weight on the lap.',
    progZh: '垫高双脚，或腿上放个重物。',
    regEn: 'Bend the knees to shorten the lever.',
    regZh: '屈膝降低难度。',
    defSets: 3,
    defReps: '10-12',
    defRest: 90,
  ),
  Exercise(
    id: 'jump_squat',
    nameEn: 'Jump Squat',
    nameZh: '跳跃深蹲',
    category: 'bodyweight',
    contraindications: ['knee'],
    muscles: ['quads', 'cardio'],
    difficulty: 2,
    descEn:
        'Explosive squat to a vertical jump. Power plus conditioning — land soft.',
    descZh: '深蹲接垂直起跳。练爆发力也练心肺——落地要轻。',
    cuesEn: [
      'Land with soft knees, absorb through the whole foot.',
      'Quality jumps only — stop when height drops.'
    ],
    cuesZh: ['屈膝缓冲落地，全脚掌吸收冲击。', '只做好看的跳跃——高度掉下来就停。'],
    mistakesEn: [
      'Stiff-legged landings straight into the knees.',
      'Grinding extra reps after power is gone.'
    ],
    mistakesZh: ['直腿硬着陆，冲击直达膝盖。', '爆发力没了还硬凑次数。'],
    progEn: 'Add a tuck or hold light dumbbells.',
    progZh: '加收腿动作，或持轻哑铃。',
    regEn: 'Do fast bodyweight squats without the jump.',
    regZh: '做不跳起的快速自重深蹲。',
    defSets: 3,
    defReps: '10-12',
    defRest: 90,
  ),
  Exercise(
    id: 'burpee',
    nameEn: 'Burpee',
    nameZh: '波比跳',
    category: 'bodyweight',
    muscles: ['full_body', 'cardio'],
    difficulty: 2,
    descEn:
        'Squat, kick to a push-up, jump up. The full-body conditioner everyone loves to hate.',
    descZh: '下蹲、撑地变俯卧撑、起跳。全身心肺训练的全民公敌。',
    cuesEn: [
      'Keep the push-up honest — chest to the floor.',
      'Move at a pace you can hold for the whole set.'
    ],
    cuesZh: ['俯卧撑别偷懒——胸口要碰地。', '用整组都能保持的节奏做。'],
    mistakesEn: [
      'Snake push-ups with the hips collapsing first.',
      'Sprinting the first reps then dying — pace it.'
    ],
    mistakesZh: ['塌腰的蛇形假俯卧撑。', '前几个猛冲后面瘫掉——控制节奏。'],
    progEn: 'Add a tuck jump or wear a weighted vest.',
    progZh: '起跳加收腿，或穿负重背心。',
    regEn: 'Step back and step up instead of hopping.',
    regZh: '手脚改为先后退再收回，不跳。',
    defSets: 3,
    defReps: '10-15',
    defRest: 90,
  ),
  Exercise(
    id: 'calf_raise_bw',
    nameEn: 'Standing Calf Raise',
    nameZh: '站姿提踵',
    category: 'bodyweight',
    muscles: ['calves'],
    difficulty: 1,
    descEn:
        'Simple calf work. Full stretch at the bottom, full squeeze at the top.',
    descZh: '简单的小腿训练。底部完全拉伸，顶部完全收紧。',
    cuesEn: [
      'Pause at the top and feel the calf squeeze.',
      'Full range: heels below the level of the toes if possible.'
    ],
    cuesZh: ['顶端停顿，感受小腿收紧。', '全幅度：尽量让脚跟低于前脚掌水平。'],
    mistakesEn: [
      'Fast bouncy reps on no range.',
      'Rolling onto the outside of the foot.'
    ],
    mistakesZh: ['幅度极小的弹跳式提踵。', '重心滚到脚掌外侧。'],
    progEn: 'Single-leg version, or do them on a stair step for extra range.',
    progZh: '换成单腿提踵，或站在台阶边缘加大幅度。',
    regEn: 'Hold a wall for balance and slow down.',
    regZh: '扶墙保持平衡并放慢速度。',
    defSets: 4,
    defReps: '15-20',
    defRest: 45,
  ),
  Exercise(
    id: 'wall_sit',
    nameEn: 'Wall Sit',
    nameZh: '靠墙静蹲',
    category: 'bodyweight',
    muscles: ['quads'],
    difficulty: 1,
    descEn:
        'Isometric squat hold against a wall. Knee-friendly burn, great finisher.',
    descZh: '靠墙的等长深蹲保持。对膝盖友好，适合收尾。',
    cuesEn: [
      'Thighs parallel to the floor, back flat on the wall.',
      'Weight through the heels.'
    ],
    cuesZh: ['大腿平行地面，背部贴紧墙面。', '重心放在脚跟。'],
    mistakesEn: [
      'Sliding up into a shallow squat as it burns.',
      'Hands resting on the thighs.'
    ],
    mistakesZh: ['酸了就往下滑变成浅蹲。', '用手撑在大腿上偷懒。'],
    progEn: 'Add 15s per round or hold a weight to the chest.',
    progZh: '每轮加 15 秒，或胸前抱重物。',
    regEn: 'Sit a bit higher and shorten the hold.',
    regZh: '坐高一点，缩短保持时间。',
    defSets: 3,
    defReps: '45-60s',
    defRest: 60,
  ),
  // ---- added 2026-10-29: pulling without a gym, more core + lower body
  Exercise(
    id: 'inverted_row',
    nameEn: 'Inverted Row',
    nameZh: '反向划船',
    category: 'bodyweight',
    muscles: ['back', 'biceps'],
    difficulty: 1,
    descEn:
        'The missing pull for home training: lie under a sturdy table or low bar and row your chest up to it.',
    descZh: '居家训练缺的那个拉：躺在结实的桌子或低杠下面，把胸口划向桌沿。',
    cuesEn: [
      'Body straight from heels to head, like an upside-down plank.',
      'Pull elbows back past the ribs and squeeze the shoulder blades.'
    ],
    cuesZh: ['脚跟到头顶一条直线，像一个倒过来的平板支撑。', '手肘向后拉过肋骨，夹紧肩胛骨。'],
    mistakesEn: [
      'Hips sagging so only the arms work.',
      'Craning the chin toward the bar instead of bringing the chest.'
    ],
    mistakesZh: ['塌髋，只剩手臂在用力。', '伸下巴去够桌沿，而不是把胸口带上去。'],
    progEn: 'Walk the feet further forward, then elevate them on a chair.',
    progZh: '双脚往前走让身体更平，再把脚垫高到椅子上。',
    regEn: 'Bend the knees, or use a higher bar so the body is more upright.',
    regZh: '屈膝做，或换更高的杠让身体更直立。',
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'chin_up',
    nameEn: 'Chin-Up',
    nameZh: '反手引体向上',
    category: 'bodyweight',
    muscles: ['back', 'biceps'],
    difficulty: 3,
    descEn:
        'Palms-facing-you pull-up. The biceps help more, so most people get their first rep here before the pull-up.',
    descZh: '掌心朝向自己的引体向上。二头肌参与更多，多数人的第一个引体是在这里完成的。',
    cuesEn: [
      'Start from a full hang, shoulders pulled down first.',
      'Drive elbows toward the hips until the chin clears the bar.'
    ],
    cuesZh: ['从完全悬垂开始，先把肩膀往下沉。', '手肘往髋部方向拉，直到下巴过杠。'],
    mistakesEn: [
      'Kipping or kicking to get over the bar.',
      'Half reps that never reach a straight-arm hang.'
    ],
    mistakesZh: ['蹬腿摆动借力过杠。', '半程动作，手臂从不伸直。'],
    progEn: 'Add a 3-second lowering, then add weight.',
    progZh: '下放放慢到 3 秒，再加负重。',
    regEn: 'Negative chin-ups or inverted rows.',
    regZh: '离心引体或反向划船。',
    defSets: 3,
    defReps: '5-8',
    defRest: 120,
  ),
  Exercise(
    id: 'negative_pullup',
    nameEn: 'Negative Pull-Up',
    nameZh: '离心引体向上',
    category: 'bodyweight',
    muscles: ['back', 'biceps'],
    difficulty: 2,
    descEn:
        'Jump or step to the top of a pull-up, then lower yourself as slowly as you can. The bridge to your first full rep.',
    descZh: '跳起或踩凳到引体顶端，再尽可能慢地下放。通往第一个完整引体的桥梁。',
    cuesEn: [
      'Take 3-5 seconds to lower, evenly the whole way.',
      'Keep the chest up and shoulders packed until arms are straight.'
    ],
    cuesZh: ['用 3-5 秒下放，全程匀速。', '挺胸、沉肩，一直控制到手臂伸直。'],
    mistakesEn: [
      'Dropping fast through the bottom half.',
      'Doing too many reps — quality fades quickly.'
    ],
    mistakesZh: ['下半程直接掉下去。', '做太多次——质量下降得很快。'],
    progEn: 'Slow to 8 seconds, then try a full pull-up.',
    progZh: '下放放慢到 8 秒，然后尝试完整引体。',
    regEn: 'Dead hangs and inverted rows.',
    regZh: '先做悬垂和反向划船。',
    defSets: 3,
    defReps: '3-5',
    defRest: 120,
  ),
  Exercise(
    id: 'dead_hang',
    nameEn: 'Dead Hang',
    nameZh: '悬垂',
    category: 'bodyweight',
    muscles: ['back', 'forearms', 'core'],
    difficulty: 1,
    descEn:
        'Just hang from a bar. Builds grip, decompresses the spine and prepares the shoulders for pull-ups.',
    descZh: '就是挂在单杠上。练握力、放松脊柱，也为引体向上准备好肩膀。',
    cuesEn: [
      'Full grip, thumbs around the bar.',
      'Breathe slowly; let the body hang long and still.'
    ],
    cuesZh: ['全握，大拇指扣住杠。', '缓慢呼吸，让身体拉长、保持不动。'],
    mistakesEn: ['Swinging or kicking the legs.', 'Holding the breath.'],
    mistakesZh: ['身体晃动或乱踢腿。', '憋气。'],
    progEn: 'Active hang (shoulders pulled down), then one-arm assisted hangs.',
    progZh: '主动悬垂（沉肩），再做单手辅助悬垂。',
    regEn: 'Keep the toes lightly on a box to take some weight.',
    regZh: '脚尖轻点在箱子上分担部分体重。',
    defSets: 3,
    defReps: '20-40s',
    defRest: 60,
  ),
  Exercise(
    id: 'decline_pushup',
    nameEn: 'Decline Push-Up',
    nameZh: '下斜俯卧撑',
    category: 'bodyweight',
    muscles: ['chest', 'shoulders', 'triceps'],
    difficulty: 2,
    descEn:
        'Feet up on a chair or step. More of your weight goes to the hands and the upper chest works harder.',
    descZh: '双脚垫在椅子或台阶上。更多体重压到双手，上胸参与更多。',
    cuesEn: [
      'Keep the same rigid plank as a floor push-up.',
      'Lower the upper chest toward the floor between the hands.'
    ],
    cuesZh: ['保持和地面俯卧撑一样绷直的身体。', '上胸朝双手之间的地面下降。'],
    mistakesEn: [
      'Hips piking up to make it easier.',
      'Head dropping toward the floor first.'
    ],
    mistakesZh: ['撅起臀部偷懒。', '头先低下去够地面。'],
    progEn: 'Raise the feet higher, or add a pause at the bottom.',
    progZh: '把脚垫得更高，或在最低点停顿。',
    regEn: 'Regular push-ups.',
    regZh: '回到标准俯卧撑。',
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'archer_pushup',
    nameEn: 'Archer Push-Up',
    nameZh: '弓箭手俯卧撑',
    category: 'bodyweight',
    muscles: ['chest', 'triceps', 'shoulders'],
    difficulty: 3,
    descEn:
        'Very wide hands; shift your weight to one side while the other arm stays nearly straight. A step toward one-arm push-ups.',
    descZh: '双手很宽，重心移到一侧，另一侧手臂几乎伸直。是通往单臂俯卧撑的一步。',
    cuesEn: [
      'Lower toward the working hand; the other arm only assists.',
      'Keep hips square to the floor — no twisting.'
    ],
    cuesZh: ['朝发力手一侧下降，另一侧手臂只做辅助。', '髋部保持与地面平行，不要扭转。'],
    mistakesEn: [
      'Bending both arms equally — that is just a wide push-up.',
      'Rotating the torso to cheat the bottom.'
    ],
    mistakesZh: ['两侧手臂同样弯曲——那只是宽距俯卧撑。', '在底部扭转躯干借力。'],
    progEn:
        'Lift the assisting hand onto fingertips, then toward one-arm push-ups.',
    progZh: '辅助手改为指尖撑，再向单臂俯卧撑过渡。',
    regEn: 'Wide push-ups, or archers with hands on a bench.',
    regZh: '宽距俯卧撑，或双手撑凳做弓箭手。',
    defSets: 3,
    defReps: '5-8',
    defRest: 120,
  ),
  Exercise(
    id: 'reverse_lunge',
    nameEn: 'Reverse Lunge',
    nameZh: '后撤步箭步蹲',
    category: 'bodyweight',
    muscles: ['quads', 'glutes'],
    difficulty: 1,
    descEn:
        'Step backward instead of forward. Easier to balance and the front shin stays more upright than in a forward lunge.',
    descZh: '向后撤步而不是向前跨。比前跨箭步蹲更好平衡，前侧小腿也更竖直。',
    cuesEn: [
      'Most of the weight stays on the front foot.',
      'Drop the back knee straight down, then push through the front heel.'
    ],
    cuesZh: ['大部分重心留在前脚。', '后膝垂直向下落，再用前脚跟蹬起。'],
    mistakesEn: [
      'Stepping back too short so the front knee shoots forward.',
      'Pushing off the back foot to stand up.'
    ],
    mistakesZh: ['后撤步太小，前膝猛往前冲。', '用后脚蹬地站起来。'],
    progEn: 'Hold dumbbells, or step back from a low step (deficit).',
    progZh: '手持哑铃，或站在矮台阶上向后撤（增加幅度）。',
    regEn: 'Hold a wall or chair for balance; shorten the depth.',
    regZh: '扶墙或椅子保持平衡，减小下蹲深度。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'lateral_lunge',
    nameEn: 'Lateral Lunge',
    nameZh: '侧弓步',
    category: 'bodyweight',
    muscles: ['quads', 'adductors', 'glutes'],
    difficulty: 2,
    descEn:
        'Step wide to the side and sit into one hip. Trains the legs in the side-to-side direction most plans ignore.',
    descZh: '向侧面大步跨出，坐向一侧髋部。练到多数计划忽略的左右方向。',
    cuesEn: [
      'Sit the hips back over the bent leg; the other leg stays straight.',
      'Keep the whole foot down and the knee in line with the toes.'
    ],
    cuesZh: ['臀部往后坐到弯曲的那条腿上，另一条腿伸直。', '全脚掌踩实，膝盖与脚尖方向一致。'],
    mistakesEn: [
      'Knee caving inward on the bent leg.',
      'Rounding the back to reach lower.'
    ],
    mistakesZh: ['弯曲侧膝盖内扣。', '弓背去够更低的位置。'],
    progEn: 'Hold a dumbbell at the chest (goblet lateral lunge).',
    progZh: '胸前抱一只哑铃（高脚杯侧弓步）。',
    regEn: 'Shorter step and shallower depth, holding a support.',
    regZh: '步幅缩小、蹲浅一点，扶着支撑物。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '8-10',
    defRest: 90,
  ),
  Exercise(
    id: 'pistol_squat',
    nameEn: 'Pistol Squat',
    nameZh: '单腿深蹲',
    category: 'bodyweight',
    muscles: ['quads', 'glutes', 'core'],
    difficulty: 3,
    descEn:
        'Full squat on one leg with the other held out in front. Strength, mobility and balance in one move.',
    descZh: '单腿完成全程深蹲，另一条腿向前伸直。力量、灵活性和平衡集于一身。',
    cuesEn: [
      'Reach the arms forward as a counterweight.',
      'Sit down slowly, heel flat, knee tracking over the toes.'
    ],
    cuesZh: ['双臂向前伸作为配重。', '缓慢坐下，脚跟踩实，膝盖对准脚尖。'],
    mistakesEn: [
      'Collapsing into the bottom without control.',
      'Heel lifting off the floor.'
    ],
    mistakesZh: ['失控地跌坐到底。', '脚跟离地。'],
    progEn: 'Slow 3-second descents, then hold a light weight.',
    progZh: '3 秒慢速下蹲，再手持轻重量。',
    regEn: 'Box pistols: sit to a chair and stand back up on one leg.',
    regZh: '坐箱单腿蹲：单腿坐到椅子上再单腿站起。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '3-6',
    defRest: 120,
  ),
  Exercise(
    id: 'nordic_curl',
    nameEn: 'Nordic Hamstring Curl',
    nameZh: '北欧挺',
    category: 'bodyweight',
    muscles: ['hamstrings', 'glutes'],
    difficulty: 3,
    descEn:
        'Kneel with the ankles anchored under a sofa and lower your body forward as slowly as you can. Brutal for the hamstrings.',
    descZh: '跪姿，脚踝卡在沙发底下固定，身体尽可能慢地向前倒下。对腘绳肌非常狠。',
    cuesEn: [
      'Hips stay extended — one straight line from knees to head.',
      'Fight the fall all the way, catch yourself with the hands.'
    ],
    cuesZh: ['髋部保持伸直——膝盖到头顶一条直线。', '全程对抗下落，最后用双手撑住地面。'],
    mistakesEn: [
      'Bending at the hips to shorten the lever.',
      'Letting go halfway and dropping.'
    ],
    mistakesZh: ['屈髋缩短力臂偷懒。', '到一半就放弃直接倒下。'],
    progEn:
        'Lower further before catching, then pull back up with less hand push.',
    progZh: '撑地前下放得更低，再逐步减少手推、靠腿拉回。',
    regEn: 'Partial range only, or glute bridges and single-leg bridges.',
    regZh: '只做部分幅度，或先练臀桥和单腿臀桥。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '3-6',
    defRest: 120,
  ),
  Exercise(
    id: 'donkey_kick',
    nameEn: 'Donkey Kick',
    nameZh: '跪姿后踢腿',
    category: 'bodyweight',
    muscles: ['glutes', 'core'],
    difficulty: 1,
    descEn:
        'On hands and knees, press one heel up toward the ceiling. A simple way to feel the glutes working.',
    descZh: '四点跪姿，一侧脚跟向天花板方向蹬。最简单的找臀部发力感的方法。',
    cuesEn: [
      'Keep the knee bent 90 degrees and push the heel straight up.',
      'Brace the core so the lower back does not arch.'
    ],
    cuesZh: ['膝盖保持 90 度，脚跟垂直向上蹬。', '收紧核心，腰不要塌。'],
    mistakesEn: [
      'Swinging the leg with momentum.',
      'Arching the back to lift higher.'
    ],
    mistakesZh: ['靠惯性甩腿。', '塌腰换来更高的高度。'],
    progEn:
        'Pause 2 seconds at the top, or hold a light dumbbell behind the knee.',
    progZh: '顶端停 2 秒，或在膝窝夹一只轻哑铃。',
    regEn: 'Smaller range; focus on the squeeze.',
    regZh: '减小幅度，专注臀部收缩。',
    defSets: 3,
    defReps: '12-15',
    defRest: 45,
  ),
  Exercise(
    id: 'dead_bug',
    nameEn: 'Dead Bug',
    nameZh: '死虫式',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 1,
    descEn:
        'On your back, slowly extend opposite arm and leg while the lower back stays glued to the floor. The safest core builder.',
    descZh: '仰卧，对侧手脚缓慢伸展，下背始终贴紧地面。最安全的核心训练。',
    cuesEn: [
      'Press the lower back into the floor before moving.',
      'Exhale as the limbs reach out; move slowly.'
    ],
    cuesZh: ['动之前先把下背压向地面。', '手脚伸出时呼气，动作要慢。'],
    mistakesEn: [
      'Lower back lifting off as the leg goes down.',
      'Rushing through reps.'
    ],
    mistakesZh: ['腿往下放时下背离地。', '动作太快。'],
    progEn: 'Hold light dumbbells, or pause with the limbs extended.',
    progZh: '手持轻哑铃，或在伸展位停顿。',
    regEn: 'Move only the legs, or only tap the heel down.',
    regZh: '只动腿，或只做脚跟点地。',
    defSets: 3,
    defReps: '8-10',
    defRest: 45,
  ),
  Exercise(
    id: 'hollow_hold',
    nameEn: 'Hollow Body Hold',
    nameZh: '空心支撑',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 2,
    descEn:
        'Lie on your back and lift shoulders and legs into a shallow banana shape. The gymnast core foundation.',
    descZh: '仰卧，肩膀和双腿抬离地面成浅浅的香蕉形。体操运动员的核心基础。',
    cuesEn: [
      'Lower back stays pressed into the floor the whole time.',
      'Arms by the ears, legs long, breathe shallowly.'
    ],
    cuesZh: ['下背全程压住地面。', '双臂贴耳，双腿伸长，浅呼吸。'],
    mistakesEn: ['Lower back peeling off the floor.', 'Holding the breath.'],
    mistakesZh: ['下背离开地面。', '憋气。'],
    progEn: 'Lower the legs closer to the floor, then add hollow rocks.',
    progZh: '双腿降得更低，再做空心摇摆。',
    regEn: 'Bend the knees and keep the arms by the sides.',
    regZh: '屈膝，双臂放在身体两侧。',
    defSets: 3,
    defReps: '20-30s',
    defRest: 45,
  ),
  Exercise(
    id: 'bicycle_crunch',
    nameEn: 'Bicycle Crunch',
    nameZh: '单车卷腹',
    category: 'bodyweight',
    muscles: ['core'],
    difficulty: 1,
    descEn:
        'Alternate elbow toward opposite knee while the other leg extends. Works the obliques along with the abs.',
    descZh: '手肘交替靠近对侧膝盖，另一条腿伸直。在练腹直肌的同时练到腹斜肌。',
    cuesEn: [
      'Rotate the shoulder toward the knee, not just the elbow.',
      'Slow and controlled — feel each side.'
    ],
    cuesZh: ['是肩膀转向膝盖，而不只是手肘。', '慢而有控制，感受每一侧。'],
    mistakesEn: [
      'Yanking the neck with the hands.',
      'Pedalling fast with tiny range.'
    ],
    mistakesZh: ['用手拽脖子。', '小幅度快速蹬腿。'],
    progEn: 'Pause 1 second on each side, or extend the legs lower.',
    progZh: '每侧停 1 秒，或把腿伸得更低。',
    regEn: 'Keep feet on the floor and just rotate (cross-body crunch).',
    regZh: '双脚着地只做转体（交叉卷腹）。',
    defSets: 3,
    defReps: '12-16',
    defRest: 45,
  ),
  Exercise(
    id: 'jumping_jack',
    nameEn: 'Jumping Jack',
    nameZh: '开合跳',
    category: 'bodyweight',
    muscles: ['cardio', 'full_body'],
    difficulty: 1,
    descEn:
        'The classic warm-up and conditioning move. Raises heart rate fast with almost no learning curve.',
    descZh: '经典的热身和体能动作。几乎零学习成本，快速提高心率。',
    cuesEn: [
      'Land softly on the balls of the feet.',
      'Arms all the way overhead, keep a steady rhythm.'
    ],
    cuesZh: ['用前脚掌轻柔落地。', '双臂完全举过头顶，节奏均匀。'],
    mistakesEn: ['Landing flat-footed and loud.', 'Half-way arm swings.'],
    mistakesZh: ['全脚掌重重砸地。', '手臂只摆一半。'],
    progEn: 'Go longer or faster, or switch to burpees.',
    progZh: '延长时间或加快节奏，或换成波比跳。',
    regEn: 'Step-out jacks: step one foot out at a time, no jumping.',
    regZh: '无跳跃版：左右脚轮流向外迈步。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '30-45s',
    defRest: 45,
  ),
  Exercise(
    id: 'bear_crawl',
    nameEn: 'Bear Crawl',
    nameZh: '熊爬',
    category: 'bodyweight',
    muscles: ['full_body', 'core'],
    difficulty: 2,
    descEn:
        'Crawl on hands and feet with the knees hovering just above the floor. Core, shoulders and coordination together.',
    descZh: '手脚着地爬行，膝盖悬空离地几厘米。核心、肩膀和协调性一起练。',
    cuesEn: [
      'Back flat like a table, knees an inch off the floor.',
      'Move opposite hand and foot together, small steps.'
    ],
    cuesZh: ['后背像桌面一样平，膝盖离地一寸。', '对侧手脚同时移动，小步前进。'],
    mistakesEn: [
      'Hips shooting up high.',
      'Rushing so the hips sway side to side.'
    ],
    mistakesZh: ['臀部翘得很高。', '爬太快导致髋部左右晃。'],
    progEn: 'Crawl backward and sideways, or go longer.',
    progZh: '向后、向侧面爬，或延长时间。',
    regEn: 'Bear hold: stay in place with knees hovering.',
    regZh: '熊式静止：膝盖悬空原地保持。',
    defSets: 3,
    defReps: '20-30s',
    defRest: 60,
  ),

  // ------------------------------------------------ legs, hips & calves (v0.4)
  Exercise(
    id: 'cossack_squat',
    nameEn: 'Cossack Squat',
    nameZh: '哥萨克深蹲',
    category: 'bodyweight',
    muscles: ['quads', 'adductors', 'glutes'],
    difficulty: 2,
    descEn:
        'Wide stance, sit all the way down over one leg while the other stays straight with the toes up. Inner-thigh strength and hip mobility in one move.',
    descZh: '宽站距，完全坐到一条腿上，另一条腿伸直、脚尖朝上。一个动作练到大腿内侧力量和髋关节活动度。',
    cuesEn: [
      'Heel of the bent leg stays down; chest up.',
      'Shift across slowly — the straight leg is actively stretched, not relaxed.'
    ],
    cuesZh: ['弯曲腿的脚跟踩实，胸口挺起。', '慢慢横移——伸直的那条腿主动拉伸，不是放松。'],
    mistakesEn: [
      'Heel lifting on the squatting leg.',
      'Collapsing forward to get lower.'
    ],
    mistakesZh: ['下蹲腿脚跟离地。', '为了蹲更低整个人往前趴。'],
    progEn: 'Hold a light dumbbell at the chest as a counterweight.',
    progZh: '胸前抱一只轻哑铃作配重。',
    regEn: 'Hold a doorframe or pole and go only as deep as the heel allows.',
    regZh: '扶门框或立柱，只蹲到脚跟还能踩实的深度。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '6-8',
    defRest: 90,
  ),
  Exercise(
    id: 'copenhagen_plank',
    nameEn: 'Copenhagen Plank',
    nameZh: '哥本哈根侧撑',
    category: 'bodyweight',
    muscles: ['adductors', 'core'],
    difficulty: 2,
    descEn:
        'Side plank with the top leg resting on a bench. The inner thigh holds the whole body up — the best adductor builder that needs no machine.',
    descZh: '侧平板，上面那条腿搭在凳子上。大腿内侧撑起整个身体——不用器械的最佳内收肌训练。',
    cuesEn: [
      'Elbow under the shoulder; body in one straight line from head to top foot.',
      'Press the top knee or foot down into the bench the whole time.'
    ],
    cuesZh: ['手肘在肩膀正下方，头到上脚一条直线。', '全程把上面那条腿的膝盖或脚往凳子里压。'],
    mistakesEn: [
      'Hips sagging toward the floor.',
      'Rotating the chest toward the ceiling.'
    ],
    mistakesZh: ['髋部往地面塌。', '胸口转向天花板。'],
    progEn:
        'Straighten the top leg (rest the ankle, not the knee, on the bench) and lift the bottom leg.',
    progZh: '上腿伸直（脚踝而非膝盖搭凳），再把下面的腿抬离地面。',
    regEn:
        'Rest the top knee on the bench and keep the bottom knee bent on the floor.',
    regZh: '上腿膝盖搭凳，下腿屈膝放在地上。',
    defSets: 3,
    defReps: '20-30s',
    defRest: 60,
  ),
  Exercise(
    id: 'sumo_squat_bw',
    nameEn: 'Sumo Squat',
    nameZh: '相扑深蹲',
    category: 'bodyweight',
    muscles: ['quads', 'adductors', 'glutes'],
    difficulty: 1,
    descEn:
        'Wide stance, toes turned out, knees tracking over the toes. Shifts work from the front of the thigh to the inner thigh and glutes.',
    descZh: '宽站距、脚尖外八，膝盖顺着脚尖方向。把负荷从大腿前侧转到内侧和臀部。',
    cuesEn: [
      'Push the knees out over the toes on the way down.',
      'Torso upright, hips straight down between the feet.'
    ],
    cuesZh: ['下蹲时膝盖往外推到脚尖方向。', '躯干直立，髋部垂直落在两脚之间。'],
    mistakesEn: [
      'Knees falling inside the feet.',
      'Leaning forward and turning it into a hinge.'
    ],
    mistakesZh: ['膝盖掉到脚的内侧。', '前倾变成髋屈伸。'],
    progEn: 'Pause 2 s at the bottom, then move to the dumbbell version.',
    progZh: '底部停 2 秒，然后进阶到哑铃版。',
    regEn: 'Squat to a box or chair.',
    regZh: '蹲到箱子或椅子上。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '12-15',
    defRest: 60,
  ),
  Exercise(
    id: 'curtsy_lunge',
    nameEn: 'Curtsy Lunge',
    nameZh: '屈膝礼弓步',
    category: 'bodyweight',
    muscles: ['glutes', 'quads', 'abductors'],
    difficulty: 2,
    descEn:
        'Step one foot back and across behind the other, like a curtsy. Loads the outer hip and glute more than a straight lunge.',
    descZh: '一只脚向后并交叉到另一只脚后方，像行屈膝礼。比普通弓步更练到臀外侧和臀中肌。',
    cuesEn: [
      'Front knee stays over the front foot; hips stay square to the front.',
      'Lower under control until the back knee nearly touches the floor.'
    ],
    cuesZh: ['前膝保持在前脚正上方，髋部正对前方。', '有控制地下降到后膝几乎触地。'],
    mistakesEn: [
      'Front knee collapsing inward.',
      'Twisting the hips to make the step easier.'
    ],
    mistakesZh: ['前膝内扣。', '为了省力把髋扭开。'],
    progEn: 'Hold a dumbbell at the chest.',
    progZh: '胸前抱一只哑铃。',
    regEn: 'Shorter cross-step with a hand on a support.',
    regZh: '交叉步幅缩小，一只手扶支撑物。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '8-10',
    defRest: 75,
  ),
  Exercise(
    id: 'walking_lunge',
    nameEn: 'Walking Lunge',
    nameZh: '行走弓步',
    category: 'bodyweight',
    muscles: ['quads', 'glutes'],
    difficulty: 2,
    descEn:
        'Lunge forward and step straight through into the next lunge. More balance and more glute than the stationary version.',
    descZh: '向前弓步后直接跨进下一个弓步。比原地版更考验平衡，也更练臀。',
    cuesEn: [
      'Long steps; the back knee drops straight down.',
      'Push off the front heel and bring the back foot through in one motion.'
    ],
    cuesZh: ['步幅要大，后膝垂直下落。', '前脚跟发力，后脚一步跨过来。'],
    mistakesEn: [
      'Short, choppy steps that load the knee.',
      'Leaning forward over the front leg.'
    ],
    mistakesZh: ['步子又短又碎，压力都在膝盖上。', '身体趴向前腿。'],
    progEn: 'Carry dumbbells at the sides.',
    progZh: '双手各持哑铃垂在体侧。',
    regEn: 'Stationary split squat until the balance is there.',
    regZh: '先做原地分腿蹲，等平衡够了再行走。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '10-12',
    defRest: 75,
  ),
  Exercise(
    id: 'sissy_squat',
    nameEn: 'Sissy Squat',
    nameZh: '西西深蹲',
    category: 'bodyweight',
    muscles: ['quads'],
    difficulty: 3,
    descEn:
        'Knees travel far forward while the body leans back in one line from knee to shoulder. Isolates the quads harder than anything else bodyweight.',
    descZh: '膝盖大幅前移，身体从膝到肩成一条直线向后倾。徒手动作里最孤立刺激股四头肌的一个。',
    cuesEn: [
      'Hold a support; rise onto the toes as the knees go forward.',
      'Keep hips open — the body is a straight plank from knees to shoulders.'
    ],
    cuesZh: ['扶住支撑物，膝盖前移时脚跟抬起。', '髋保持打开——从膝到肩是一块直板。'],
    mistakesEn: [
      'Folding at the hips into a normal squat.',
      'Dropping fast into the bottom.'
    ],
    mistakesZh: ['髋部折叠变成普通深蹲。', '快速砸到底部。'],
    progEn:
        'Less support from the hands, then a light plate held at the chest.',
    progZh: '手扶得更少，再到胸前抱一片轻杠铃片。',
    regEn:
        'Reverse Nordic curls, or a shallow range with both hands on a rack.',
    regZh: '先做反向北欧弯举，或双手扶架子做小幅度。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '8-12',
    defRest: 90,
  ),
  Exercise(
    id: 'reverse_nordic',
    nameEn: 'Reverse Nordic Curl',
    nameZh: '反向北欧弯举',
    category: 'bodyweight',
    muscles: ['quads'],
    difficulty: 2,
    descEn:
        'Kneel tall and lean back from the knees with a straight body, then pull yourself back up with the quads. A long-range quad stretch under load.',
    descZh: '高跪姿，身体保持笔直从膝盖处向后倒，再用股四头肌拉回来。负重下的大行程股四头拉伸。',
    cuesEn: [
      'Squeeze the glutes so the hips never bend.',
      'Lower slowly; go only as far as you can return from.'
    ],
    cuesZh: ['夹紧臀部，髋全程不弯。', '慢慢向后倒，只倒到能自己拉回来的位置。'],
    mistakesEn: [
      'Sitting back onto the heels instead of leaning.',
      'Arching the lower back.'
    ],
    mistakesZh: ['坐向脚跟而不是整体后倾。', '腰部反弓。'],
    progEn: 'Hold a light plate at the chest, or pause at the lowest point.',
    progZh: '胸前抱一片轻杠铃片，或在最低点停顿。',
    regEn: 'Hold a band anchored in front, or keep the range small.',
    regZh: '握住前方固定的弹力带，或缩小幅度。',
    contraindications: ['knee'],
    defSets: 3,
    defReps: '6-10',
    defRest: 90,
  ),
  Exercise(
    id: 'clamshell',
    nameEn: 'Clamshell',
    nameZh: '蚌式开合',
    category: 'bodyweight',
    muscles: ['abductors', 'glutes'],
    difficulty: 1,
    descEn:
        'Lie on your side with knees bent and feet together; open the top knee like a clam. Wakes up the outer hip that keeps knees tracking straight.',
    descZh: '侧卧，屈膝并拢双脚，像贝壳一样打开上面的膝盖。唤醒让膝盖走直线的臀外侧肌群。',
    cuesEn: [
      'Feet stay together; only the knee lifts.',
      'Pelvis stays stacked — do not roll backward to lift higher.'
    ],
    cuesZh: ['双脚贴紧，只有膝盖打开。', '骨盆保持叠放——别为了开得更高往后倒。'],
    mistakesEn: [
      'Rolling the hips back.',
      'Using momentum instead of a slow squeeze.'
    ],
    mistakesZh: ['髋部往后翻。', '靠惯性甩而不是慢慢夹紧。'],
    progEn: 'Add a mini band above the knees.',
    progZh: '膝盖上方套迷你弹力带。',
    regEn: 'Fewer reps with a 2 s hold at the top.',
    regZh: '减少次数，顶端停 2 秒。',
    defSets: 2,
    defReps: '15-20',
    defRest: 45,
  ),
  Exercise(
    id: 'fire_hydrant',
    nameEn: 'Fire Hydrant',
    nameZh: '消防栓式抬腿',
    category: 'bodyweight',
    muscles: ['abductors', 'glutes'],
    difficulty: 1,
    descEn:
        'On all fours, lift one bent knee out to the side. Trains the hip to move sideways, which squats and lunges never do.',
    descZh: '四足跪姿，一条屈膝的腿向侧面抬起。训练髋部的侧向发力，这是深蹲和弓步练不到的。',
    cuesEn: [
      'Keep the knee bent at 90 degrees and lift from the hip.',
      'Shoulders and hips stay level; the spine does not twist.'
    ],
    cuesZh: ['膝盖保持 90 度，从髋发力抬起。', '肩和髋保持水平，脊柱不扭转。'],
    mistakesEn: [
      'Tilting the whole torso to lift higher.',
      'Rushing the lowering.'
    ],
    mistakesZh: ['整个躯干歪过去换取更高的高度。', '下落太快。'],
    progEn: 'Mini band above the knees, or a 2 s pause at the top.',
    progZh: '膝盖上方套迷你弹力带，或顶端停 2 秒。',
    regEn: 'Smaller lift, focusing on keeping the hips still.',
    regZh: '抬低一点，专注于髋部不动。',
    defSets: 2,
    defReps: '12-15',
    defRest: 45,
  ),
  Exercise(
    id: 'side_lying_leg_raise',
    nameEn: 'Side-Lying Leg Raise',
    nameZh: '侧卧抬腿',
    category: 'bodyweight',
    muscles: ['abductors', 'glutes'],
    difficulty: 1,
    descEn:
        'Lie on your side and lift the straight top leg toward the ceiling. Simple, and the outer hip burns within a set.',
    descZh: '侧卧，把伸直的上腿朝天花板抬起。很简单，一组之内臀外侧就会发酸。',
    cuesEn: [
      'Toes point forward or slightly down, not up.',
      'Lift from the hip, lower slowly, never let the leg rest.'
    ],
    cuesZh: ['脚尖朝前或略微朝下，不要朝上。', '从髋发力抬起，慢慢放下，腿不着地。'],
    mistakesEn: [
      'Rolling the hips back and using the hip flexors.',
      'Swinging the leg.'
    ],
    mistakesZh: ['髋往后翻，变成髂腰肌发力。', '甩腿。'],
    progEn: 'Ankle weight or a band around the ankles.',
    progZh: '脚踝加沙袋或套弹力带。',
    regEn: 'Bend the bottom knee for balance and shorten the range.',
    regZh: '下腿屈膝保持平衡，缩小幅度。',
    defSets: 2,
    defReps: '12-15',
    defRest: 45,
  ),
  Exercise(
    id: 'frog_pump',
    nameEn: 'Frog Pump',
    nameZh: '蛙式臀桥',
    category: 'bodyweight',
    muscles: ['glutes', 'adductors'],
    difficulty: 1,
    descEn:
        'Glute bridge with the soles of the feet together and knees open. The short range and open hips keep everything on the glutes.',
    descZh: '双脚脚掌相对、膝盖打开的臀桥。短行程和外展的髋让刺激全部留在臀部。',
    cuesEn: [
      'Tuck the chin and pump the hips up with a hard squeeze.',
      'Feet stay together; push through the outer edges.'
    ],
    cuesZh: ['收下巴，用力夹臀把髋顶起。', '双脚贴紧，用脚的外侧发力。'],
    mistakesEn: [
      'Arching the lower back at the top.',
      'Letting the knees drift together.'
    ],
    mistakesZh: ['顶端腰部反弓。', '膝盖并拢。'],
    progEn: 'Hold a dumbbell on the hips; high reps still apply.',
    progZh: '髋上放一只哑铃，依然做高次数。',
    regEn: 'Fewer reps with a slower tempo.',
    regZh: '减少次数，放慢节奏。',
    defSets: 2,
    defReps: '20-30',
    defRest: 45,
  ),
  Exercise(
    id: 'sliding_leg_curl',
    nameEn: 'Sliding Leg Curl',
    nameZh: '滑行腿弯举',
    category: 'bodyweight',
    muscles: ['hamstrings', 'glutes'],
    difficulty: 2,
    descEn:
        'From a glute bridge, slide the heels out until the legs are straight and curl them back in, hips up the whole time. A hamstring curl with a towel and a smooth floor.',
    descZh: '从臀桥开始，脚跟向外滑到双腿伸直再弯回来，髋部全程不落。一条毛巾加光滑地面就是腿弯举。',
    cuesEn: [
      'Hips stay high as the heels slide out.',
      'Curl back by dragging the heels, not by lifting the hips first.'
    ],
    cuesZh: ['脚跟外滑时髋保持高位。', '靠脚跟往回拖来弯腿，而不是先抬髋。'],
    mistakesEn: [
      'Hips dropping as the legs extend.',
      'Only sliding half way out.'
    ],
    mistakesZh: ['腿伸出去时髋掉下来。', '只滑出一半。'],
    progEn: 'Single-leg slides.',
    progZh: '单腿滑行。',
    regEn: 'Only the eccentric: slide out, then drop the hips and reset.',
    regZh: '只做离心：滑出去，然后髋落地重新开始。',
    defSets: 3,
    defReps: '8-12',
    defRest: 75,
  ),
  Exercise(
    id: 'single_leg_calf_raise',
    nameEn: 'Single-Leg Calf Raise',
    nameZh: '单腿提踵',
    category: 'bodyweight',
    muscles: ['calves'],
    difficulty: 2,
    descEn:
        'Calf raise on one leg with the heel off a step. Twice the load of the two-leg version and a full stretch at the bottom.',
    descZh: '单腿站在台阶边缘做提踵，脚跟悬空。负荷是双腿版的两倍，底部还有完整拉伸。',
    cuesEn: [
      'Drop the heel below the step and pause, then rise as high as you can.',
      'Fingertips on a wall for balance only.'
    ],
    cuesZh: ['脚跟降到台阶以下停一下，再尽量踮高。', '指尖扶墙只为平衡。'],
    mistakesEn: ['Bouncing out of the stretch.', 'Bending the knee to help.'],
    mistakesZh: ['在拉伸位借弹力。', '屈膝借力。'],
    progEn: 'Hold a dumbbell on the working side.',
    progZh: '同侧手持哑铃。',
    regEn: 'Two-leg calf raises on the step.',
    regZh: '台阶上双腿提踵。',
    defSets: 3,
    defReps: '10-15',
    defRest: 60,
  ),
  Exercise(
    id: 'tibialis_raise',
    nameEn: 'Tibialis Raise',
    nameZh: '胫骨前肌提举',
    category: 'bodyweight',
    muscles: ['calves'],
    difficulty: 1,
    descEn:
        'Lean back against a wall with the feet out in front and lift the toes toward the shins. Trains the front of the shin — the brake the knee relies on when running and landing.',
    descZh: '背靠墙，双脚放在前方，把脚尖朝小腿方向勾起。练小腿前侧——跑步和落地时膝盖依赖的刹车。',
    cuesEn: [
      'Heels stay down; lift the toes as high as possible.',
      'The further the feet are from the wall, the harder it is.'
    ],
    cuesZh: ['脚跟不动，脚尖尽量勾高。', '脚离墙越远越难。'],
    mistakesEn: [
      'Bending the knees to cheat the toes up.',
      'Dropping the toes instead of lowering them.'
    ],
    mistakesZh: ['屈膝帮脚尖抬起。', '脚尖直接落下而不是控制着放。'],
    progEn: 'Feet further out, then a dumbbell across the toes.',
    progZh: '脚放得更远，再把哑铃压在脚背上。',
    regEn: 'Seated, lifting the toes with the feet flat.',
    regZh: '坐姿，脚平放勾脚尖。',
    defSets: 2,
    defReps: '15-25',
    defRest: 45,
  ),
];
