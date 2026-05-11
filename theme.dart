import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bg = Color(0xFF0A0C0F);
  static const Color surface = Color(0xFF111419);
  static const Color card = Color(0xFF161B22);
  static const Color border = Color(0xFF21262D);
  static const Color accent = Color(0xFF00D4AA); // teal
  static const Color accentDim = Color(0xFF007A62);
  static const Color danger = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFAA00);
  static const Color success = Color(0xFF00CC66);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF7D8590);
  static const Color textMuted = Color(0xFF484F58);
  static const Color scanline = Color(0x06FFFFFF); // overlay effect

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accent,
          secondary: accentDim,
          error: danger,
          onSurface: textPrimary,
        ),
        textTheme: GoogleFonts.ibmPlexMonoTextTheme().copyWith(
          displayLarge: GoogleFonts.rajdhani(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          titleLarge: GoogleFonts.rajdhani(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
          titleMedium: GoogleFonts.ibmPlexMono(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: GoogleFonts.ibmPlexMono(
            color: textSecondary,
            fontSize: 13,
          ),
          labelSmall: GoogleFonts.ibmPlexMono(
            color: textMuted,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.rajdhani(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          iconTheme: const IconThemeData(color: accent),
        ),
        cardTheme: CardTheme(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          labelStyle: GoogleFonts.ibmPlexMono(
            color: textSecondary,
            fontSize: 13,
          ),
          hintStyle: GoogleFonts.ibmPlexMono(
            color: textMuted,
            fontSize: 13,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: bg,
            textStyle: GoogleFonts.rajdhani(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
        ),
      );
}
