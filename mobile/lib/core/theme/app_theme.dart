// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

import 'design_tokens.dart';
export 'design_tokens.dart';

/// 全局色彩常量（从 Python QSS / PALACES 提取，保持视觉一致）。
class AppColors {
  AppColors._();

  // —— 通用绘制语义 ——
  static const Color transparent = Color(0x00000000);
  static const Color shadow = Color(0xFF000000);
  static const Color paperWhite = Color(0xFFFFFFFF);

  // —— 背景 ——
  static const Color bg = Color(0xFF171C19);
  static const Color bgInner = Color(0xFF1D241F);
  static const Color bgMid = Color(0xFF1A211C);
  static const Color bgOuter = Color(0xFF141A16);

  // —— 鎏金系 ——
  static const Color gold = Color(0xFFA88D64);
  static const Color goldBright = Color(0xFFB99D71);
  static const Color goldLight = Color(0xFFCEB589);
  static const Color goldBorder = Color.fromRGBO(168, 141, 100, 0.38);
  static const Color jade = Color(0xFF9CAA8E);

  // —— 文字 ——
  static const Color textHighlight = Color(0xFFF5F2E8);
  static const Color textPrimary = Color(0xFFE8E5DA);
  static const Color textBody = Color(0xFFC3C4B8);
  static const Color textMeta = Color(0xFFA6ACA0);
  static const Color textSubtitle = Color(0xFF9DA598);
  static const Color textHint = Color(0xFF7B8278);

  // —— 面板 ——
  static const Color panel = Color(0xFF1D241F);
  static const Color card = Color(0xFF252C26);
  static const Color buttonTop = Color(0xFF303A32);
  static const Color buttonBottom = Color(0xFF232B25);

  // —— 五行色（小六壬六宫）——
  static const Color wood = Color(0xFF3FAE6F);
  static const Color woodGlow = Color(0xFF7FE3AD);
  static const Color water = Color(0xFF6A8AA6);
  static const Color waterGlow = Color(0xFF9BC0DC);
  static const Color fire = Color(0xFFE85A3C);
  static const Color fireGlow = Color(0xFFFF9077);
  static const Color metal = Color(0xFFC5CDD8);
  static const Color metalGlow = Color(0xFFEEF2F8);
  static const Color waterDeep = Color(0xFF3A86B8);
  static const Color waterDeepGlow = Color(0xFF74BCE4);
  static const Color earth = Color(0xFFB8924E);
  static const Color earthGlow = Color(0xFFE0BF7E);

  // —— 周易爻色 ——
  static const Color yang = Color(0xFFD4A857);
  static const Color yin = Color(0xFF9BC0DC);
  static const Color changing = Color(0xFFE85A3C);

  // —— 断语分级色 ——
  static const Color gradeGreat = Color(0xFF7FE3AD);
  static const Color gradeGood = Color(0xFF9BC0DC);
  static const Color gradeSteady = Color(0xFFD4A857);
  static const Color gradeRough = Color(0xFFE0BF7E);
  static const Color gradeBad = Color(0xFFFF9077);

  // —— 仪式绘制语义 ——
  static const Color ritualWood = Color(0xFF6BAB6B);
  static const Color ritualPaper = Color(0xFFE8D9B8);
  static const Color ritualInk = Color(0xFF3A2E1F);
  static const Color ritualStick = Color(0xFFC9A063);
  static const Color ritualStickTip = Color(0xFFB23A3A);
  static const Color ritualPaperBorder = Color(0xFFB89A5C);
  static const Color ritualRoller = Color(0xFF6B4F1F);
  static const Color ritualTube = Color(0xFF2A2233);
  static const Color ritualTubeInner = Color(0xFF1B1626);
  static const Color ritualDarkInk = Color(0xFF1A1208);
  static const Color ritualBackground = Color.fromRGBO(12, 10, 18, 1);
  static const Color ritualTaijiLight = Color(0xFFEEE6CD);
  static const Color ritualTaijiDark = Color(0xFF14101C);
  static const Color ritualEarthDark = Color(0xFF6A4A2A);
  static const Color ritualEarthLight = Color(0xFF8A6A3A);
  static const Color ritualEarthHighlight = Color(0xFFA88A5A);
  static const Color sparkIgnite = Color(0xFFFFF0C0);
  static const Color sparkCursor = Color(0xFFFFE6A0);
  static const Color sparkTrail = Color(0xFFFFD782);

