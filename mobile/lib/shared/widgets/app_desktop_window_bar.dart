// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/app_theme.dart';

/// Windows title bar integrated with Jeenith's desktop theme.
class AppDesktopWindowBar extends StatefulWidget {
  const AppDesktopWindowBar({super.key});

  @override
  State<AppDesktopWindowBar> createState() => _AppDesktopWindowBarState();
}

class _AppDesktopWindowBarState extends State<AppDesktopWindowBar>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_refreshWindowState());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _refreshWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    if (!mounted || isMaximized == _isMaximized) return;
    setState(() => _isMaximized = isMaximized);
  }

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
      return;
    }
    await windowManager.maximize();
  }

  void _setMaximized(bool value) {
    if (!mounted || value == _isMaximized) return;
    setState(() => _isMaximized = value);
  }

  @override
  void onWindowMaximize() => _setMaximized(true);

  @override
  void onWindowUnmaximize() => _setMaximized(false);

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    final typography = context.appTypography;

    return SizedBox(
      height: AppWindowChrome.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.windowBarBackground,
          border: Border(bottom: BorderSide(color: c.windowBarDivider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        color: c.jade,
                        size: AppWindowChrome.markIconSize,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        '志极',
                        style: typography.navigationSelectedLabel,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        'JEENITH',
                        style: typography.brandCaption.copyWith(
                          color: c.textMeta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _windowControl(
              colors: c,
              label: '最小化',
              icon: Icons.remove,
              onPressed: () => unawaited(windowManager.minimize()),
            ),
            _windowControl(
              colors: c,
              label: _isMaximized ? '还原' : '最大化',
              icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
              onPressed: () => unawaited(_toggleMaximize()),
            ),
            _windowControl(
              colors: c,
              label: '关闭',
              icon: Icons.close,
              isClose: true,
              onPressed: () => unawaited(windowManager.close()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _windowControl({
    required AppClr colors,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isClose = false,
  }) {
    final hoverColor = isClose
        ? colors.windowControlCloseHover
        : colors.windowControlHover;

    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onPressed,
          mouseCursor: SystemMouseCursors.click,
          hoverColor: hoverColor,
          focusColor: hoverColor,
          splashColor: hoverColor,
          child: SizedBox(
            width: AppWindowChrome.controlWidth,
            height: AppWindowChrome.height,
            child: Center(
              child: ExcludeSemantics(
                child: Icon(
                  icon,
                  color: colors.textSubtitle,
                  size: AppWindowChrome.controlIconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
