// Copyright (c) 2026 Qore
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import 'dark_button.dart';

/// 「分享结果」按钮：通过 [RepaintBoundary] 截图结果区，**合成主题背景后**分享 PNG。
///
/// 截图区通常不含不透明背景（半透明面板），直接分享会让文字「浮空」、违和。
/// 本组件在截图上叠加一层主题背景（玄黑 / 浅米渐变 + 鎏金细边），保证分享图
/// 美观且贴合 app 主题。
///
/// 用法：结果区外层包 `RepaintBoundary(key: boundaryKey, child: ...)`，
/// 与 [CopyResultButton] 并列放置本按钮，传入同一 `boundaryKey`。
class ShareResultButton extends StatelessWidget {
  final GlobalKey boundaryKey;
  final bool enabled;
  final String? fallbackText;

  const ShareResultButton({
    super.key,
    required this.boundaryKey,
    this.enabled = true,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return DarkButton(
      icon: Icon(Icons.ios_share, color: c.textPrimary, size: 18),
      text: '分享结果',
      onPressed: enabled ? () => _share(context) : null,
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      final boundaryObj = boundaryKey.currentContext?.findRenderObject();
      if (boundaryObj is! RenderRepaintBoundary) {
        _fallbackShare();
        return;
      }
      final raw = await boundaryObj.toImage(pixelRatio: 2.0);
      if (!context.mounted) {
        _fallbackShare();
        return;
      }
      final isLight = Theme.of(context).brightness == Brightness.light;
      final composed = await _composeWithBackground(raw, isLight: isLight);
      final byteData = await composed.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        _fallbackShare();
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      final tmpDir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tmpDir.path}/jeenith_share_$ts.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      _fallbackShare();
    }
  }

  /// 在截图上合成主题背景渐变 + 鎏金细边。
  Future<ui.Image> _composeWithBackground(
    ui.Image raw, {
    required bool isLight,
  }) async {
    final w = raw.width;
    final h = raw.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

    // 主题背景渐变（玄黑 / 浅米，与 app 一致）
    final bgTop = isLight ? AppColorsLight.bgOuter : AppColors.bgInner;
    final bgBottom = isLight ? AppColorsLight.bg : AppColors.bg;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgTop, bgBottom],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 画截图内容
    canvas.drawImage(raw, Offset.zero, Paint());

    // 鎏金细边（点睛，呼应主题）
    final borderPaint = Paint()
      ..color = (isLight ? AppColorsLight.gold : AppColors.gold)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect.deflate(1), borderPaint);

    // 品牌署名（底部居中小金字，分享图自带品牌传播）
    final goldColor = isLight ? AppColorsLight.gold : AppColors.gold;
    final tp = TextPainter(
      text: TextSpan(
        text: '志极 Jeenith · 叩问本心',
        style: TextStyle(
          color: goldColor.withValues(alpha: 0.85),
          fontSize: AppFontSize.shareBranding(w.toDouble()),
          fontFamily: AppFonts.serif,
          letterSpacing: AppLetterSpacing.shareBranding(w.toDouble()),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((w - tp.width) / 2, h - tp.height - w.toDouble() * 0.028),
    );
    tp.dispose();

    final picture = recorder.endRecording();
    return picture.toImage(w, h);
  }

  Future<void> _fallbackShare() async {
    if (fallbackText != null && fallbackText!.isNotEmpty) {
      await Share.share(fallbackText!);
    }
  }
}