  /// 明度缩放（对应 Python darker()）。
  static Color darker(Color c, double f) {
    return Color.fromARGB(
      (c.a * 255).round(),
      (c.r * 255 * f).round().clamp(0, 255),
      (c.g * 255 * f).round().clamp(0, 255),
      (c.b * 255 * f).round().clamp(0, 255),
    );
  }
}

/// 浅色主题色彩常量（v1.5.0 新增，与深色保持同等五色系语义）。
class AppColorsLight {
  AppColorsLight._();

  static const Color transparent = Color(0x00000000);
  static const Color shadow = Color(0xFF000000);
  static const Color paperWhite = Color(0xFFFFFFFF);

  // —— 背景（浅米色）——
  static const Color bg = Color(0xFFF0EEE5);
  static const Color bgInner = Color(0xFFFAF9F4);
  static const Color bgMid = Color(0xFFF7F5ED);
  static const Color bgOuter = Color(0xFFE7E4DA);

  // —— 鎏金系（深一些以保证对比度）——
  static const Color gold = Color(0xFF96784F);
  static const Color goldBright = Color(0xFF856A47);
  static const Color goldLight = Color(0xFFAB8A5B);
  static const Color goldBorder = Color.fromRGBO(150, 120, 79, 0.42);
  static const Color jade = Color(0xFF5E7465);

  // —— 文字 ——
  static const Color textHighlight = Color(0xFF20221E);
  static const Color textPrimary = Color(0xFF282923);
  static const Color textBody = Color(0xFF55574F);
  static const Color textMeta = Color(0xFF70736A);
  static const Color textSubtitle = Color(0xFF68786B);
  static const Color textHint = Color(0xFF85877E);

  // —— 面板 ——
  static const Color panel = Color(0xFFFAF9F4);
  static const Color card = Color(0xFFFFFEFA);
  static const Color buttonTop = Color(0xFFE8E5DB);
  static const Color buttonBottom = Color(0xFFDFDCD1);

  // —— 五行色 ——
  static const Color wood = Color(0xFF2D8E54);
  static const Color woodGlow = Color(0xFF1E6B3F);
  static const Color water = Color(0xFF3A6E8E);
  static const Color waterGlow = Color(0xFF2A5670);
  static const Color fire = Color(0xFFC13E1E);
  static const Color fireGlow = Color(0xFFA02E0E);
  static const Color metal = Color(0xFF5A6878);
  static const Color metalGlow = Color(0xFF3E4A58);
  static const Color waterDeep = Color(0xFF1E5A88);
  static const Color waterDeepGlow = Color(0xFF124068);
  static const Color earth = Color(0xFF8A6420);
  static const Color earthGlow = Color(0xFF6A4A14);

  static const Color yang = Color(0xFF9B7A2A);
  static const Color yin = Color(0xFF3A6E8E);
  static const Color changing = Color(0xFFC13E1E);

  static const Color gradeGreat = Color(0xFF1E6B3F);
  static const Color gradeGood = Color(0xFF2A5670);
  static const Color gradeSteady = Color(0xFF8A6A1E);
  static const Color gradeRough = Color(0xFF6A4A14);
  static const Color gradeBad = Color(0xFFA02E0E);

  static const Color ritualEarthDark = Color(0xFF8A6A3A);
  static const Color ritualEarthLight = Color(0xFFA88A5A);
  static const Color ritualDarkInk = Color(0xFF1A1208);
}

/// 主题感知色板：基于动画插值 t（0=深 1=浅），实现深/浅主题**渐变切换**。
///
/// t 由根 [ThemeAnimScope] 提供（配合 JeenithApp 的 AnimationController）。
/// 用法：`context.appClr.card`，或罕见色用 `context.appClr.resolve(深色, 浅色)`。
class AppClr {
  final double t;
  const AppClr._(this.t);

  static AppClr of(BuildContext c) => AppClr._(ThemeAnimScope.of(c));

  Color _lerp(Color d, Color l) => Color.lerp(d, l, t)!;

  /// 通用：插值任意深/浅色。
  Color resolve(Color dark, Color light) => Color.lerp(dark, light, t)!;

