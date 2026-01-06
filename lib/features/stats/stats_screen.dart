import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/models/category.dart';
import 'package:femman/models/difficulty.dart';
import 'package:femman/providers/settings_providers.dart';
import 'package:femman/providers/stats_providers.dart';

/// Player statistics overview screen.
///
/// Shows:
/// - Total cards played
/// - Total questions correct (with percentage)
/// - Best streak
/// - Per-category breakdown:
///   - Category name
///   - Accuracy percentage
///   - Current difficulty level
///   - Questions attempted
///   - Optional simple bar visualization for accuracy
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final playerStats = ref.watch(playerStatsProvider);
    final totalCards = ref.watch(totalCardsPlayedProvider);
    final totalCorrect = ref.watch(totalCorrectAnswersProvider);
    final overallAccuracy = ref.watch(overallAccuracyProvider);
    final bestStreak = ref.watch(allTimeBestStreakProvider);

    final overallPercentage = (overallAccuracy).clamp(0.0, 1.0) * 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.statsTitle(language),
          style: AppTypography.headlineMedium,
        ),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overall stats
              _OverallStatsSection(
                language: language,
                totalCards: totalCards,
                totalCorrect: totalCorrect,
                overallPercentage: overallPercentage,
                bestStreak: bestStreak,
                totalQuestionsAttempted: playerStats.totalQuestionsAttempted,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Per-category breakdown
              Text(
                AppStrings.categoryStats(language),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Column(
                children: Category.values.map((category) {
                  final stats = ref.watch(categoryStatsProvider(category));
                  final difficulty =
                      ref.watch(categoryDifficultyProvider(category));
                  final accuracy =
                      ref.watch(categoryAccuracyProvider(category));
                  final attempted = stats.attempted;
                  final percentage = accuracy.clamp(0.0, 100.0);

                  return _CategoryStatsRow(
                    category: category,
                    language: language,
                    difficulty: difficulty,
                    attempted: attempted,
                    percentage: percentage,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverallStatsSection extends StatelessWidget {
  const _OverallStatsSection({
    required this.language,
    required this.totalCards,
    required this.totalCorrect,
    required this.overallPercentage,
    required this.bestStreak,
    required this.totalQuestionsAttempted,
  });

  final AppLanguage language;
  final int totalCards;
  final int totalCorrect;
  final double overallPercentage;
  final int bestStreak;
  final int totalQuestionsAttempted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.totalCards(language, totalCards),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.totalCorrect(language, totalCorrect),
          style: AppTypography.bodyMedium,
        ),
        if (totalQuestionsAttempted > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.accuracy(language, overallPercentage),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.bestStreak(language, bestStreak),
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

class _CategoryStatsRow extends StatelessWidget {
  const _CategoryStatsRow({
    required this.category,
    required this.language,
    required this.difficulty,
    required this.attempted,
    required this.percentage,
  });

  final Category category;
  final AppLanguage language;
  final Difficulty difficulty;
  final int attempted;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final label = category.localizedName(language);
    final difficultyLabel = difficulty.displayName(language);
    final percentageText = '${percentage.toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium,
                ),
              ),
              Text(
                percentageText,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Simple bar visualization
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final barWidth = maxWidth * (percentage / 100).clamp(0.0, 1.0);

              return Container(
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.borderDefault,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: barWidth,
                    color: category.color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),

          // Meta row: difficulty + attempted
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.currentDifficulty(language, difficultyLabel),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${attempted.toString()} '
                '${language == AppLanguage.sv ? "försök" : "attempts"}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
