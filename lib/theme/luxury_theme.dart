import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuxuryColors {
  // =========================
  // MAIN COLORS
  // =========================

  static const Color espresso = Color(0xFF2C1810);
  static const Color espressoDark = Color(0xFF180B07);
  static const Color chocolate = Color(0xFF45261A);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF7E8B5);
  static const Color goldDark = Color(0xFFA67C1E);
  static const Color amber = Color(0xFFE5A93C);

  static const Color cream = Color(0xFFFBF8F3);
  static const Color creamCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF26150E);

  static const Color textPrimary = Color(0xFF21130D);
  static const Color textSecondary = Color(0xFF806F67);
  static const Color textLight = Color(0xFFFFFCF7);

  static const Color borderGold = Color(0x40D4AF37);
  static const Color dividerWarm = Color(0x228D6E63);

  // Extra UI colors
  static const Color inputBackground = Color(0xFFFFFDF9);
  static const Color goldBackground = Color(0xFFFFF8E7);
  static const Color softBrown = Color(0xFF6F5144);

  static Color? get creamDark => null;
}

class LuxuryGradients {
  // =========================
  // HERO GRADIENT
  // =========================

  static const LinearGradient espressoHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B2116), Color(0xFF2C1810), Color(0xFF180B07)],
  );

  // =========================
  // GOLD GRADIENT
  // =========================

  static const LinearGradient goldAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE39A), Color(0xFFD4AF37), Color(0xFFA67C1E)],
  );

  // =========================
  // SOFT GOLD
  // =========================

  static const LinearGradient goldSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF9E9), Color(0xFFF3E4BE)],
  );

  // =========================
  // DARK CARD
  // =========================

  static const LinearGradient darkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A2116), Color(0xFF211109)],
  );

  // =========================
  // LIGHT CARD
  // =========================

  static const LinearGradient lightCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFCF8)],
  );

  // =========================
  // PREMIUM CARD
  // =========================

  static const LinearGradient premiumCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDF9), Color(0xFFF8F0E1)],
  );
}

class LuxuryShadows {
  // =========================
  // SOFT SHADOW
  // =========================

  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF2C1810).withValues(alpha: 0.06),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  // =========================
  // ELEVATED SHADOW
  // =========================

  static List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF2C1810).withValues(alpha: 0.10),
      blurRadius: 28,
      spreadRadius: 0,
      offset: const Offset(0, 10),
    ),
  ];

  // =========================
  // GOLD GLOW
  // =========================

  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
      blurRadius: 20,
      spreadRadius: 1,
      offset: const Offset(0, 5),
    ),
  ];

  // =========================
  // DARK SHADOW
  // =========================

  static List<BoxShadow> darkShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

// ============================================================
// LUXURY THEME
// ============================================================