  // —— 背景 ——
  Color get bg => _lerp(AppColors.bg, AppColorsLight.bg);
  Color get bgInner => _lerp(AppColors.bgInner, AppColorsLight.bgInner);
  Color get bgMid => _lerp(AppColors.bgMid, AppColorsLight.bgMid);
  Color get bgOuter => _lerp(AppColors.bgOuter, AppColorsLight.bgOuter);

  // —— 面板 ——
  Color get panel => _lerp(AppColors.panel, AppColorsLight.panel);
  Color get card => _lerp(AppColors.card, AppColorsLight.card);
  Color get buttonTop => _lerp(AppColors.buttonTop, AppColorsLight.buttonTop);
  Color get buttonBottom =>
      _lerp(AppColors.buttonBottom, AppColorsLight.buttonBottom);

  // —— 鎏金系 ——
  Color get gold => _lerp(AppColors.gold, AppColorsLight.gold);
  Color get goldBright =>
      _lerp(AppColors.goldBright, AppColorsLight.goldBright);
  Color get goldLight => _lerp(AppColors.goldLight, AppColorsLight.goldLight);
  Color get goldBorder =>
      _lerp(AppColors.goldBorder, AppColorsLight.goldBorder);
  Color get jade => _lerp(AppColors.jade, AppColorsLight.jade);
  Color get onAction => _lerp(AppColors.bg, AppColorsLight.panel);
  Color get shadow => _lerp(AppColors.shadow, AppColorsLight.shadow);
  Color get ritualEarthDark =>
      _lerp(AppColors.ritualEarthDark, AppColorsLight.ritualEarthDark);
  Color get ritualEarthLight =>
      _lerp(AppColors.ritualEarthLight, AppColorsLight.ritualEarthLight);
  Color get ritualTaijiLight =>
      _lerp(AppColors.ritualTaijiLight, AppColorsLight.yang);
  Color get ritualTaijiDark =>
      _lerp(AppColors.ritualTaijiDark, AppColorsLight.ritualDarkInk);
  Color get sparkIgnite => _lerp(AppColors.sparkIgnite, AppColorsLight.gold);
  Color get sparkCursor => _lerp(AppColors.sparkCursor, AppColorsLight.gold);
  Color get sparkTrail => _lerp(AppColors.sparkTrail, AppColorsLight.gold);

  // —— 文字 ——
  Color get textHighlight =>
      _lerp(AppColors.textHighlight, AppColorsLight.textHighlight);
  Color get textPrimary =>
      _lerp(AppColors.textPrimary, AppColorsLight.textPrimary);
  Color get textBody => _lerp(AppColors.textBody, AppColorsLight.textBody);
  Color get textMeta => _lerp(AppColors.textMeta, AppColorsLight.textMeta);
  Color get textSubtitle =>
      _lerp(AppColors.textSubtitle, AppColorsLight.textSubtitle);
  Color get textHint => _lerp(AppColors.textHint, AppColorsLight.textHint);

  // —— 五行色 ——
  Color get wood => _lerp(AppColors.wood, AppColorsLight.wood);
  Color get woodGlow => _lerp(AppColors.woodGlow, AppColorsLight.woodGlow);
  Color get water => _lerp(AppColors.water, AppColorsLight.water);
  Color get waterGlow => _lerp(AppColors.waterGlow, AppColorsLight.waterGlow);
  Color get fire => _lerp(AppColors.fire, AppColorsLight.fire);
  Color get fireGlow => _lerp(AppColors.fireGlow, AppColorsLight.fireGlow);
  Color get metal => _lerp(AppColors.metal, AppColorsLight.metal);
  Color get metalGlow => _lerp(AppColors.metalGlow, AppColorsLight.metalGlow);
  Color get waterDeep => _lerp(AppColors.waterDeep, AppColorsLight.waterDeep);
  Color get waterDeepGlow =>
      _lerp(AppColors.waterDeepGlow, AppColorsLight.waterDeepGlow);
  Color get earth => _lerp(AppColors.earth, AppColorsLight.earth);
  Color get earthGlow => _lerp(AppColors.earthGlow, AppColorsLight.earthGlow);

  // —— 周易爻色 ——
  Color get yang => _lerp(AppColors.yang, AppColorsLight.yang);
  Color get yin => _lerp(AppColors.yin, AppColorsLight.yin);
  Color get changing => _lerp(AppColors.changing, AppColorsLight.changing);

