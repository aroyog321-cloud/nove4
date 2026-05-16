import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NOVE Mobile Design Tokens
/// Updated with glassmorphism, 60fps animation curves, and CTA glow tokens
class NoveColors {
  // Primary Brand Colors
  static const Color terracotta = Color(0xFFC0452A);
  static const Color terracottaLight = Color(0xFFD65A3E);
  static const Color terracottaDark = Color(0xFF9A3720);

  // Accent Colors
  static const Color amber = Color(0xFFF5C842);
  static const Color amberLight = Color(0xFFF9D567);
  static const Color amberDark = Color(0xFFD4A820);
  static const Color teal = Color(0xFF5DCAA5);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color deepBlue = Color(0xFF2563EB);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Base Light Theme
  static const Color cream = Color(0xFFF5F2EC);
  static const Color creamLight = Color(0xFFF9F6F2);
  static const Color warmWhite = Color(0xFFFEFCF8);

  // Warm Gray Scale
  static const Color warmGray50 = Color(0xFFF5F2EC);
  static const Color warmGray100 = Color(0xFFF3EBE0);
  static const Color warmGray200 = Color(0xFFEBE5D9);
  static const Color warmGray300 = Color(0xFFD4C9B8);
  static const Color warmGray400 = Color(0xFFA39C93);
  static const Color warmGray500 = Color(0xFF8C8273);
  static const Color warmGray600 = Color(0xFF72685E);
  static const Color warmGray700 = Color(0xFF5C5449);
  static const Color warmGray800 = Color(0xFF3D3630);
  static const Color warmGray900 = Color(0xFF242018);

  // Base Dark Theme
  static const Color deepDark = Color(0xFF1A1714);
  static const Color cardDark = Color(0xFF242018);
  static const Color cardDarkLight = Color(0xFF2F2A22);
  static const Color darkBorder = Color(0xFF3D3630);
  static const Color glassDark = Color(0x331A1714);
  static const Color glassLight = Color(0x33FFFFFF);

  // Sticky Note Colors
  static const Color stickyYellow = Color(0xFFFDD835);
  static const Color stickyPink = Color(0xFFF48FB1);
  static const Color stickyGreen = Color(0xFF81C784);
  static const Color stickyBlue = Color(0xFF64B5F6);

  // Surface Tint Variations
  static const Color surfaceTintAmber = Color(0xFFFFF8E1);
  static const Color surfaceTintTerracotta = Color(0xFFFFF3EE);
  static const Color surfaceTintTeal = Color(0xFFE8F5F1);

  // Semantic Surface Colors
  static Color surfaceSuccess(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B3A1F)
          : const Color(0xFFE8F5E9);

  static Color surfaceWarning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3A2F1B)
          : const Color(0xFFFFF3E0);

  static Color surfaceError(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3A1B1B)
          : const Color(0xFFFFEBEE);

  static Color surfaceInfo(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A2A3A)
          : const Color(0xFFE3F2FD);

  // Helper: get background for dark vs light
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? deepDark : cream;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : warmWhite;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : warmGray200;

  static Color primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cream : warmGray900;

  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? warmGray500 : warmGray600;

  static Color mutedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? warmGray700 : warmGray400;

  static Color inputBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : warmGray200;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? terracottaLight : terracotta;
}

/// Glassmorphism surface tokens — single source of truth for all glass effects.
/// Inspired by glass3d.dev and GlowUI design system.
class NoveGlass {
  // Light theme glass surfaces
  static const Color lightSurface = Color(0xC7FFFFFF); // 78% white
  static const Color lightBorder  = Color(0x99FFFFFF); // 60% white
  static const Color lightShadow  = Color(0x0F000000); // 6% black

  // Dark theme glass surfaces
  static const Color darkSurface = Color(0xB81A1714);  // 72% deep dark
  static const Color darkBorder  = Color(0x14FFFFFF);  // 8% white
  static const Color darkShadow  = Color(0x59000000);  // 35% black

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface
          : lightSurface;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorder
          : lightBorder;

  static List<BoxShadow> shadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? darkShadow : lightShadow,
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.9),
        blurRadius: 0,
        offset: const Offset(0, 1),
        spreadRadius: 0,
      ),
    ];
  }
}

class NoveRadii {
  static const double none = 0;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 9999;
}

class NoveBlur {
  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  // NEW — named semantic blur values for glass effects
  static const double card  = 18.0; // standard glass card blur (glass3d.dev)
  static const double heavy = 28.0; // header / modal heavy blur
}

class NoveSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxx = 48;
}

