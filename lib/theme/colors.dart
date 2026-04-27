import 'package:flutter/material.dart';

class AppColors {
  // Base Surface Colors
  static const Color background = Color(0xFFF7F9FB);
  static const Color surfaceContainerLow = Color(0xFFF0F4F7);
  static const Color surfaceContainer = Color(0xFFEAEFF2);
  static const Color surfaceContainerHigh = Color(0xFFE3E9ED);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Brand Colors
  static const Color primary = Color(0xFF005CC0);
  static const Color primaryContainer = Color(0xFF4287F5);
  static const Color onPrimary = Color(0xFFF9F8FF);
  
  static const Color secondary = Color(0xFF5A5899);
  static const Color secondaryContainer = Color(0xFFE3DFFF);
  static const Color onSecondaryContainer = Color(0xFF4D4A8A);

  static const Color tertiary = Color(0xFF645A7A);
  static const Color tertiaryContainer = Color(0xFFE4D7FD);

  // Text Colors
  static const Color onSurface = Color(0xFF2C3437);
  static const Color onSurfaceVariant = Color(0xFF596064);

  // Other UI colors
  static const Color outline = Color(0xFF747C80);
  static const Color outlineVariant = Color(0xFFACB3B7); // Ghost border
  static const Color error = Color(0xFFA83836);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onError = Color(0xFFFFF7F6);

  // Signature Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