  // —— 断语分级色 ——
  Color get gradeGreat =>
      _lerp(AppColors.gradeGreat, AppColorsLight.gradeGreat);
  Color get gradeGood => _lerp(AppColors.gradeGood, AppColorsLight.gradeGood);
  Color get gradeSteady =>
      _lerp(AppColors.gradeSteady, AppColorsLight.gradeSteady);
  Color get gradeRough =>
      _lerp(AppColors.gradeRough, AppColorsLight.gradeRough);
  Color get gradeBad => _lerp(AppColors.gradeBad, AppColorsLight.gradeBad);

  // —— 桌面窗口栏 ——
  Color get windowBarBackground => bg;
  Color get windowBarDivider =>
      goldBorder.withValues(alpha: AppWindowChrome.dividerOpacity);
  Color get windowControlHover => jade.withValues(alpha: AppWindowChrome.hoverOpacity);
  Color get windowControlCloseHover =>
      gradeBad.withValues(alpha: AppWindowChrome.closeHoverOpacity);
}

/// 根级主题动画插值载体（t: 0=深 1=浅）。
/// 由 JeenithApp 的 AnimationController 驱动，配合 [AppClr] 实现深/浅渐变切换。
class ThemeAnimScope extends InheritedWidget {
  final double t;
  const ThemeAnimScope({super.key, required this.t, required super.child});
  static double of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<ThemeAnimScope>()?.t ?? 0.0;
  @override
  bool updateShouldNotify(ThemeAnimScope old) => t != old.t;
}

/// [BuildContext] 便捷扩展：`context.appClr` 取主题感知色板。
extension AppClrContext on BuildContext {
  AppClr get appClr => AppClr.of(this);
}

/// 字体常量。
class AppFonts {
  AppFonts._();

  /// 思源宋体（如已打包则用宋体；否则回退系统默认）。
  static const String serif = 'SourceHanSerif';
}

/// Reusable typography roles. Use these instead of creating a font scale in a
/// page or widget; colors follow the animated light/dark theme.
class AppTypography {
  final AppClr colors;

  const AppTypography._(this.colors);

  static AppTypography of(BuildContext context) =>
      AppTypography._(AppClr.of(context));

  TextStyle get display => TextStyle(
    color: colors.textHighlight,
    fontSize: AppFontSize.display,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
    height: AppLineHeight.heading,
  );

  TextStyle get title => TextStyle(
    color: colors.textPrimary,
    fontSize: AppFontSize.title,
    fontWeight: AppFontWeight.bold,
  );

  TextStyle get brand => TextStyle(
    color: colors.textHighlight,
    fontSize: AppFontSize.wordmark,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
  );

  TextStyle get brandCaption => TextStyle(
    color: colors.textSubtitle,
    fontSize: AppFontSize.footnote,
    fontWeight: AppFontWeight.bold,
    letterSpacing: AppLetterSpacing.label,
    height: AppLineHeight.brand,
    decoration: TextDecoration.none,
  );

  TextStyle get navigationLabel => TextStyle(
    color: colors.textSubtitle,
    fontSize: AppFontSize.bodySmall,
    decoration: TextDecoration.none,
  );

  TextStyle get navigationSelectedLabel => TextStyle(
    color: colors.textPrimary,
    fontSize: AppFontSize.bodySmall,
    fontWeight: AppFontWeight.semibold,
    decoration: TextDecoration.none,
  );

  TextStyle get navigationGroup => TextStyle(
    color: colors.textHint,
    fontSize: AppFontSize.caption,
    fontWeight: AppFontWeight.semibold,
    letterSpacing: AppLetterSpacing.compact,
    height: AppLineHeight.brand,
    decoration: TextDecoration.none,
  );

  TextStyle get navigationFooter => TextStyle(
    color: colors.textHint,
    fontSize: AppFontSize.caption,
    height: AppLineHeight.navigation,
    decoration: TextDecoration.none,
  );

  TextStyle get sectionTitle => TextStyle(
    color: colors.textSubtitle,
    fontSize: AppFontSize.body,
    fontWeight: AppFontWeight.bold,
  );

  TextStyle get subtitle => TextStyle(
    color: colors.textPrimary,
    fontSize: AppFontSize.bodyLarge,
    fontWeight: AppFontWeight.semibold,
  );