class NoveTypography {
  static TextStyle lora({TextStyle? style}) => GoogleFonts.lora(textStyle: style);
  static TextStyle dmsans({TextStyle? style}) => GoogleFonts.dmSans(textStyle: style);
  static TextStyle caveat({TextStyle? style}) => GoogleFonts.caveat(textStyle: style);

  static TextStyle editorFont({TextStyle? style}) => GoogleFonts.lora(textStyle: style, height: 1.6);
  static TextStyle uiFont({TextStyle? style}) => GoogleFonts.dmSans(textStyle: style);

  static TextStyle display(BuildContext context) => lora(style: TextStyle(fontSize: 40, height: 1.2, fontWeight: FontWeight.w700, color: NoveColors.primaryText(context)));
  static TextStyle h1(BuildContext context) => lora(style: TextStyle(fontSize: 30, height: 1.3, fontWeight: FontWeight.w600, color: NoveColors.primaryText(context), letterSpacing: -0.5));
  static TextStyle h2(BuildContext context) => lora(style: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w600, color: NoveColors.primaryText(context), letterSpacing: -0.3));
  static TextStyle h3(BuildContext context) => lora(style: TextStyle(fontSize: 18, height: 1.4, fontWeight: FontWeight.w500, color: NoveColors.primaryText(context), letterSpacing: 0));

  static TextStyle bodyLg(BuildContext context) => dmsans(style: TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w400, color: NoveColors.primaryText(context)));
  static TextStyle body(BuildContext context) => dmsans(style: TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w400, color: NoveColors.primaryText(context)));
  static TextStyle bodySm(BuildContext context) => dmsans(style: TextStyle(fontSize: 12, height: 1.5, fontWeight: FontWeight.w400, color: NoveColors.secondaryText(context)));
  static TextStyle caption(BuildContext context) => dmsans(style: TextStyle(fontSize: 11, height: 1.4, fontWeight: FontWeight.w400, color: NoveColors.mutedText(context)));
  static TextStyle label(BuildContext context) => dmsans(style: TextStyle(fontSize: 10, height: 1.5, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: NoveColors.secondaryText(context)));

  static const double fontSizeXs = 11;
  static const double fontSizeSm = 13;
  static const double fontSizeMd = 15;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 22;
  static const double fontSizeXxl = 28;
  static const double fontSizeXxxl = 36;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  static const double letterSpacingWide = 1;
  static const double letterSpacingWider = 2;
}

class NoveAnimation {
  // Durations
  static const Duration instant   = Duration(milliseconds: 100);
  static const Duration fast      = Duration(milliseconds: 200);
  static const Duration normal    = Duration(milliseconds: 350);
  static const Duration slow      = Duration(milliseconds: 500);
  static const Duration verySlow  = Duration(milliseconds: 800);
  static const Duration entrance  = Duration(milliseconds: 600);
  // NEW — semantic durations for 60fps patterns (60fps.design)
  static const Duration micro     = Duration(milliseconds: 120); // press state feedback
  static const Duration card      = Duration(milliseconds: 380); // card entrance slide

  // Curves
  static const Curve snappy    = Curves.easeOutCubic;
  static const Curve smooth    = Curves.easeInOutCubic;
  static const Curve bounce    = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
  // NEW — spring physics curves for natural motion (60fps.design)
  static const Curve spring    = Curves.easeOutBack;    // scale-in effects, FAB appear
  static const Curve snap      = Curves.easeOutExpo;   // drawer/sheet open
}

class NoveShadows {
  static List<BoxShadow> cardLight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ];
  }

  static List<BoxShadow> cardSmall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];
  }

  static List<BoxShadow> cardElevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ];
  }

  /// NEW — terracotta CTA glow (cta.gallery style)
  static List<BoxShadow> ctaGlow() => [
        BoxShadow(
          color: NoveColors.terracotta.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: NoveColors.terracotta.withValues(alpha: 0.2),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> amberGlow() => [
        BoxShadow(
          color: NoveColors.amber.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: NoveColors.amber.withValues(alpha: 0.2),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> stickyNote(Color noteColor) => [
        BoxShadow(
          color: noteColor.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(2, 4),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: NoveColors.terracotta.withValues(alpha: 0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get glassmorphism => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 4),
          blurRadius: 30,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.01),
          offset: const Offset(0, 1),
          blurRadius: 0,
          spreadRadius: 1,
        ),
      ];
}

/// Single source of truth for the 6-color note label palette.
const kNoteColorLabels = [
  '#C0452A',
  '#F5C842',
  '#5DCAA5',
  '#85B7EB',
  '#ED93B1',
  '#FFFFFF',
];