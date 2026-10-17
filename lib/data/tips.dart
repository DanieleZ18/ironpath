library;

/// Rotating health/form tips shown during workouts (rest screen) and one
/// recovery tip on the finish screen. Bilingual pairs, terse — one line each.

class TrainingTip {
  final String en;
  final String zh;
  const TrainingTip(this.en, this.zh);
}

const List<TrainingTip> trainingTips = [
  TrainingTip(
      'Sip water between sets — small and often beats a gallon at once.',
      '组间小口补水——少量多次比一次猛灌强。'),
  TrainingTip(
      'Protein target: 1.6-2g per kg bodyweight daily. Food builds muscle; training only signals it.',
      '每天每公斤体重 1.6-2g 蛋白质。长肌肉的是食物，训练只是发信号。'),
  TrainingTip(
      'Sleep 7-9 hours — it is the strongest recovery tool there is.',
      '睡 7-9 小时——它是最强的恢复工具，没有之一。'),
  TrainingTip(
      'Lower the weight slowly. Muscles grow on the way down too.',
      '下放慢一点，肌肉在离心阶段同样在生长。'),
  TrainingTip(
      'Eat enough overall. Chronic under-eating and progress do not mix.',
      '总热量要吃够，长期节食和进步不可兼得。'),
  TrainingTip(
      'Sharp joint pain (not muscle burn) means stop, not push.',
      '关节刺痛（不是肌肉酸胀）意味着停下，不是硬撑。'),
  TrainingTip(
      'Exhale on the effort, inhale on the way down.',
      '发力呼气，还原吸气。'),
  TrainingTip(
      'Consistency beats intensity — three average weeks beat one heroic one.',
      '坚持胜过强度：三个普通周好过一个拼命周。'),
  TrainingTip(
      'Track your weights. What gets measured gets managed.',
      '记录你的重量，被测量的东西才会被管理。'),
];