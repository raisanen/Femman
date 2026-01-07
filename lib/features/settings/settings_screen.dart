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

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppStrings.settingsTitle(language),
          style: AppTypography.headlineMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),

              const Spacer(),

              // App version
              Text(
                language == AppLanguage.sv ? 'Version $_appVersion' : 'Version $_appVersion',
                style: AppTypography.labelMedium.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
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
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              color: dialogTheme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: dialogTheme.colorScheme.onSurface,
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDefaultDark : AppColors.borderDefault;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.white;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : backgroundColor,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.labelMedium.copyWith(
                color: selected ? AppColors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
