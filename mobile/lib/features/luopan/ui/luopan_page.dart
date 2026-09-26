// Copyright (c) 2026 Qore
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_case_launch_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/platform_info.dart';
import '../../../shared/widgets/ai_case_launch_button.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../daliuren/algorithm/divine.dart' show shan24;
import '../sensor/compass_provider.dart';

/// 24 山对应的方位标签（顺时针，每 15° 一山）。
const _directionLabels = [
  '北',
  '北',
  '北',
  '东北',
  '东北',
  '东北',
  '东',
  '东',
  '东',
  '东南',
  '东南',
  '东南',
  '南',
  '南',
  '南',
  '西南',
  '西南',
  '西南',
  '西',
  '西',
  '西',
  '西北',
  '西北',
  '西北',
];

/// 八卦四隅位（巽艮坤乾）的标号。
const _baguaIdx = {3: '巽', 9: '艮', 15: '坤', 21: '乾'};

class LuopanPage extends ConsumerStatefulWidget {
  const LuopanPage({super.key});
  @override
  ConsumerState<LuopanPage> createState() => _LuopanPageState();
}

class _LuopanPageState extends ConsumerState<LuopanPage> {
  bool _active = false;

  @override
  void dispose() {
    if (_active) {
      ref.read(compassProvider.notifier).stop();
    }
    super.dispose();
  }

