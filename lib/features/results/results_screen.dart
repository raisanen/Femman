import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/features/results/widgets/category_breakdown.dart';
import 'package:femman/models/card_result.dart';
import 'package:femman/providers/settings_providers.dart';
import 'package:femman/providers/stats_providers.dart';

/// Results screen shown after completing a card.
///
/// - Large score hero (e.g. "4/5")
/// - "RÄTT SVAR" / "CORRECT" label
/// - Category breakdown with ✓ / ✗
/// - Current streak
/// - Total score (running total of correct answers)
/// - "Next Card" (primary) and "Home" (secondary) actions
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({
    super.key,
    required this.result,
  });

  final CardResult result;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    // Record result to stats service and update streak on mount
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_recorded) return;
      _recorded = true;
      try {
        await ref
            .read(statsNotifierProvider.notifier)
            .recordCardResult(widget.result);
        // Force a rebuild after stats are recorded
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        // Log error but don't crash the UI
        // ignore: avoid_print
        print('Error recording stats: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    // Watch the stats notifier to know when recording is complete
    final statsNotifierState = ref.watch(statsNotifierProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final totalCorrect = ref.watch(totalCorrectAnswersProvider);

    final scoreFraction =
        '${widget.result.score}/${widget.result.results.length}';
    final scoreText = AppStrings.scoreDisplay(
      language,
      widget.result.score,
      widget.result.results.length,
    );

    String subtitle;
    if (widget.result.isPerfect) {
      subtitle = AppStrings.perfectScore(language);
    } else if (widget.result.score >= 3) {
      subtitle = AppStrings.goodScore(language);
    } else {
      subtitle = AppStrings.keepTrying(language);
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppStrings.cardComplete(language),
          style: AppTypography.headlineMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero score
              Center(
                child: Column(
                  children: [
                    Text(
                      scoreFraction,
                      style: AppTypography.displayLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      scoreText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.labelMedium.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // "Correct answers" label
              Text(
                language == AppLanguage.sv ? 'RÄTT SVAR' : 'CORRECT',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category breakdown list
              Expanded(
                child: SingleChildScrollView(
                  child: CategoryBreakdown(
                    result: widget.result,
                    language: language,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Current streak & total score
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.currentStreak(language, currentStreak),
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.totalCorrect(language, totalCorrect),
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Actions at bottom
              ElevatedButton(
                onPressed: () {
                  // Start a new card by replacing with a fresh QuizScreen
                  Navigator.of(context).pushReplacementNamed('/quiz');
                },
                child: Text(AppStrings.nextCardButton(language)),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  // Pop back to home
                  Navigator.of(context).popUntil(
                    (route) => route.settings.name == '/' || route.isFirst,
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
