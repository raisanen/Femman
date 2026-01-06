import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_theme.dart';
import 'package:femman/features/home/home_screen.dart';

/// Root Femman app widget with Riverpod scope and theme.
class FemmanApp extends StatelessWidget {
  const FemmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Femman',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