ThemeData createLuxuryTheme(Color primaryColor, Color accentColor) {
  final baseTextTheme = GoogleFonts.outfitTextTheme();

  final playfair = GoogleFonts.playfairDisplayTextTheme();

  return ThemeData(
    useMaterial3: true,

    // ========================================================
    // COLOR SCHEME
    // ========================================================
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: LuxuryColors.cream,
      onPrimary: Colors.white,
      onSecondary: LuxuryColors.espresso,
      onSurface: LuxuryColors.textPrimary,
    ),

    // ========================================================
    // BACKGROUND
    // ========================================================
    scaffoldBackgroundColor: LuxuryColors.cream,

    fontFamily: GoogleFonts.outfit().fontFamily,

    // ========================================================
    // TEXT THEME
    // ========================================================
    textTheme: baseTextTheme.copyWith(
      // Main heading
      headlineLarge: playfair.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: LuxuryColors.textPrimary,
        letterSpacing: -0.8,
        height: 1.1,
      ),

      // Secondary heading
      headlineMedium: playfair.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: LuxuryColors.textPrimary,
        letterSpacing: -0.4,
        height: 1.15,
      ),

      // Small heading
      headlineSmall: playfair.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: LuxuryColors.textPrimary,
        height: 1.2,
      ),

      // Large title
      titleLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        color: LuxuryColors.textPrimary,
        fontSize: 20,
        letterSpacing: 0.1,
      ),

      // Medium title
      titleMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        color: LuxuryColors.textPrimary,
        fontSize: 16,
        letterSpacing: 0.1,
      ),

      // Small title
      titleSmall: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        color: LuxuryColors.textPrimary,
        fontSize: 14,
      ),

      // Main body
      bodyLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w400,
        color: LuxuryColors.textPrimary,
        fontSize: 15,
        height: 1.5,
      ),

      // Secondary body
      bodyMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w400,
        color: LuxuryColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),

      // Small body
      bodySmall: GoogleFonts.outfit(
        fontWeight: FontWeight.w400,
        color: LuxuryColors.textSecondary,
        fontSize: 12,
        height: 1.4,
      ),

      // Label
      labelLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.2,
      ),

      labelMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),

    // ========================================================
    // APP BAR
    // ========================================================
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,

      elevation: 0,

      scrolledUnderElevation: 0,

      centerTitle: false,

      surfaceTintColor: Colors.transparent,

      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 19,
        letterSpacing: 0.2,
      ),

      iconTheme: const IconThemeData(color: Colors.white, size: 23),
    ),

    // ========================================================
    // CARD
    // ========================================================
    cardTheme: CardThemeData(
      elevation: 0,

      color: LuxuryColors.creamCard,

      surfaceTintColor: Colors.transparent,

      margin: EdgeInsets.zero,

      shadowColor: LuxuryColors.espresso.withValues(alpha: 0.08),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),

        side: const BorderSide(color: LuxuryColors.dividerWarm, width: 1),
      ),
    ),

    // ========================================================
    // INPUT FIELDS
    // ========================================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: LuxuryColors.inputBackground,

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),

      floatingLabelBehavior: FloatingLabelBehavior.auto,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: const BorderSide(color: Color(0x338D6E63)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: const BorderSide(color: Color(0x338D6E63), width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: BorderSide(color: accentColor, width: 1.8),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),

      labelStyle: GoogleFonts.outfit(
        color: LuxuryColors.textSecondary,
        fontSize: 14,
      ),

      floatingLabelStyle: GoogleFonts.outfit(
        color: accentColor,
        fontWeight: FontWeight.w600,
      ),

      hintStyle: GoogleFonts.outfit(
        color: LuxuryColors.textSecondary.withValues(alpha: 0.65),
        fontSize: 14,
      ),

      prefixIconColor: LuxuryColors.softBrown,

      suffixIconColor: LuxuryColors.softBrown,

      errorStyle: GoogleFonts.outfit(
        color: Colors.redAccent,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ========================================================
    // ELEVATED BUTTON
    // ========================================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,

        foregroundColor: Colors.white,

        elevation: 0,

        shadowColor: primaryColor.withValues(alpha: 0.25),

        minimumSize: const Size(double.infinity, 54),

        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ========================================================
    // OUTLINED BUTTON
    // ========================================================
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,

        minimumSize: const Size(double.infinity, 52),

        side: BorderSide(color: accentColor, width: 1.2),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),

    // ========================================================
    // TEXT BUTTON
    // ========================================================
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,

        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),

    // ========================================================
    // CHIP
    // ========================================================
    chipTheme: ChipThemeData(
      backgroundColor: LuxuryColors.goldBackground,

      selectedColor: accentColor,

      disabledColor: Colors.grey.shade200,

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      labelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: LuxuryColors.textPrimary,
      ),

      secondaryLabelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      side: const BorderSide(color: LuxuryColors.borderGold, width: 1),
    ),

    // ========================================================
    // DIVIDER
    // ========================================================
    dividerTheme: const DividerThemeData(
      color: LuxuryColors.dividerWarm,
      thickness: 1,
      space: 1,
    ),

    // ========================================================
    // ICON THEME
    // ========================================================
    iconTheme: const IconThemeData(color: LuxuryColors.espresso, size: 22),

    // ========================================================
    // FLOATING ACTION BUTTON
    // ========================================================
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColor,

      foregroundColor: LuxuryColors.espresso,

      elevation: 4,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    ),

    // ========================================================
    // BOTTOM SHEET
    // ========================================================
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LuxuryColors.cream,

      surfaceTintColor: Colors.transparent,

      elevation: 10,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    // ========================================================
    // DIALOG
    // ========================================================
    dialogTheme: DialogThemeData(
      backgroundColor: LuxuryColors.cream,

      surfaceTintColor: Colors.transparent,

      elevation: 10,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      titleTextStyle: GoogleFonts.playfairDisplay(
        color: LuxuryColors.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),

      contentTextStyle: GoogleFonts.outfit(
        color: LuxuryColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    ),

    // ========================================================
    // SNACKBAR
    // ========================================================
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LuxuryColors.espresso,

      contentTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      behavior: SnackBarBehavior.floating,

      elevation: 5,
    ),

    // ========================================================
    // PROGRESS INDICATOR
    // ========================================================
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accentColor),

    // ========================================================
    // SWITCH
    // ========================================================
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }

        return LuxuryColors.textSecondary;
      }),

      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }

        return Colors.grey.shade300;
      }),
    ),

    // ========================================================
    // CHECKBOX
    // ========================================================
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),

      side: BorderSide(color: accentColor, width: 1.5),

      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }

        return Colors.transparent;
      }),

      checkColor: WidgetStateProperty.all(Colors.white),
    ),

    // ========================================================
    // RADIO
    // ========================================================
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }

        return LuxuryColors.textSecondary;
      }),
    ),
  );
}
