import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  // Using default TextStyle with specified settings to mimic Inter 
  // (Assuming Inter is added to pubspec or we use default robust sans-serif for now)
  
  // Hero Statements
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 56.0, // 3.5rem equivalent
    height: 1.1,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -1.0,
  );

  // Primary Page Titles
  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32.0, // 2rem equivalent
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );

  // Data / Body
  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0, // 0.875rem equivalent
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // Smaller body text
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // Card Headers and Nav Labels
  static const TextStyle titleSm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16.0, // 1rem equivalent
    height: 1.5,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.onSurface,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18.0, 
    fontWeight: FontWeight.w500,
    color: AppColors.onPrimary,
  );
}
