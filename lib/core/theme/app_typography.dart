import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Femman typography scale following Swiss typography principles.
/// Inter font family for clean, modern sans-serif aesthetic.
class AppTypography {
  AppTypography._();

  /// Display — Large numbers, scores (72pt, Inter Tight, weight 800)
  /// Bold, blocky style matching poster aesthetic
  static TextStyle get displayLarge => GoogleFonts.interTight(
        fontSize: 72,
        fontWeight: FontWeight.w800, // Extra bold for poster style
        color: AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -1.0, // Tighter spacing for blocky look
      );

  /// Headline Large — Category labels, screen titles (32pt, Inter, weight 800)
  /// Bold, prominent style
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800, // Bolder for poster style
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// Headline Medium — Section headers (24pt, Inter, weight 700)
  /// Bold, prominent style
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700, // Bolder for poster style
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.3,
      );

  /// Body Large — Questions (20pt, Inter, weight 500)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Body Medium — Standard text (18pt, Inter, weight 400)
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Label Large — Metadata, hints (14pt, Inter, weight 500, uppercase, tracking 0.5)
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
        letterSpacing: 0.5,
      );

  /// Label Medium — Small labels (12pt, Inter, weight 400, uppercase, tracking 0.5)
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
        letterSpacing: 0.5,
      );
}
