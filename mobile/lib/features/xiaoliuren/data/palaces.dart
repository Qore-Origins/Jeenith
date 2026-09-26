// Copyright (c) 2026 Qore
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:jeenith/core/theme/app_theme.dart';

/// 小六壬六宫数据模型（1:1 搬运自 Python main.py PALACES）。
@immutable
class Palace {
  final String name;
  final String wuxing;   // 五行
  final String shen;     // 六神
  final String fangwei;  // 方位
  final String jixiong;  // 吉凶文字
  final int level;       // 吉凶等级 0-5（5大吉 ... 0大凶）
  final Color color;     // 五行主色
  final Color glow;      // 亮色
  final String poem;     // 诗诀
  final String meaning;  // 含义
  final Map<String, String> detail; // 七维断辞

  const Palace({
    required this.name,
    required this.wuxing,
    required this.shen,
    required this.fangwei,
    required this.jixiong,
    required this.level,
    required this.color,
    required this.glow,
    required this.poem,
    required this.meaning,
    required this.detail,
  });
}

/// 六宫顺序（顺时针）：大安→留连→速喜→赤口→小吉→空亡（索引 0-5）。
const palaces = <Palace>[
  Palace(
    name: '大安', wuxing: '木', shen: '青龙', fangwei: '东方',
    jixiong: '大吉', level: 5,
    color: AppColors.wood, glow: AppColors.woodGlow,
    poem: '大安事事昌，求谋主荣光。',
    meaning: '万事安定，青龙主事。如春木生发，平和顺遂、稳重安泰。占事主平稳、有贵人、宜静守待时。',
    detail: {
      '求谋': '可成，宜稳进，贵人扶助。',
      '失物': '在东方，可寻，未远走。',
      '出行': '平安，路途顺遂。',
      '婚姻': '和合美满，可成。',
      '财利': '平稳有得，不宜贪。',
      '行人': '未动身，安坐家中。',
      '疾病': '无碍，宜静养。',
    },
  ),
  Palace(
    name: '留连', wuxing: '水', shen: '勾陈', fangwei: '东南',
    jixiong: '小凶', level: 1,
    color: AppColors.water, glow: AppColors.waterGlow,
    poem: '留连事难成，谋望皆迟滞。',
    meaning: '事多拖延纠缠，勾陈主滞。如水停滞不流，反复难决。占事主迟缓、口舌、暗昧不明，需耐心等待。',
    detail: {
      '求谋': '难成，事多拖延反复。',
      '失物': '在南方或东南，迟寻可得。',
      '出行': '有阻，宜缓行。',
      '婚姻': '有阻隔，迟则成。',
      '财利': '迟得，被事纠缠。',
      '行人': '在外盘桓，未即归。',
      '疾病': '缠绵难愈，宜久治。',
    },
  ),
  Palace(
    name: '速喜', wuxing: '火', shen: '朱雀', fangwei: '南方',
    jixiong: '中吉', level: 4,
    color: AppColors.fire, glow: AppColors.fireGlow,
    poem: '速喜喜来临，求财到禄位。',
    meaning: '喜事速至，朱雀报信。如烈火烹油，迅捷明快。占事主有喜讯、速成、得财、贵人来助。',
    detail: {
      '求谋': '速成，有喜讯捷报。',
      '失物': '在西南方，速寻可得。',
      '出行': '有喜相遇，顺利。',
      '婚姻': '佳偶天成，速定。',
      '财利': '速得，意外之财。',
      '行人': '立至，已在归途。',
      '疾病': '乍发乍愈，勿忧。',
    },
  ),
  Palace(
    name: '赤口', wuxing: '金', shen: '白虎', fangwei: '西方',
    jixiong: '大凶', level: 0,
    color: AppColors.metal, glow: AppColors.metalGlow,
    poem: '赤口主口舌，是非凶祸生。',
    meaning: '口舌争讼，白虎主凶。如秋金肃杀，冲突锋利。占事主官非、争吵、损伤、破财，宜谨慎防备。',
    detail: {
      '求谋': '不利，有口舌争执。',
      '失物': '难寻，恐已毁失。',
      '出行': '有阻，防口舌意外。',
      '婚姻': '口舌不和，难成。',
      '财利': '破财，宜守不宜动。',
      '行人': '有阻，途中生变。',
      '疾病': '急且重，宜速医。',
    },
  ),
  Palace(
    name: '小吉', wuxing: '水', shen: '玄武', fangwei: '北方',
    jixiong: '小吉', level: 3,
    color: AppColors.waterDeep, glow: AppColors.waterDeepGlow,
    poem: '小吉最相宜，诸事皆和合。',
    meaning: '小有吉利，玄武藏机。如水流平稳，柔顺通达。占事主小顺、和合、阴人相助，凡事小有成就。',
    detail: {
      '求谋': '可成，和顺有得。',
      '失物': '在北方，阳人来报。',
      '出行': '顺遂，得人助。',
      '婚姻': '和合，媒人助成。',
      '财利': '小有进益，平稳。',
      '行人': '将归，喜信将至。',
      '疾病': '渐愈，无大碍。',
    },
  ),
  Palace(
    name: '空亡', wuxing: '土', shen: '腾蛇', fangwei: '中央',
    jixiong: '平凶', level: 2,
    color: AppColors.earth, glow: AppColors.earthGlow,
    poem: '空亡事不祥，凡谋皆落空。',
    meaning: '虚无落空，腾蛇主惊。如浮云无定，事多虚惊。占事主落空、无果、虚惊一场，宜重新谋划。',
    detail: {
      '求谋': '不成，落空无果。',
      '失物': '难寻，恐已失。',
      '出行': '落空，徒劳无功。',
      '婚姻': '不成，虚情假意。',
      '财利': '无得，竹篮打水。',
      '行人': '有灾，信息全无。',
      '疾病': '有反复，难根治。',
    },
  ),
];

const detailKeys = ['求谋', '失物', '出行', '婚姻', '财利', '行人', '疾病'];
