// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/config/config_providers.dart';
import 'core/config/platform_info.dart';
import 'core/layout/app_breakpoints.dart';
import 'core/rng/rng_providers.dart';
import 'shared/widgets/app_desktop_window_bar.dart';
import 'shared/widgets/app_desktop_navigation.dart';
import 'router/app_router.dart';

class JeenithApp extends ConsumerStatefulWidget {
  const JeenithApp({super.key});

  @override
  ConsumerState<JeenithApp> createState() => _JeenithAppState();
}

class _JeenithAppState extends ConsumerState<JeenithApp>
    with TickerProviderStateMixin {
  /// 主题渐变动画：t=0 深色，t=1 浅色。themeMode 变化时 450ms easeInOutCubic 过渡。
  late final AnimationController _themeCtrl;
  bool _isLight = false;
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    _themeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 0,
    );
  }

  @override
  void dispose() {
    _themeCtrl.dispose();
    super.dispose();
  }

  /// 根据 themeMode + 系统亮度计算实际是否浅色主题。
  bool _effectiveLight(BuildContext context, AppConfig? config) {
    final mode = config?.themeMode ?? ThemeMode.dark;
    switch (mode) {
      case ThemeMode.light:
        return true;
      case ThemeMode.dark:
        return false;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final tracker = ref.watch(touchTrackerProvider);
    final config = ref.watch(configProvider).valueOrNull;
    final isLight = _effectiveLight(context, config);

    // themeMode 变化时驱动渐变动画；首次启动直接设值（避免开场动画）
    if (isLight != _isLight || _firstBuild) {
      _isLight = isLight;
      if (_firstBuild) {
        _themeCtrl.value = isLight ? 1.0 : 0.0;
        _firstBuild = false;
      } else {
        _themeCtrl.animateTo(isLight ? 1.0 : 0.0, curve: Curves.easeInOutCubic);
      }
    }

    return Listener(
      onPointerMove: tracker.onPointerMove,
      onPointerHover: tracker.onPointerHover,
      child: AnimatedBuilder(
        animation: _themeCtrl,
        builder: (context, child) =>
            ThemeAnimScope(t: _themeCtrl.value, child: child!),
        child: MaterialApp.router(
          title: '志极',
          theme: appTheme(isLight: isLight),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final t = ThemeAnimScope.of(context);
            return ColoredBox(
              color: Color.lerp(AppColors.bg, AppColorsLight.bg, t)!,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = child ?? const SizedBox.shrink();
                  final appContent = !AppBreakpoints.isDesktopNavigation(
                    constraints.maxWidth,
                  )
                      ? content
                      : Row(
                    children: [
                      AppDesktopNavigation(
                        router: router,
                        showBrand: !PlatformInfo.isWindows,
                      ),
                      Expanded(child: content),
                    ],
                  );
                  if (!PlatformInfo.isWindows) return appContent;
                  return Column(
                    children: [
                      const AppDesktopWindowBar(),
                      Expanded(child: appContent),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
