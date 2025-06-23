import 'package:flutter/material.dart';

/// Central color palette for the entire application
/// All colors should be defined here and referenced elsewhere
class AppColors {
  // Base colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  // Grey scale
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Primary colors
  static const Color blue = Color(0xFF42A5F5);
  static const Color green = Color(0xFF66BB6A);
  static const Color orange = Color(0xFFFFB74D);
  static const Color red = Color(0xFFEF5350);
  static const Color purple = Color(0xFFBA68C8);

  // Streak colors
  static const Color streakFire = Color(0xFFFF8A65);
  static const Color streakLightning = Color.fromARGB(255, 224, 141, 51);

  // Achievement colors
  static const Color achievementBronze = Color.fromARGB(255, 139, 106, 61);
  static const Color achievementSilver = Color.fromARGB(255, 160, 178, 185);
  static const Color achievementGold = Color(0xFFDAA520);
  static const Color achievementPlatinum = Color.fromARGB(255, 86, 18, 98);

  // Status colors
  static const Color statusCompleted = Color.fromARGB(255, 43, 200, 51);
  static const Color statusPartial = orange;
  static const Color statusMissed = red;
  static const Color statusEmpty = Color.fromARGB(255, 255, 255, 255);
  static const Color statusExcluded = grey700;
  static const Color statusFuture = grey800;

  // UI elements
  static const Color cardBorder = Color.fromARGB(255, 255, 255, 255);
  static const Color cardSelectedBorder = blue;
  static const Color buttonPrimary = blue;
  static const Color buttonSecondary = grey600;
  static const Color textPrimary = white;
  static const Color textSecondary = grey400;
  static const Color textHint = grey600;

  // Progress indicators
  static const Color progressComplete = Color.fromARGB(255, 56, 192, 63);
  static const Color progressPartial = orange;
  static const Color progressBackground = Color.fromARGB(174, 140, 140, 140);
}
