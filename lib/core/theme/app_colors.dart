import 'package:flutter/material.dart';

/// Femman color palette inspired by bold, high-contrast poster design.
/// Vibrant colors on dark background with strong typography focus.
class AppColors {
  AppColors._();

  // Dark theme palette (primary theme, matching poster style)
  static const backgroundDark = Color(0xFF0D0D0D); // Dark charcoal/black
  static const textPrimaryDark = Color(0xFFE8D5C4); // Light beige/pale peach
  static const textSecondaryDark = Color(0xFF7FDBCA); // Light teal/mint green
  static const accentDark = Color(0xFF9B8BB0); // Muted purple/plum
  static const accentBright = Color(0xFFFF1493); // Vibrant magenta/fuchsia

  // Light theme palette (fallback)
  static const background = Color(0xFFFAFAFA); // Off-white
  static const textPrimary = Color(0xFF1A1A1A); // Near-black
  static const textSecondary = Color(0xFF6B6B6B); // Grey
  static const accent = Color(0xFF9B8BB0); // Muted purple/plum

  // Category accents (inspired by poster color palette)
  static const categoryNowThen = Color(0xFFE8D5C4); // Light beige/pale peach
  static const categoryEntertainment = Color(0xFFFF1493); // Vibrant magenta/fuchsia
  static const categoryNearFar = Color(0xFF7FDBCA); // Light teal/mint green
  static const categorySportMisc = Color(0xFF9B8BB0); // Muted purple/plum
  static const categoryScienceTech = Color(0xFFE8D5C4); // Light beige/pale peach

  // UI element colors
  static const borderDefault = Color(0x33666666); // textSecondary at 20% opacity
  static const borderDefaultDark = Color(0x33E8D5C4); // textPrimaryDark at 20% opacity
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}