  void _toggle() {
    if (!PlatformInfo.isAndroid) return;
    final notifier = ref.read(compassProvider.notifier);
    if (_active) {
      notifier.stop();
      setState(() => _active = false);
    } else {
      notifier.start();
      setState(() => _active = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(compassProvider);
    final azimuth = reading?.azimuth ?? 0.0;
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          children: [
            const Text('风水罗盘', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '二 十 四 山',
              style: TextStyle(
                fontSize: AppFontSize.micro,
                color: c.textSubtitle,
                letterSpacing: AppLetterSpacing.decorative,
              ),
            ),
          ],
        ),
      ),
      body: PlatformInfo.isAndroid
          ? _buildAndroidBody(azimuth, hasReading: reading != null)
          : _buildDesktopPlaceholder(),
    );
  }

  Widget _buildAndroidBody(double azimuth, {required bool hasReading}) {
    final c = AppClr.of(context);
    final shanIdx = ((azimuth + 7.5) ~/ 15) % 24;
    final shan = shan24[shanIdx];
    final dir = _directionLabels[shanIdx];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DecorativePanel(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReading(
                    '方位角',
                    '${azimuth.toStringAsFixed(1)}°',
                    c.goldBright,
                  ),
                  _buildReading('坐山', shan, c.fireGlow),
                  _buildReading('方位', dir, c.woodGlow),
                ],
              ),
              const SizedBox(height: 10),
              GoldButton(text: _active ? '停止' : '开始', onPressed: _toggle),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DecorativePanel(
          padding: const EdgeInsets.all(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _LuopanPainter(
                azimuth: azimuth,
                active: _active,
                clr: c,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '提示：将设备水平放置并远离金属物体以提高精度。',
          style: TextStyle(color: c.textMeta, fontSize: AppFontSize.caption),
          textAlign: TextAlign.center,
        ),
        if (hasReading)
          Center(
            child: AiCaseLaunchButton(
              launchContext: AiCaseLaunchContext(
                techId: 'luopan',
                techName: '风水罗盘',
                summary: '$dir · $shan',
                detail:
                    '方位角：${azimuth.toStringAsFixed(1)}°\n'
                    '坐山：$shan\n方位：$dir',
                time: DateTime.now(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopPlaceholder() {
    final c = AppClr.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: c.gold, size: 64),
            const SizedBox(height: 16),
            Text(
              '罗盘功能仅支持 Android 设备',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: AppFontSize.bodyLarge,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '当前平台：${PlatformInfo.label}\n'
              '磁力计硬件在桌面端不可用，请在 Android 设备上体验。',
              style: TextStyle(color: c.textMeta, fontSize: AppFontSize.label),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReading(String label, String value, Color valueColor) {
    final c = AppClr.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: c.textMeta, fontSize: AppFontSize.caption),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: AppFontSize.metric,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 罗盘绘制器：天盘 24 山随方位反向旋转，外圈八卦四隅位固定。
class _LuopanPainter extends CustomPainter {
  final double azimuth;
  final bool active;
  final AppClr clr;

  _LuopanPainter({
    required this.azimuth,
    required this.active,
    required this.clr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.46;

    // 同心圆：外圈、24山圈、八卦圈、内圈
    final ringPaint = Paint()
      ..color = clr.goldBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, r, ringPaint);
    canvas.drawCircle(center, r * 0.85, ringPaint);
    canvas.drawCircle(center, r * 0.55, ringPaint);
    canvas.drawCircle(center, r * 0.30, ringPaint);

    // 24 等分线
    final linePaint = Paint()
      ..color = clr.gold.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var i = 0; i < 24; i++) {
      final angle = (i * 15 - 90) * math.pi / 180;
      canvas.drawLine(
        Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ),
        Offset(
          center.dx + r * 0.55 * math.cos(angle),
          center.dy + r * 0.55 * math.sin(angle),
        ),
        linePaint,
      );
    }

    // 旋转坐标系使罗盘指针固定指北（罗盘随方位反向旋转）
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-azimuth * math.pi / 180);

    // 24 山字符
    final shanTp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (var i = 0; i < 24; i++) {
      // 罗盘上山位与方位角对应：北为子(0°)，但 24 山索引 0 是壬(345°-15°)，子(0°) 是索引 1
      // 罗盘上山位的角度（顺时针从北）= i * 15 - 7.5（让"壬"位于 -7.5° 到 +7.5° 的中心为 0°？）
      // 标准罗盘：壬位于 352.5°-7.5°，子在 7.5°-22.5°，但以"子"指北时，子中心在 0°
      // 这里采用：子位 0°，癸 15°，丑 30°... 顺时针
      // 实际 shan24 = [壬, 子, 癸, ...]，子是索引 1，让子在 0°：山 i 的角度 = (i - 1) * 15
      final angle = ((i - 1) * 15 - 90) * math.pi / 180;
      final x = (r + r * 0.85) / 2 * math.cos(angle);
      final y = (r + r * 0.85) / 2 * math.sin(angle);

      final isGua = _baguaIdx.containsValue(shan24[i]);
      shanTp.text = TextSpan(
        text: shan24[i],
        style: TextStyle(
          color: isGua
              ? clr.fireGlow
              : (shan24[i] == '子' ||
                        shan24[i] == '午' ||
                        shan24[i] == '卯' ||
                        shan24[i] == '酉'
                    ? clr.goldBright
                    : clr.textBody),
          fontSize: isGua ? 13 : 12,
          fontWeight: AppFontWeight.bold,
        ),
      );
      shanTp.layout();
      shanTp.paint(canvas, Offset(x - shanTp.width / 2, y - shanTp.height / 2));
    }
    shanTp.dispose();

    // 八卦四隅位标号
    final guaTp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    // 巽(东南135°) 艮(东北45°) 坤(西南225°) 乾(西北315°)
    const guaList = ['乾', '坎', '艮', '震', '巽', '离', '坤', '兑'];
    const guaAngles = [315.0, 0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0];
    for (var i = 0; i < 8; i++) {
      final angle = (guaAngles[i] - 90) * math.pi / 180;
      final x = (r * 0.85 + r * 0.55) / 2 * math.cos(angle);
      final y = (r * 0.85 + r * 0.55) / 2 * math.sin(angle);
      guaTp.text = TextSpan(
        text: guaList[i],
        style: TextStyle(
          color: clr.waterDeepGlow,
          fontSize: AppFontSize.bodySmall,
        ),
      );
      guaTp.layout();
      guaTp.paint(canvas, Offset(x - guaTp.width / 2, y - guaTp.height / 2));
    }
    guaTp.dispose();

    canvas.restore();

    // 顶部指针（固定）
    final pointerPaint = Paint()
      ..color = clr.fire
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - r - 10)
      ..lineTo(center.dx - 6, center.dy - r + 6)
      ..lineTo(center.dx + 6, center.dy - r + 6)
      ..close();
    canvas.drawPath(path, pointerPaint);

    // 中心太极
    final centerPaint = Paint()..color = clr.gold;
    canvas.drawCircle(center, 5, centerPaint);
    final innerPaint = Paint()..color = clr.bg;
    canvas.drawCircle(center, 3, innerPaint);
  }

  @override
  bool shouldRepaint(_LuopanPainter old) =>
      azimuth != old.azimuth || active != old.active || clr.t != old.clr.t;
}
