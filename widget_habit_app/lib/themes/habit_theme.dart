import 'package:flutter/material.dart';

/// Custom theme extension for habit-specific colors
/// This extends ThemeExtension to integrate with Material Design 3
class HabitTheme extends ThemeExtension<HabitTheme> {
  // Streak & Achievement Colors
  final Color streakFireColor;
  final Color streakLightningColor;
  final Color achievementBronze;
  final Color achievementSilver;
  final Color achievementGold;
  final Color achievementPlatinum;

  // Habit Status Colors
  final Color habitCompleted;
  final Color habitPartial;
  final Color habitMissed;
  final Color habitEmpty;
  final Color habitExcluded;
  final Color habitFuture;

  // Progress Indicators
  final Color progressRingComplete;
  final Color progressRingPartial;
  final Color progressBackground;

  // UI Elements
  final Color cardBackground;
  final Color cardBorder;
  final Color cardSelectedBorder;
  final Color buttonPrimary;
  final Color buttonSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // Constructors
  const HabitTheme({
    required this.streakFireColor,
    required this.streakLightningColor,
    required this.achievementBronze,
    required this.achievementSilver,
    required this.achievementGold,
    required this.achievementPlatinum,
    required this.habitCompleted,
    required this.habitPartial,
    required this.habitMissed,
    required this.habitEmpty,
    required this.habitExcluded,
    required this.habitFuture,
    required this.progressRingComplete,
    required this.progressRingPartial,
    required this.progressBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardSelectedBorder,
    required this.buttonPrimary,
    required this.buttonSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  @override
  ThemeExtension<HabitTheme> copyWith({
    Color? streakFireColor,
    Color? streakLightningColor,
    Color? achievementBronze,
    Color? achievementSilver,
    Color? achievementGold,
    Color? achievementPlatinum,
    Color? habitCompleted,
    Color? habitPartial,
    Color? habitMissed,
    Color? habitEmpty,
    Color? habitExcluded,
    Color? habitFuture,
    Color? progressRingComplete,
    Color? progressRingPartial,
    Color? progressBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? cardSelectedBorder,
    Color? buttonPrimary,
    Color? buttonSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
  }) {
    return HabitTheme(
      streakFireColor: streakFireColor ?? this.streakFireColor,
      streakLightningColor: streakLightningColor ?? this.streakLightningColor,
      achievementBronze: achievementBronze ?? this.achievementBronze,
      achievementSilver: achievementSilver ?? this.achievementSilver,
      achievementGold: achievementGold ?? this.achievementGold,
      achievementPlatinum: achievementPlatinum ?? this.achievementPlatinum,
      habitCompleted: habitCompleted ?? this.habitCompleted,
      habitPartial: habitPartial ?? this.habitPartial,
      habitMissed: habitMissed ?? this.habitMissed,
      habitEmpty: habitEmpty ?? this.habitEmpty,
      habitExcluded: habitExcluded ?? this.habitExcluded,
      habitFuture: habitFuture ?? this.habitFuture,
      progressRingComplete: progressRingComplete ?? this.progressRingComplete,
      progressRingPartial: progressRingPartial ?? this.progressRingPartial,
      progressBackground: progressBackground ?? this.progressBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      cardSelectedBorder: cardSelectedBorder ?? this.cardSelectedBorder,
      buttonPrimary: buttonPrimary ?? this.buttonPrimary,
      buttonSecondary: buttonSecondary ?? this.buttonSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
    );
  }

  @override
  ThemeExtension<HabitTheme> lerp(
    covariant ThemeExtension<HabitTheme>? other,
    double t,
  ) {
    if (other is! HabitTheme) {
      return this;
    }

    return HabitTheme(
      streakFireColor: Color.lerp(streakFireColor, other.streakFireColor, t)!,
      streakLightningColor: Color.lerp(
        streakLightningColor,
        other.streakLightningColor,
        t,
      )!,
      achievementBronze: Color.lerp(
        achievementBronze,
        other.achievementBronze,
        t,
      )!,
      achievementSilver: Color.lerp(
        achievementSilver,
        other.achievementSilver,
        t,
      )!,
      achievementGold: Color.lerp(achievementGold, other.achievementGold, t)!,
      achievementPlatinum: Color.lerp(
        achievementPlatinum,
        other.achievementPlatinum,
        t,
      )!,
      habitCompleted: Color.lerp(habitCompleted, other.habitCompleted, t)!,
      habitPartial: Color.lerp(habitPartial, other.habitPartial, t)!,
      habitMissed: Color.lerp(habitMissed, other.habitMissed, t)!,
      habitEmpty: Color.lerp(habitEmpty, other.habitEmpty, t)!,
      habitExcluded: Color.lerp(habitExcluded, other.habitExcluded, t)!,
      habitFuture: Color.lerp(habitFuture, other.habitFuture, t)!,
      progressRingComplete: Color.lerp(
        progressRingComplete,
        other.progressRingComplete,
        t,
      )!,
      progressRingPartial: Color.lerp(
        progressRingPartial,
        other.progressRingPartial,
        t,
      )!,
      progressBackground: Color.lerp(
        progressBackground,
        other.progressBackground,
        t,
      )!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardSelectedBorder: Color.lerp(
        cardSelectedBorder,
        other.cardSelectedBorder,
        t,
      )!,
      buttonPrimary: Color.lerp(buttonPrimary, other.buttonPrimary, t)!,
      buttonSecondary: Color.lerp(buttonSecondary, other.buttonSecondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
    );
  }

  // Helper method to get the theme from context
  static HabitTheme of(BuildContext context) {
    return Theme.of(context).extension<HabitTheme>() ??
        _defaultLightTheme(); // Fallback to default
  }

  // Public method to get default light theme
  static HabitTheme defaultLightTheme() {
    return _defaultLightTheme();
  }

  // Default light theme factory
  static HabitTheme _defaultLightTheme() {
    return const HabitTheme(
      // Streak Colors
      streakFireColor: Color(0xFFFF6B35), // Orange-red
      streakLightningColor: Color(0xFF007AFF), // Blue
      // Achievement Colors (matching current tier colors)
      achievementBronze: Color(0xFFCD853F), // Peru
      achievementSilver: Color(0xFF4682B4), // Steel Blue
      achievementGold: Color(0xFFB8860B), // Dark Goldenrod
      achievementPlatinum: Color(0xFF9932CC), // Dark Orchid
      // Habit Status Colors
      habitCompleted: Color(0xFF4CAF50), // Green
      habitPartial: Color(0xFFFF9500), // Orange
      habitMissed: Color(0xFFFF5722), // Red-Orange
      habitEmpty: Color(0xFF9E9E9E), // Grey
      habitExcluded: Color(0xFFBDBDBD), // Light Grey
      habitFuture: Color(0xFFE0E0E0), // Very Light Grey
      // Progress Indicators
      progressRingComplete: Color(0xFF4CAF50), // Green
      progressRingPartial: Color(0xFFFF9500), // Orange
      progressBackground: Color(0xFFE0E0E0), // Light Grey
      // UI Elements
      cardBackground: Color(0xFFFFFFFF), // White
      cardBorder: Color(0xFFE0E0E0), // Light Grey
      cardSelectedBorder: Color(0xFF007AFF), // Blue
      buttonPrimary: Color(0xFF007AFF), // Blue
      buttonSecondary: Color(0xFF6C757D), // Grey
      textPrimary: Color(0xFF212529), // Dark Grey
      textSecondary: Color(0xFF6C757D), // Medium Grey
      textHint: Color(0xFF9E9E9E), // Light Grey
    );
  }
}
