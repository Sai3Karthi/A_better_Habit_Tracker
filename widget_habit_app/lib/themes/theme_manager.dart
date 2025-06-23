import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'color_palette.dart';
import 'habit_theme.dart';

/// ThemeManager provides centralized access to the app's theme
/// Use this class to get theme values or make theme changes
class ThemeManager {
  // Get the HabitTheme from the BuildContext
  static HabitTheme getTheme(BuildContext context) {
    return HabitTheme.of(context);
  }

  // Get a specific color from the theme
  static Color getColor(BuildContext context, ThemeColor colorType) {
    final theme = getTheme(context);

    switch (colorType) {
      // Streak colors
      case ThemeColor.streakFire:
        return theme.streakFireColor;
      case ThemeColor.streakLightning:
        return theme.streakLightningColor;

      // Achievement colors
      case ThemeColor.achievementBronze:
        return theme.achievementBronze;
      case ThemeColor.achievementSilver:
        return theme.achievementSilver;
      case ThemeColor.achievementGold:
        return theme.achievementGold;
      case ThemeColor.achievementPlatinum:
        return theme.achievementPlatinum;

      // Status colors
      case ThemeColor.statusCompleted:
        return theme.habitCompleted;
      case ThemeColor.statusPartial:
        return theme.habitPartial;
      case ThemeColor.statusMissed:
        return theme.habitMissed;
      case ThemeColor.statusEmpty:
        return theme.habitEmpty;
      case ThemeColor.statusExcluded:
        return theme.habitExcluded;
      case ThemeColor.statusFuture:
        return theme.habitFuture;

      // UI elements
      case ThemeColor.cardBackground:
        return theme.cardBackground;
      case ThemeColor.cardBorder:
        return theme.cardBorder;
      case ThemeColor.cardSelectedBorder:
        return theme.cardSelectedBorder;
      case ThemeColor.buttonPrimary:
        return theme.buttonPrimary;
      case ThemeColor.buttonSecondary:
        return theme.buttonSecondary;
      case ThemeColor.textPrimary:
        return theme.textPrimary;
      case ThemeColor.textSecondary:
        return theme.textSecondary;
      case ThemeColor.textHint:
        return theme.textHint;
    }
  }

  // Get a color directly from the color palette
  static Color getPaletteColor(PaletteColor color) {
    switch (color) {
      case PaletteColor.black:
        return AppColors.black;
      case PaletteColor.white:
        return AppColors.white;
      case PaletteColor.transparent:
        return AppColors.transparent;
      case PaletteColor.blue:
        return AppColors.blue;
      case PaletteColor.green:
        return AppColors.green;
      case PaletteColor.orange:
        return AppColors.orange;
      case PaletteColor.red:
        return AppColors.red;
      case PaletteColor.purple:
        return AppColors.purple;
      case PaletteColor.grey100:
        return AppColors.grey100;
      case PaletteColor.grey200:
        return AppColors.grey200;
      case PaletteColor.grey300:
        return AppColors.grey300;
      case PaletteColor.grey400:
        return AppColors.grey400;
      case PaletteColor.grey500:
        return AppColors.grey500;
      case PaletteColor.grey600:
        return AppColors.grey600;
      case PaletteColor.grey700:
        return AppColors.grey700;
      case PaletteColor.grey800:
        return AppColors.grey800;
      case PaletteColor.grey900:
        return AppColors.grey900;
    }
  }
}

// Enum for theme colors
enum ThemeColor {
  // Streak colors
  streakFire,
  streakLightning,

  // Achievement colors
  achievementBronze,
  achievementSilver,
  achievementGold,
  achievementPlatinum,

  // Status colors
  statusCompleted,
  statusPartial,
  statusMissed,
  statusEmpty,
  statusExcluded,
  statusFuture,

  // UI elements
  cardBackground,
  cardBorder,
  cardSelectedBorder,
  buttonPrimary,
  buttonSecondary,
  textPrimary,
  textSecondary,
  textHint,
}

// Enum for palette colors
enum PaletteColor {
  // Base colors
  black,
  white,
  transparent,

  // Primary colors
  blue,
  green,
  orange,
  red,
  purple,

  // Grey scale
  grey100,
  grey200,
  grey300,
  grey400,
  grey500,
  grey600,
  grey700,
  grey800,
  grey900,
}

// Provider for the theme manager
final themeManagerProvider = Provider<ThemeManager>((ref) {
  return ThemeManager();
});
