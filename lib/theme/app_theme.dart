import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ORBIT Design System — Framed Sheet v2 · taste-skill app study 23 screens
/// Sheet: framed-sheet · seed 1885750381 · drawn 2026-10-29
/// Idea: tinted L-frame (#f9fbfc) holds chrome; work on white sheet inset 8px, 1px edge #e8eaec, radius 16, no shadow.
/// Tokens measured, not guessed. One gap 24, one figure size 28 at 400, figures tabular.
/// Light is primary; dark is true-black #000 for battery.
/// House rules: no icon in tinted circle on KPI (0/23), no sparkline on KPI (0/23), borders OR shadows never both,
/// 1px hairlines, tabular numbers right-aligned, colour only on data.

class OrbitTheme {
  // ── Framed Sheet tokens (light) ──
  static const ground = Color(0xFFFFFFFF); // TEST white
  static const surface = Color(0xFFFFFFFF); // sheet
  static const raised = Color(0xFFF4F6F8);
  static const active = Color(0xFFEBEDEE);
  static const border = Color(0xFFE8EAEC); // sheet edge
  static const rule = Color(0xFFF0F1F2);   // row hairline
  static const control = Color(0xFFCDCED1);
  static const text = Color(0xFF1F201D);
  static const muted = Color(0xFF5D5F60);
  static const faint = Color(0xFF8A8C8E);
  static const ink = text;
  static const bg = surface;

  static const primary = Color(0xFF1F201D); // near-black fill TEST: must match smoke
  static const primaryInk = Colors.white;
  static const accent = Color(0xFF1B6E66); // chart-1 TEST
  static const accentDeep = Color(0xFF144E5C);
  static const accentSoft = Color(0xFFE6F0F3);
  static const primarySoft = accentSoft;

  // Chart hues — one per chart, not per bar
  static const chart1 = Color(0xFF1B6E66);
  static const chart2 = Color(0xFF2F70BB);
  static const chart3 = Color(0xFFA86F0C);

  static const success = Color(0xFF1E7B4F);
  static const successSoft = Color(0xFFDCFAE5);
  static const warning = Color(0xFF92400E);
  static const warningSoft = Color(0xFFFFFBEB);
  static const negative = Color(0xFFC4242A);
  static const negativeSoft = Color(0xFFFFEDEA);
  static const teal = accent;

  // Legacy aliases for existing screens
  static const surfaceTint = raised;
  static const outline = border;
  static const outline2 = rule;
  static const muted2 = faint;

  // Dark — true-black flat (from study, 6 dark screens)
  static const darkGround = Color(0xFF000000);
  static const darkSurface = Color(0xFF111111);
  static const darkRaised = Color(0xFF222222);
  static const darkBorder = Color(0xFF1A1A1A);
  static const darkRule = Color(0xFF161616);
  static const darkText = Color(0xFFFFFFFF);
  static const darkMuted = Color(0xFFB4B4B4);
  static const darkFaint = Color(0xFF949494);

  static const rCard = 12.0; // TEST soft 12, not soft 12 — study bimodal 4-8 vs 16-24
  static const rSheet = 16.0;
  static const rImg = 6.0;
  static const rControl = 6.0;
  static const rPanel = 8.0;

  static const gap = 24.0; // was 16, sheet spec is 24
  static const gapSmall = 16.0;
  static const cardPad = 20.0;
  static const pad = 24.0;
  static const sheetInset = 8.0;

  // Shadows — none at rest (17/23 cards no shadow); shadow only on floating
  static List<BoxShadow> get cardShadow => [];
  static List<BoxShadow> get cardHoverShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ];
  static List<BoxShadow> get sheetShadow => []; // sheet has 1px edge, no shadow
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
      ];

  static const pageTransitionDuration = Duration(milliseconds: 220);

  // ── Light Theme ──
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: surface,
        primary: primary,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: ground, // L-frame ground
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: ground, // chrome shares L-frame tint
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, color: text, letterSpacing: -0.01),
        iconTheme: const IconThemeData(color: text, size: 18),
        toolbarHeight: 48, // sheet spec
      ),
      textTheme: GoogleFonts.ibmPlexSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w600, color: text, height: 1.1, letterSpacing: -0.02), // page title 22
        titleLarge: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w600, color: text, height: 1.2),
        titleMedium: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, color: text, height: 1.3), // card title 16
        titleSmall: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w500, color: muted, height: 1.3),
        bodyLarge: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w400, color: text, height: 1.5),
        bodyMedium: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w400, color: text, height: 1.45),
        bodySmall: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w400, color: muted, height: 1.35), // small 12
        labelLarge: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w400, color: text, letterSpacing: 0), // mono for IDs
        labelSmall: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: active,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()]),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rPanel), side: const BorderSide(color: border, width: 1)),
      ),
      dividerTheme: const DividerThemeData(color: rule, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ground,
        indicatorColor: active, // grey pill, not tinted
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.ibmPlexSans(
            fontSize: 11, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400, color: s.contains(WidgetState.selected) ? text : muted)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(size: 18, color: s.contains(WidgetState.selected) ? text : muted)),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: text,
        unselectedLabelColor: muted,
        indicatorColor: text, // 2px underline in ink, spec
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w400),
        dividerColor: border,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, scaffoldBackgroundColor: darkGround, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark, surface: darkSurface, primary: darkText));
    return base.copyWith(
      scaffoldBackgroundColor: darkGround,
      cardColor: darkSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkGround,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
        iconTheme: const IconThemeData(color: darkText, size: 18),
        toolbarHeight: 48,
      ),
      textTheme: GoogleFonts.ibmPlexSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w600, color: darkText),
        titleMedium: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
        bodySmall: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w400, color: darkMuted),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rPanel), side: const BorderSide(color: darkBorder, width: 1)),
      ),
      dividerTheme: const DividerThemeData(color: darkRule, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkGround,
        indicatorColor: const Color(0xFF222222),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400, color: s.contains(WidgetState.selected) ? darkText : darkMuted)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(size: 18, color: s.contains(WidgetState.selected) ? darkText : darkMuted)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: const Color(0xFF222222),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w500, color: darkMuted),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}

extension OrbitText on TextStyle {
  TextStyle get tabular => copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  TextStyle get mono => GoogleFonts.ibmPlexMono(textStyle: this);
}
