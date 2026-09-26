// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// 使用手册页：基础使用方法、时辰边界 Q&A、历法体系说明、实操提醒。
///
/// 解决两类常见困惑：
/// 1. 出生时间在时辰边界上时如何取舍（辰时 vs 巳时、8 还是 9）；
/// 2. 不同术数采用的历法体系不同（农历 vs 节气干支历），避免混用导致排盘错误。
class ManualPage extends StatefulWidget {
  const ManualPage({super.key});

  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('使 用 手 册'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _section('◆ 基础使用', [
            _numItem(1, '单一卜算术起卦', '第一次问大致的问题，第二次问细致的问题。'),
            _numItem(2, '多卜算术组合使用', '先用一种卜算术起卦问大致的问题，再用另外一种起卦问细节上的问题。'),
            _paragraph('3. 可以将卦象的完整截图和问题一并发送给 AI，也可以自己查资料。'),
            _paragraph('4. 点击起卦按钮前，心里默念问题，集中注意力，注意力达到顶点的一刹那起卦。'),
          ]),
          _section('◆ 时辰边界 Q&A', [
            _paragraph('古时以「时辰」计时，一时辰合现代两小时。各时辰与现代小时的对应：',
                emphasis: true),
            _paragraph(
                '子 23-1 · 丑 1-3 · 寅 3-5 · 卯 5-7 · 辰 7-9 · 巳 9-11 · '
                '午 11-13 · 未 13-15 · 申 15-17 · 酉 17-19 · 戌 19-21 · 亥 21-23'),
            Divider(
                color: c.goldBorder, height: 18),
            _qa(
              '我的公历出生年月日是 2006 年 12 月 3 日上午 8:40-9:00，母亲 9:15 左右出手术室，我在她前面出。到底是辰时还是巳时？',
              '8:40-9:00 之间出生，整体落在辰时（7-9 点）范围内。即便 9:00 整点出生，仍属辰时；'
              '巳时从 9:00 之后才开始。因此你的时辰应取「辰时」。\n'
              '关键规则：时辰起止按「左闭右开」——9:00 整点属于辰时的最后一刻，'
              '巳时从 9:00 之后才开始。若你确定是 8:58 出生，毫无疑问是辰时。',
            ),
            _qa(
              '假如是 8:58 分出生，在填写公历出生日期时是填 8 还是 9？',
              '公历日期中时分秒是连续的，按实际分钟数填写即可——「8 时 58 分」，'
              '不需要四舍五入到整数点。\n'
              '所谓「填 8 还是 9」的困惑主要出现在两种场景：\n'
              '1. 紫微斗数：部分老排盘软件只接受「时辰」输入（子/丑/寅…），此时直接选「辰时」即可，工具会自动换算；\n'
              '2. 奇门遁甲：要求精确到「时辰」，需看具体落在哪个时辰区间。8:58 落在辰时（7-9 点）区间内，时辰就是辰时。\n'
              '现代排盘工具都能接受精确分钟输入，建议尽量填准确时间，避免四舍五入。',
            ),
            _qa(
              '时辰换算时遇到整点（如 9:00 整）该归哪个时辰？',
              '通用规则：时辰区间采用左闭右开。[7:00, 9:00) 属于辰时，[9:00, 11:00) 属于巳时。\n'
              '即 9:00:00 整点出生，按巳时算；8:59:59 仍是辰时。\n'
              '不过实务中相差几秒不至于影响排盘大局，不必过分纠结。',
            ),
            _qa(
              '出生时间不确定怎么办？',
              '尽量向家长核对出生时间。如果实在记不清，可以采用以下策略：\n'
              '1. 取最可能的时辰排盘，再结合过往经历反推（命理学称之为「定盘」）；\n'
              '2. 同时排两个相邻时辰的盘，比较哪个更贴合实际经历；\n'
              '3. 命理推算本就有容错空间，相邻时辰的盘象差异通常体现在个别宫位上，整体格局相近。',
            ),
          ]),
          _section('◆ 历法体系区分', [
            _paragraph('结论：不能说「全部都只用农历」。传统术数分两大底层历法体系：',
                emphasis: true),
            _paragraph('古代民用记录日期确实用农历，但专业卜算、命理分两套底层逻辑：'
                '一套看农历月相，一套看节气太阳历（干支历）。'),
            const SizedBox(height: 6),
            _subTitle('1. 以农历（阴历朔望月）为基准的术数'),
            _paragraph('这类术数看「正月初一换年、农历初一至三十为日、农历月份」，'
                '不看立春节气。代表性术数：'),
            _bullet('紫微斗数：古法完全以农历年月日排盘，正月初一换年，几月就是几月；'),
            _bullet('小六壬、抽签、民间看黄道吉日、嫁娶择日：起课、定吉凶直接用农历日期；'),
            _bullet('铁板神数、部分民间盲派简易算命：依托农历生辰起数。'),
            const SizedBox(height: 6),
            _subTitle('2. 以节气干支历（太阳历）为核心的正统卜算术'),
            _paragraph('这类只认「二十四节气」划分年月，与农历初几无关，'
                '是古代官方、道家正宗卜算体系：'),
            _bullet('四柱八字（子平术）：立春换年、节气换月。哪怕农历正月，只要没到立春，'
                '依旧算上一年；农历腊月过了立春，就算新年；'),
            _bullet('三式绝学（奇门遁甲、大六壬、太乙神数）：古代皇家顶级卜术，'
                '完全以节气定局、换月将，和农历日期无关；'),
            _bullet('六爻纳甲、梅花易数（时间起卦）：断卦旺衰、流年吉凶以立春、节气分界，'
                '不用农历正月初一做新年起点。'),
            const SizedBox(height: 6),
            _subTitle('3. 为什么大家普遍有「算卦都用农历」的错觉'),
            _bullet('古代没有公历，所有人记录生日、办事日期全写农历，'
                '流传到现代民间算命自然沿用农历；'),
            _bullet('紫微斗数、抽签这类普通人接触最多的术数刚好是纯农历体系，'
                '大众印象最深；'),
            _bullet('现代排盘软件简化操作：输入公历后台会自动换算农历/干支历，'
                '普通人看不到底层历法逻辑，误以为「全部靠农历」。'),
          ]),
          _section('◆ 各术数历法归属', [
            _paragraph('简单区分记忆：', emphasis: true),
            _bullet('看「人一辈子命运」：紫微斗数 → 农历；四柱八字 → 节气干支历；'),
            _bullet('看「短期遇事占卜」（求财、考试、出行）：奇门、六壬、六爻、梅花 → 节气干支历；'),
            _bullet('民间日常小事测算（小六壬、求签） → 农历。'),
            const SizedBox(height: 8),
            _paragraph('志极各术数的历法归属表：', emphasis: true),
            _calendarTable(),
          ]),
          _section('◆ 实操提醒', [
            _paragraph('不管哪一类术数，现代都可以填公历生日，工具会自动转换；'
                '但手工排盘必须分清体系，混用历法会全盘出错。',
                emphasis: true),
            const SizedBox(height: 6),
            _bullet('本 App 所有时间输入均接受公历，后台会根据所选术数自动换算到对应历法；'),
            _bullet('历史记录里保存的「时间」是公历起卦时间，便于回溯；'),
            _bullet('若需手工排盘参考，请先查清该术数属于农历体系还是节气干支历体系；'),
            _bullet('紫微斗数即使农历正月十五排盘，若未到立春，年份仍属上一年——这是初学者最易混淆之处；'),
            _bullet('四柱八字即使农历腊月初排盘，若已过立春，年份仍属下一年——同上易错点。'),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> body) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: c.gold,
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: AppLetterSpacing.label)),
          const SizedBox(height: 8),
          _panel(body),
        ],
      ),
    );
  }

  Widget _panel(List<Widget> children) {
    final c = AppClr.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(AppRadius.panelCompact),
        border: Border.all(color: c.goldBorder),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _subTitle(String text) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(text,
          style: TextStyle(
              color: c.goldBright,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold)),
    );
  }

  Widget _paragraph(String text, {bool emphasis = false}) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              color: emphasis ? c.goldBright : c.textBody,
              fontSize: AppFontSize.label,
              height: AppLineHeight.reading,
              fontWeight: emphasis ? AppFontWeight.bold : AppFontWeight.regular)),
    );
  }

  Widget _bullet(String text) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('· ',
              style: TextStyle(color: c.gold, fontSize: AppFontSize.label)),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: c.textBody, fontSize: AppFontSize.label, height: AppLineHeight.body)),
          ),
        ],
      ),
    );
  }

  Widget _numItem(int n, String title, String body) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n. $title',
              style: TextStyle(
                  color: c.goldBright,
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold)),
          const SizedBox(height: 2),
          Text(body,
              style: TextStyle(
                  color: c.textBody, fontSize: AppFontSize.label, height: AppLineHeight.body)),
        ],
      ),
    );
  }

  Widget _qa(String question, String answer) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q：',
                  style: TextStyle(
                      color: c.gold,
                      fontSize: AppFontSize.label,
                      fontWeight: AppFontWeight.bold)),
              Expanded(
                child: Text(question,
                    style: TextStyle(
                        color: c.goldBright,
                        fontSize: AppFontSize.label,
                        fontWeight: AppFontWeight.bold,
                        height: AppLineHeight.body)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A：',
                  style: TextStyle(
                      color: c.gold,
                      fontSize: AppFontSize.label,
                      fontWeight: AppFontWeight.bold)),
              Expanded(
                child: Text(answer,
                    style: TextStyle(
                        color: c.textBody,
                        fontSize: AppFontSize.label,
                        height: AppLineHeight.reading)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarTable() {
    final c = AppClr.of(context);
    final rows = <List<String>>[
      ['术数', '历法体系', '换年节点'],
      ['紫微斗数', '农历', '正月初一'],
      ['小六壬', '农历', '正月初一'],
      ['抽签求签', '农历', '正月初一'],
      ['奇门遁甲', '节气干支历', '立春'],
      ['大六壬', '节气干支历', '立春'],
      ['梅花易数', '节气干支历', '立春'],
      ['周易卦象', '节气干支历', '立春'],
      ['风水罗盘', '不依赖历法', '—'],
      ['测字', '不依赖历法', '—'],
      ['掷筊', '不依赖历法', '—'],
    ];
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: c.goldBorder, width: 0.6),
      children: [
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i == 0
                  ? c.gold.withValues(alpha: 0.12)
                  : AppColors.transparent,
            ),
            children: [
              for (final cell in rows[i])
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(cell,
                      style: TextStyle(
                          color: i == 0
                              ? c.goldBright
                              : c.textBody,
                          fontSize: AppFontSize.caption,
                          fontWeight:
                              i == 0 ? AppFontWeight.bold : AppFontWeight.regular,
                          height: AppLineHeight.navigation)),
                ),
            ],
          ),
      ],
    );
  }
}
