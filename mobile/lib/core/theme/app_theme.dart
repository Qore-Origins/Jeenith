// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

/// 全局色彩常量（从 Python QSS / PALACES 提取，保持视觉一致）。
class AppColors {
  AppColors._();

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

/// 中国风深色主题（Material 3）。
ThemeData appTheme({bool isLight = false}) {
  if (isLight) return _lightTheme();
  return _darkTheme();
}

ThemeData _darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldBright,
      tertiary: AppColors.jade,
      surface: AppColors.bg,
      onPrimary: Color(0xFF22251F),
      onSecondary: Color(0xFF22251F),
      onTertiary: Color(0xFF22251F),
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.goldBright,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
      iconTheme: IconThemeData(color: AppColors.gold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF202721),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldBright),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),
  );
}

ThemeData _lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColorsLight.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.gold,
      secondary: AppColorsLight.goldBright,
      tertiary: AppColorsLight.jade,
      surface: AppColorsLight.bg,
      onPrimary: Color(0xFFFFFEFA),
      onSecondary: Color(0xFFFFFEFA),
      onTertiary: Color(0xFFFFFEFA),
      onSurface: AppColorsLight.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColorsLight.goldBright,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
      iconTheme: IconThemeData(color: AppColorsLight.gold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F2E9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColorsLight.goldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColorsLight.goldBright),
      ),
      hintStyle: const TextStyle(color: AppColorsLight.textHint),
    ),
  );
}
