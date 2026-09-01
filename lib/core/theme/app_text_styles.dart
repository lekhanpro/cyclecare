import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextTheme get textTheme => GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 57,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 45,
          height: 1.08,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.nunito(
          fontSize: 36,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
        headlineLarge: GoogleFonts.nunito(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.25,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 28,
          height: 1.18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.15,
        ),
        headlineSmall: GoogleFonts.nunito(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        titleSmall: GoogleFonts.nunito(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: 12.5,
          height: 1.4,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          height: 1.25,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.nunito(
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.nunito(
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.25,
        ),
      );
}