  TextStyle get body => TextStyle(
    color: colors.textBody,
    fontSize: AppFontSize.body,
    height: AppLineHeight.body,
  );

  TextStyle get bodySmall => TextStyle(
    color: colors.textBody,
    fontSize: AppFontSize.bodySmall,
    height: AppLineHeight.body,
  );

  TextStyle get label => TextStyle(
    color: colors.textMeta,
    fontSize: AppFontSize.label,
    fontWeight: AppFontWeight.medium,
  );

  TextStyle get caption =>
      TextStyle(color: colors.textMeta, fontSize: AppFontSize.caption);

  TextStyle get button => TextStyle(
    color: colors.textPrimary,
    fontSize: AppFontSize.button,
    fontWeight: AppFontWeight.semibold,
  );

  TextStyle get secondaryButton => TextStyle(
    color: colors.textBody,
    fontSize: AppFontSize.bodySmall,
    fontWeight: AppFontWeight.bold,
  );
}

extension AppTypographyContext on BuildContext {
  AppTypography get appTypography => AppTypography.of(this);
}

class AppSurfaceStyles {
  AppSurfaceStyles._();

  static BoxDecoration panel(AppClr colors) => BoxDecoration(
    color: colors.panel,
    borderRadius: BorderRadius.circular(AppRadius.panel),
    border: Border.all(color: colors.goldBorder),
  );
}

/// Shared Material button variants for intentional one-off states. Base
/// geometry and typography remain owned by the app theme.
class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle filled({
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
  }) => FilledButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    padding:
        padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
    visualDensity: visualDensity,
    minimumSize: const Size(64, 42),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    ),
  );

  static ButtonStyle outlined({
    Color? foregroundColor,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
  }) => OutlinedButton.styleFrom(
    foregroundColor: foregroundColor,
    side: borderColor == null ? null : BorderSide(color: borderColor),
    padding: padding,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    ),
  );

  static ButtonStyle text({
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
    Size? minimumSize,
    MaterialTapTargetSize? tapTargetSize,
  }) => TextButton.styleFrom(
    foregroundColor: foregroundColor,
    padding: padding,
    visualDensity: visualDensity,
    minimumSize: minimumSize,
    tapTargetSize: tapTargetSize,
  );

}

/// 中国风深色主题（Material 3）。
ThemeData appTheme({bool isLight = false}) {
  if (isLight) return _lightTheme();
  return _darkTheme();
}

TextTheme _darkTextTheme() => const TextTheme(
  displayLarge: TextStyle(
    color: AppColors.textHighlight,
    fontSize: AppFontSize.displayLarge,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
    height: AppLineHeight.display,
  ),
  displayMedium: TextStyle(
    color: AppColors.textHighlight,
    fontSize: AppFontSize.displaySmall,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
    height: AppLineHeight.display,
  ),
  headlineLarge: TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppFontSize.heading,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
  ),
  headlineMedium: TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppFontSize.headingSmall,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
  ),
  titleLarge: TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppFontSize.title,
    fontWeight: AppFontWeight.bold,
  ),
  titleMedium: TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppFontSize.bodyLarge,
    fontWeight: AppFontWeight.semibold,
  ),
  titleSmall: TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppFontSize.body,
    fontWeight: AppFontWeight.semibold,
  ),
  bodyLarge: TextStyle(
    color: AppColors.textBody,
    fontSize: AppFontSize.bodyLarge,
    height: AppLineHeight.body,
  ),
  bodyMedium: TextStyle(
    color: AppColors.textBody,
    fontSize: AppFontSize.body,
    height: AppLineHeight.body,
  ),
  bodySmall: TextStyle(
    color: AppColors.textBody,
    fontSize: AppFontSize.bodySmall,
    height: AppLineHeight.body,
  ),
  labelLarge: TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppFontSize.button,
    fontWeight: AppFontWeight.semibold,
  ),
  labelMedium: TextStyle(
    color: AppColors.textMeta,
    fontSize: AppFontSize.label,
    fontWeight: AppFontWeight.medium,
  ),
  labelSmall: TextStyle(
    color: AppColors.textMeta,
    fontSize: AppFontSize.caption,
  ),
);

