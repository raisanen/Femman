import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/providers/settings_providers.dart';
import 'package:femman/providers/stats_providers.dart';

/// Minimal settings screen.
///
/// - Language toggle (Swedish / English)
/// - Reset stats option (with confirmation)
/// - App version display
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _appVersion = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.settingsTitle(language),
          style: AppTypography.headlineMedium,
        ),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language toggle label
              Text(
                AppStrings.languageLabel(language),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Language segmented control
              Row(
                children: [
                  _LanguageChip(
                    label: AppStrings.languageSwedish(language),
                    selected: language == AppLanguage.sv,
                    onTap: () {
                      ref
                          .read(languageProvider.notifier)
                          .setLanguage(AppLanguage.sv);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _LanguageChip(
                    label: AppStrings.languageEnglish(language),
                    selected: language == AppLanguage.en,
                    onTap: () {
                      ref
                          .read(languageProvider.notifier)
                          .setLanguage(AppLanguage.en);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Reset stats
              TextButton(
                onPressed: () => _confirmResetStats(context, ref, language),
                child: Text(
                  language == AppLanguage.sv ? 'Återställ statistik' : 'Reset stats',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const Spacer(),

              // App version
              Text(
                language == AppLanguage.sv ? 'Version $_appVersion' : 'Version $_appVersion',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmResetStats(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    final title =
        language == AppLanguage.sv ? 'Återställ statistik?' : 'Reset stats?';
    final message = language == AppLanguage.sv
        ? 'Detta raderar all din spelstatistik. Är du säker?'
        : 'This will erase all your game statistics. Are you sure?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: AppTypography.headlineMedium,
          ),
          content: Text(
            message,
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.cancel(language)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                language == AppLanguage.sv ? 'ÅTERSTÄLL' : 'RESET',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(statsNotifierProvider.notifier).resetStats();
    }
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.white,
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.labelMedium.copyWith(
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
