import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_strings.dart';

part 'category.g.dart';

/// Quiz question categories matching the MIG card game format.
/// Each card contains one question from each category.
@HiveType(typeId: 1)
enum Category {
  @HiveField(0)
  nowThen, // Nu & Då / Now & Then

  @HiveField(1)
  entertainment, // Nöje & Kultur / Entertainment & Culture

  @HiveField(2)
  nearFar, // Nära & Fjärran / Near & Far

  @HiveField(3)
  sportMisc, // Sport & Blandat / Sport & Misc

  @HiveField(4)
  scienceTech, // Vetenskap & Teknik / Science & Tech
}

/// Extension methods for Category enum
extension CategoryExtension on Category {
  /// Get the accent color for this category
  Color get color {
    switch (this) {
      case Category.nowThen:
        return AppColors.categoryNowThen;
      case Category.entertainment:
        return AppColors.categoryEntertainment;
      case Category.nearFar:
        return AppColors.categoryNearFar;
      case Category.sportMisc:
        return AppColors.categorySportMisc;
      case Category.scienceTech:
        return AppColors.categoryScienceTech;
    }
  }

  /// Get the localized display name for this category
  String localizedName(AppLanguage lang) {
    switch (this) {
      case Category.nowThen:
        return AppStrings.categoryNowThen(lang);
      case Category.entertainment:
        return AppStrings.categoryEntertainment(lang);
      case Category.nearFar:
        return AppStrings.categoryNearFar(lang);
      case Category.sportMisc:
        return AppStrings.categorySportMisc(lang);
      case Category.scienceTech:
        return AppStrings.categoryScienceTech(lang);
    }
  }
}
