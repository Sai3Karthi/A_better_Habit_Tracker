# Color System Guide

## Overview
The app now uses a unified color system with three layers:

1. **Color Palette** - Base colors defined in `color_palette.dart`
2. **HabitTheme** - Theme extension that uses the color palette
3. **ThemeManager** - Utility to access colors throughout the app

## How to Use the Color System

### 1. Direct Access to Color Palette
Use `AppColors` class for direct access to raw colors:

```dart
import 'themes/color_palette.dart';

// Examples
final blue = AppColors.blue;
final white = AppColors.white;
final grey800 = AppColors.grey800;
```

### 2. Using Theme Colors in Widgets
Get theme colors through the context:

```dart
import 'themes/habit_theme.dart';

// In a widget build method
final habitTheme = HabitTheme.of(context);
final completedColor = habitTheme.habitCompleted;
final cardBorder = habitTheme.cardBorder;
```

### 3. Using ThemeManager (Recommended)
Use the ThemeManager for consistent access:

```dart
import 'themes/theme_manager.dart';

// Get a theme color
final completedColor = ThemeManager.getColor(context, ThemeColor.statusCompleted);

// Get a palette color directly
final blue = ThemeManager.getPaletteColor(PaletteColor.blue);
```

## Modifying Colors

To change colors throughout the app:

1. Edit the base colors in `color_palette.dart`
2. All components using those colors will automatically update

## Color Categories

### Base Colors
- Black, white, transparent

### Grey Scale
- grey100 through grey900 (lightest to darkest)

### Primary Colors
- blue, green, orange, red, purple

### Functional Colors
- Streak colors (fire, lightning)
- Achievement colors (bronze, silver, gold, platinum)
- Status colors (completed, partial, missed, empty, excluded, future)
- UI elements (backgrounds, borders, buttons, text) 