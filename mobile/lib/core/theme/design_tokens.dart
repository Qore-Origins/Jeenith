// Copyright (c) 2026 Qore
import 'dart:ui' show FontStyle, FontWeight;

/// Central type scale used by widgets, pages, and result painters.
class AppFontSize {
  AppFontSize._();

  static const double ornament = 8;
  static const double footnote = 9;
  static const double micro = 10;
  static const double caption = 11;
  static const double label = 12;
  static const double bodySmall = 13;
  static const double body = 14;
  static const double button = 15;
  static const double bodyLarge = 16;
  static const double eyebrow = 17;
  static const double title = 18;
  static const double wordmark = 20;
  static const double metric = 22;
  static const double headingSmall = 26;
  static const double heading = 28;
  static const double displaySmall = 30;
  static const double display = 32;
  static const double displayLarge = 34;
  static const double hero = 40;
  static const double heroLarge = 56;
  static const double ritual = 60;
  static const double ritualLarge = 64;
  static const double ritualDisplay = 72;

  static double shareBranding(double canvasWidth) => canvasWidth * 0.022;
}

/// Named text weight and posture roles for a consistent typographic voice.
class AppFontWeight {
  AppFontWeight._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class AppFontStyle {
  AppFontStyle._();

  static const FontStyle normal = FontStyle.normal;
  static const FontStyle italic = FontStyle.italic;
}

/// Named line-height roles used when composing a text style.
class AppLineHeight {
  AppLineHeight._();

  static const double compact = 1.1;
  static const double display = 1.2;
  static const double heading = 1.25;
  static const double navigation = 1.3;
  static const double brand = 1.35;
  static const double compactBody = 1.4;
  static const double denseBody = 1.45;
  static const double body = 1.5;
  static const double relaxedBody = 1.55;
  static const double reading = 1.6;
  static const double relaxedReading = 1.65;
  static const double spacious = 1.7;
  static const double ritual = 1.8;
}

/// Named tracking roles for the app's typographic hierarchy.
class AppLetterSpacing {
  AppLetterSpacing._();

  static const double tight = 0.5;
  static const double subtle = 1;
  static const double compact = 1.2;
  static const double displayCompact = 1.4;
  static const double label = 2;
  static const double labelWide = 2.2;
  static const double decorative = 4;
  static const double display = 6;
  static const double ritual = 8;
  static const double ritualDisplay = 12;
  static const double ritualDisplayWide = 16;

  static double shareBranding(double canvasWidth) => canvasWidth * 0.004;
}

/// Spacing roles for shared controls and surfaces.
class AppSpacing {
  AppSpacing._();

  static const double xSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 24;
  static const double xxLarge = 32;
  static const double buttonPrimaryHorizontal = 22;
  static const double buttonPrimaryVertical = 12;
  static const double buttonSecondaryHorizontal = 18;
  static const double buttonSecondaryVertical = 10;
}

/// Shared corner radii for the app's component families.
class AppRadius {
  AppRadius._();

  static const double hairline = 2;
  static const double tiny = 3;
  static const double compact = 4;
  static const double compactSoft = 5;
  static const double compactRound = 6;
  static const double compactLoose = 7;
  static const double small = 8;
  static const double control = 10;
  static const double button = 12;
  static const double panelCompact = 14;
  static const double bubble = 15;
  static const double panel = 16;
  static const double card = 18;
  static const double dialog = 20;
  static const double dialogLarge = 22;
  static const double large = 24;
  static const double pill = 30;
}

/// Window chrome dimensions and interaction emphasis for desktop platforms.
class AppWindowChrome {
  AppWindowChrome._();

  static const double height = 36;
  static const double controlWidth = 46;
  static const double markIconSize = 16;
  static const double controlIconSize = 14;
  static const double dividerOpacity = 0.38;
  static const double hoverOpacity = 0.08;
  static const double closeHoverOpacity = 0.20;
}
