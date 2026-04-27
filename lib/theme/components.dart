import 'package:flutter/material.dart';
import 'colors.dart';

class AppComponents {
  // Ambient Shadows
  static List<BoxShadow> get ambientShadow => [
    BoxShadow(
      color: AppColors.onSurface.withValues(alpha: 0.06),
      blurRadius: 32.0,
      spreadRadius: -4.0,
      offset: const Offset(0, 8),
    )
  ];

  // Ghost Border
  static Border get ghostBorder => Border.all(
    color: AppColors.outlineVariant.withValues(alpha: 0.15),
    width: 1.0,
  );

  // Glassmorphism Box Decoration
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(24.0),
    border: ghostBorder,
  );

  // Primary Button Style (Gradient & Rounded)
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent, // Handled by gradient container 
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24.0), // xl (1.5rem) roundedness
    ),
  );

  // Secondary Button
  static final ButtonStyle secondaryButton = FilledButton.styleFrom(
    backgroundColor: AppColors.secondaryContainer,
    foregroundColor: AppColors.onSecondaryContainer,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
    elevation: 0,
  );

  // Input Decoration
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceContainer,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0), // md rounded
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1.0,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  );
}
