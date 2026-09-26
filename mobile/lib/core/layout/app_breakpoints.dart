// Copyright (c) 2026 Qore

/// Shared logical-pixel breakpoints for the responsive application layouts.
class AppBreakpoints {
  AppBreakpoints._();

  static const double desktopNavigation = 960;
  static const double aiWorkspace = 1270;
  static const double homeThreeColumns = 900;
  static const double homeFourColumns = 1220;
  static const double contentMaxWidth = 1320;

  static bool isDesktopNavigation(double width) => width >= desktopNavigation;

  static bool hasWideAiWorkspace(double width) => width >= aiWorkspace;

  static int homeColumns(double width) {
    if (width >= homeFourColumns) return 4;
    if (width >= homeThreeColumns) return 3;
    return 2;
  }
}
