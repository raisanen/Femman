import 'package:flutter/material.dart';

/// Femman color palette following Swiss typography principles.
/// Limited, purposeful colors with generous whitespace.
class AppColors {
  AppColors._();

  // Core palette
  static const background = Color(0xFFFAFAFA); // Off-white
  static const textPrimary = Color(0xFF1A1A1A); // Near-black
  static const textSecondary = Color(0xFF6B6B6B); // Grey
  static const accent = Color(0xFFE63946); // Confident red

  // Category accents (subtle, used sparingly)
  static const categoryNowThen = Color(0xFFD4A574); // Muted ochre
  static const categoryEntertainment = Color(0xFFD4A5A5); // Dusty rose
  static const categoryNearFar = Color(0xFF7C9299); // Slate blue
  static const categorySportMisc = Color(0xFF9CAF88); // Sage green
  static const categoryScienceTech = Color(0xFF9E9E9E); // Cool grey

  // UI element colors
  static const borderDefault = Color(0x33666666); // textSecondary at 20% opacity
  static const white = Color(0xFFFFFFFF);
}