TextTheme _lightTextTheme() => const TextTheme(
  displayLarge: TextStyle(
    color: AppColorsLight.textHighlight,
    fontSize: AppFontSize.displayLarge,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
    height: AppLineHeight.display,
  ),
  displayMedium: TextStyle(
    color: AppColorsLight.textHighlight,
    fontSize: AppFontSize.displaySmall,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
    height: AppLineHeight.display,
  ),
  headlineLarge: TextStyle(
    color: AppColorsLight.textPrimary,
    fontSize: AppFontSize.heading,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
  ),
  headlineMedium: TextStyle(
    color: AppColorsLight.textPrimary,
    fontSize: AppFontSize.headingSmall,
    fontWeight: AppFontWeight.bold,
    fontFamily: AppFonts.serif,
  ),
  titleLarge: TextStyle(
    color: AppColorsLight.textPrimary,
    fontSize: AppFontSize.title,
    fontWeight: AppFontWeight.bold,
  ),
  titleMedium: TextStyle(
    color: AppColorsLight.textPrimary,
    fontSize: AppFontSize.bodyLarge,
    fontWeight: AppFontWeight.semibold,
  ),
  titleSmall: TextStyle(
    color: AppColorsLight.textPrimary,
    fontSize: AppFontSize.body,
    fontWeight: AppFontWeight.semibold,
  ),
  bodyLarge: TextStyle(
    color: AppColorsLight.textBody,
    fontSize: AppFontSize.bodyLarge,
    height: AppLineHeight.body,
  ),
  bodyMedium: TextStyle(
    color: AppColorsLight.textBody,
    fontSize: AppFontSize.body,
    height: AppLineHeight.body,
  ),
  bodySmall: TextStyle(
    color: AppColorsLight.textBody,
    fontSize: AppFontSize.bodySmall,
    height: AppLineHeight.body,
  ),
  labelLarge: TextStyle(
    color: AppColorsLight.textPrimary,
    fontSize: AppFontSize.button,
    fontWeight: AppFontWeight.semibold,
  ),
  labelMedium: TextStyle(
    color: AppColorsLight.textMeta,
    fontSize: AppFontSize.label,
    fontWeight: AppFontWeight.medium,
  ),
  labelSmall: TextStyle(
    color: AppColorsLight.textMeta,
    fontSize: AppFontSize.caption,
  ),
);

ThemeData _darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: _darkTextTheme(),
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.jade,
      secondary: AppColors.gold,
      tertiary: AppColors.goldBright,
      surface: AppColors.bg,
      onPrimary: AppColors.bg,
      onSecondary: AppColors.bg,
      onTertiary: AppColors.bg,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.goldBright,
        fontSize: AppFontSize.wordmark,
        fontWeight: AppFontWeight.bold,
        letterSpacing: AppLetterSpacing.label,
      ),
      iconTheme: IconThemeData(color: AppColors.jade),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInner,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.goldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.jade),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),
    filledButtonTheme: FilledButtonThemeData(style: AppButtonStyles.filled()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppButtonStyles.outlined(
        foregroundColor: AppColors.jade,
        borderColor: AppColors.goldBorder,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppButtonStyles.text(foregroundColor: AppColors.jade),
    ),
  );
}

ThemeData _lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: _lightTextTheme(),
    scaffoldBackgroundColor: AppColorsLight.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.jade,
      secondary: AppColorsLight.gold,
      tertiary: AppColorsLight.goldBright,
      surface: AppColorsLight.bg,
      onPrimary: AppColorsLight.panel,
      onSecondary: AppColorsLight.textPrimary,
      onTertiary: AppColorsLight.textPrimary,
      onSurface: AppColorsLight.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsLight.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColorsLight.goldBright,
        fontSize: AppFontSize.wordmark,
        fontWeight: AppFontWeight.bold,
        letterSpacing: AppLetterSpacing.label,
      ),
      iconTheme: IconThemeData(color: AppColorsLight.jade),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsLight.bgInner,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColorsLight.goldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColorsLight.jade),
      ),
      hintStyle: const TextStyle(color: AppColorsLight.textHint),
    ),
    filledButtonTheme: FilledButtonThemeData(style: AppButtonStyles.filled()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppButtonStyles.outlined(
        foregroundColor: AppColorsLight.jade,
        borderColor: AppColorsLight.goldBorder,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppButtonStyles.text(foregroundColor: AppColorsLight.jade),
    ),
  );
}
