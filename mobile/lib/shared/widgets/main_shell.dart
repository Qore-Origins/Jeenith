// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_breakpoints.dart';
import '../../core/theme/app_theme.dart';

/// Main tab shell. Mobile uses a bottom bar; desktop navigation lives at app root.
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _items = <_MainNavigationItem>[
    _MainNavigationItem(0, Icons.grid_view_outlined, '卜算'),
    _MainNavigationItem(1, Icons.auto_awesome_outlined, 'AI 解读'),
    _MainNavigationItem(2, Icons.person_outline, '档案'),
  ];

  void _go(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktopNavigation(
      MediaQuery.sizeOf(context).width,
    );
    if (isDesktop) return Scaffold(body: widget.navigationShell);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: widget.navigationShell),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final c = AppClr.of(context);
    final current = widget.navigationShell.currentIndex;
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: c.bgInner,
          border: Border(top: BorderSide(color: c.goldBorder)),
        ),
        child: Row(
          children: [
            for (final item in _items)
              Expanded(
                child: _navigationItem(
                  c,
                  item,
                  selected: current == item.index,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _navigationItem(
    AppClr c,
    _MainNavigationItem item, {
    required bool selected,
  }) {
    final foreground = selected ? c.jade : c.textSubtitle;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.panelCompact),
          hoverColor: c.jade.withValues(alpha: 0.08),
          focusColor: c.jade.withValues(alpha: 0.14),
          onTap: () => _go(item.index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: selected
                  ? c.jade.withValues(alpha: 0.12)
                  : AppColors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.panelCompact),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: foreground, size: 20),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? c.textPrimary : c.textSubtitle,
                    fontSize: AppFontSize.caption,
                    fontWeight: selected ? AppFontWeight.semibold : AppFontWeight.regular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainNavigationItem {
  final int index;
  final IconData icon;
  final String label;

  const _MainNavigationItem(this.index, this.icon, this.label);
}
