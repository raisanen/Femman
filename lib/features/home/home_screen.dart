import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/providers/settings_providers.dart';

/// Minimal Swiss-typography-inspired home screen.
///
/// - Prominent FEMMAN title
/// - Primary "Play" action
/// - Secondary "Stats" action
/// - Tertiary "Settings" icon button
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App title
                Text(
                  AppStrings.appTitle(language).toUpperCase(),
                  style: AppTypography.displayLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Play (primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/quiz');
                    },
                    child: Text(
                      AppStrings.playButton(language),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Stats (secondary)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderDefault),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/stats');
                    },
                    child: Text(
                      AppStrings.statsButton(language),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Settings (tertiary icon button)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: AppStrings.settingsButton(language),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/settings');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
