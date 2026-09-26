// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Persistent desktop navigation for every top-level route.
class AppDesktopNavigation extends StatelessWidget {
  final GoRouter router;
  final bool showBrand;

  const AppDesktopNavigation({
    super.key,
    required this.router,
    this.showBrand = true,
  });

  static const double width = 224;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<RouteInformation>(
        valueListenable: router.routeInformationProvider,
        builder: (context, information, _) =>
            _buildNavigation(context, information.uri.path),
      );

  Widget _buildNavigation(BuildContext context, String currentPath) {
    final c = AppClr.of(context);
    final typography = context.appTypography;
    final activeBranch = _activeBranch(currentPath);
    final border = BorderSide(color: c.goldBorder.withValues(alpha: 0.45));

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bgInner,
          border: Border(right: border),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBrand) _brand(c, typography),
                SizedBox(
                  height: showBrand
                      ? AppSpacing.xxLarge
                      : AppSpacing.xxLarge + AppWindowChrome.height,
                ),
                _sectionLabel(typography, '工作台'),
                const SizedBox(height: 8),
                for (final item in _mainItems)
                  _navigationItem(
                    c,
                    typography,
                    item.label,
                    item.icon,
                    item.path,
                    selected: activeBranch == item.branch,
                  ),
                const Spacer(),
                Divider(color: c.goldBorder.withValues(alpha: 0.45)),
                const SizedBox(height: 10),
                _sectionLabel(typography, '资料与设置'),
                const SizedBox(height: 8),
                for (final item in _utilityItems)
                  _navigationItem(
                    c,
                    typography,
                    item.label,
                    item.icon,
                    item.path,
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('志极 Jeenith', style: typography.navigationFooter),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(AppClr c, AppTypography typography) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.jade.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: c.jade.withValues(alpha: 0.28)),
        ),
        child: Icon(Icons.explore_outlined, color: c.jade, size: 21),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('志极', style: typography.brand),
          Text(
            'JEENITH',
            style: typography.brandCaption.copyWith(color: c.textMeta),
          ),
        ],
      ),
    ],
  );

  Widget _sectionLabel(AppTypography typography, String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(text, style: typography.navigationGroup),
  );

  Widget _navigationItem(
    AppClr c,
    AppTypography typography,
    String label,
    IconData icon,
    String path, {
    bool selected = false,
  }) {
    final foreground = selected ? c.jade : c.textSubtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            hoverColor: c.jade.withValues(alpha: 0.07),
            focusColor: c.jade.withValues(alpha: 0.12),
            onTap: () => router.go(path),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: selected
                    ? c.jade.withValues(alpha: 0.12)
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: selected
                      ? c.jade.withValues(alpha: 0.30)
                      : AppColors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: foreground, size: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: selected
                          ? typography.navigationSelectedLabel
                          : typography.navigationLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static int? _activeBranch(String path) {
    if (path == '/' ||
        path.startsWith('/tech/') ||
        path.startsWith('/ritual/')) {
      return 0;
    }
    if (path == '/jiekua') return 1;
    if (path == '/profiles' || path.startsWith('/profiles/')) return 2;
    return null;
  }

  static const _mainItems = <_NavigationEntry>[
    _NavigationEntry('卜算', Icons.grid_view_outlined, '/', 0),
    _NavigationEntry('AI 解读', Icons.auto_awesome_outlined, '/jiekua', 1),
    _NavigationEntry('个人档案', Icons.person_outline, '/profiles', 2),
  ];

  static const _utilityItems = <_NavigationEntry>[
    _NavigationEntry('历史记录', Icons.history, '/history'),
    _NavigationEntry('使用手册', Icons.menu_book_outlined, '/manual'),
    _NavigationEntry('设置', Icons.settings_outlined, '/settings'),
  ];
}

class _NavigationEntry {
  final String label;
  final IconData icon;
  final String path;
  final int? branch;

  const _NavigationEntry(this.label, this.icon, this.path, [this.branch]);
}
