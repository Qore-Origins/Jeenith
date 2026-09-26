// Copyright (c) 2026 Qore
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/app/restart_controller.dart';
import 'core/config/platform_info.dart';
import 'data/yijing/hexagram_texts.dart';

/// 窗口边缘为系统任务栏与桌面留出的空间。
const _kVerticalMargin = 40.0;
const _kHorizontalMargin = 48.0;

/// 桌面窗口目标尺寸上限与宽屏比例。
const _kMaxWindowWidth = 1440.0;
const _kMaxWindowHeight = 960.0;
const _kDesktopAspect = 1.45;
const _kMinimumWindowWidth = 860.0;
const _kMinimumWindowHeight = 560.0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformInfo.isDesktop) {
    await windowManager.ensureInitialized();

    final display = await ScreenRetriever.instance.getPrimaryDisplay();
    // screen_retriever 的 Display.size / visibleSize 已经是逻辑像素
    // （DPI-aware），不能再除以 scaleFactor，否则会把窗口算得过小。
    // visibleSize 已扣任务栏/Dock，没有则回退 size。
    final logical = display.visibleSize ?? display.size;
    final screenH = logical.height;

    // 在当前显示器可用空间内创建宽屏工作区，不模拟手机竖屏比例。
    final availableWidth = math
        .max(0.0, logical.width - _kHorizontalMargin)
        .toDouble();
    final availableHeight = math
        .max(0.0, screenH - _kVerticalMargin)
        .toDouble();
    final targetHeight = math
        .min(availableHeight, _kMaxWindowHeight)
        .toDouble();
    final targetWidth = math
        .min(
          math.min(availableWidth, _kMaxWindowWidth),
          targetHeight * _kDesktopAspect,
        )
        .toDouble();

    final windowOptions = WindowOptions(
      size: Size(targetWidth, targetHeight),
      minimumSize: Size(
        math.min(targetWidth, _kMinimumWindowWidth).toDouble(),
        math.min(targetHeight, _kMinimumWindowHeight).toDouble(),
      ),
      center: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }

  // 预加载 64 卦卦辞爻辞到内存（周易/梅花结果页同步查询用）
  await HexagramTexts.load();

  runApp(const _JeenithRoot());
}

/// 根 widget：监听 [RestartController]，重启时更换 [ProviderScope] 的 key，
/// 使整个 widget 树（含所有 Riverpod 状态）从已更新的 SharedPreferences
/// 重新初始化（v2.11.0）。
class _JeenithRoot extends StatefulWidget {
  const _JeenithRoot();

  @override
  State<_JeenithRoot> createState() => _JeenithRootState();
}

class _JeenithRootState extends State<_JeenithRoot> {
  @override
  void initState() {
    super.initState();
    RestartController.instance.addListener(_onRestart);
  }

  @override
  void dispose() {
    RestartController.instance.removeListener(_onRestart);
    super.dispose();
  }

  void _onRestart() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey('scope-${RestartController.instance.value}'),
      child: const JeenithApp(),
    );
  }
}
