import 'package:flutter/material.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/features/results/widgets/score_display.dart';
import 'package:femman/features/results/widgets/category_breakdown.dart';
import 'package:femman/features/home/home_screen.dart';
import 'package:femman/models/card_result.dart';
import 'package:femman/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Results screen shown after completing a card.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({
    super.key,
    required this.result,
  });

  final CardResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.cardComplete(language),
          style: AppTypography.headlineMedium,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score
              ScoreDisplay(result: result, language: language),
              const SizedBox(height: AppSpacing.xl),

              // Category breakdown
              Expanded(
                child: CategoryBreakdown(
                  result: result,
                  language: language,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Actions
              ElevatedButton(
                onPressed: () {
                  // Start a new card by popping to home and navigating to quiz again
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(AppStrings.nextCardButton(language)),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(AppStrings.homeButton(language)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
