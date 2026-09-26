// Copyright (c) 2026 Qore
import 'package:jeenith/core/theme/app_theme.dart';

import '../../../core/divination/divination_result.dart';
import '../data/palaces.dart';

/// 综合吉凶分级（1:1 移植自 Python main.py overall_verdict）。
/// score = 三宫 level 之和（0-15），按阈值分级。
Verdict overallVerdict(List<int> lands) {
  final score = lands.map((i) => palaces[i].level).fold(0, (a, b) => a + b);
  if (score >= 12) {
    return const Verdict(
        '大吉之象', AppColors.woodGlow, '三宫皆吉，青龙朱雀拱照，事事昌荣，所求如愿，宜把握良机。');
  }
  if (score >= 9) {
    return const Verdict(
        '吉兆之象', AppColors.waterGlow, '吉多于凶，整体顺遂，虽有小碍亦能化解，可放心行事。');
  }
  if (score >= 6) {
    return const Verdict(
        '平稳之象', AppColors.yang, '吉凶参半，平中藏机，宜审时度势，稳中求进，不可冒进。');
  }
  if (score >= 3) {
    return const Verdict(
        '欠顺之象', AppColors.earthGlow, '凶多于吉，事多迟滞，宜耐心守成，避口舌是非，缓图则吉。');
  }
  return const Verdict(
      '凶险之象', AppColors.fireGlow, '三宫多凶，白虎腾蛇作祟，诸事不宜，宜静守修德，待时而动。');
}
