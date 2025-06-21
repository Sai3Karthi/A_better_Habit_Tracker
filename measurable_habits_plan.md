# Phase 3A.2.1: Measurable Habits Streak Logic & Customizable Color System Plan

## Current Issue Analysis
- Measurable habits are correctly tracking daily values (0,1,2,3...) 
- Progress tracking and completion detection works properly
- **PROBLEM**: Streak calculations return 0 for measurable habits because they don't have boolean completion entries in `completedDates`
- Current and longest streak methods only check for true/false completion states

## 1. Fix Measurable Habits Streak Logic

### 1.1 Core Problem
```dart
// Current logic only works for simple habits
bool isCompleted = completedDates[dateKey] == true;

// Measurable habits store int values: {dateKey: progressValue}
// When progressValue >= targetValue, habit should count as "completed" for streaks
```

### 1.2 Solution Implementation
- Modify `getCurrentStreak()` and `getLongestStreak()` methods in `habit.dart`
- Add streak-specific completion check that works for both habit types
- Ensure backward compatibility with existing simple habits

### 1.3 Updated Streak Logic
```dart
bool _isCompletedForDate(String dateKey) {
  if (type == HabitType.simple) {
    return completedDates[dateKey] == true;
  } else {
    final int progress = dailyValues[dateKey] ?? 0;
    return progress >= targetValue;
  }
}
```

## 2. Customizable Color System Architecture

### 2.1 Research Summary: Modern Flutter Theming 2024

Based on research, implement these approaches:

#### Material Design 3 Features:
- **Dynamic Color**: ColorScheme.fromSeed() with multiple seed colors
- **Theme Extensions**: Custom semantic colors beyond Material colors  
- **Adaptive Themes**: Platform-specific design responses
- **Color Harmonization**: Blend custom colors toward primary for cohesion

#### Advanced Theming Packages:
- **flex_seed_scheme**: Multi-seed ColorScheme generation
- **FlexColorScheme**: Advanced theming with 40+ built-in schemes
- **Riverpod**: Reactive theme state management with persistence

#### Greyscale/Focus Mode Benefits:
- Reduces visual distractions for ADHD/focus users
- Improves accessibility for color-blind users  
- Battery saving on OLED displays
- Professional/minimal aesthetic option

### 2.2 Proposed Color System Structure

```
lib/
├── theme/
│   ├── color_system/
│   │   ├── app_color_scheme.dart      # Dynamic ColorScheme generation
│   │   ├── color_tokens.dart          # Design token constants
│   │   ├── theme_variants.dart        # Pre-built theme collections
│   │   └── color_extensions.dart      # Custom semantic colors
│   ├── adaptive/
│   │   ├── platform_themes.dart       # Platform-specific adaptations
│   │   └── greyscale_theme.dart      # Focus-friendly greyscale
│   ├── providers/
│   │   ├── theme_providers.dart       # Riverpod theme state
│   │   └── theme_persistence.dart     # Save/load theme preferences
│   └── theme_builder.dart            # Central theme construction
```

### 2.3 Implementation Strategy

#### Phase 1: Color Token Foundation
- Extract all hardcoded colors to centralized design tokens
- Create semantic color naming (primary, secondary, success, warning, etc.)
- Implement theme-aware color resolution

#### Phase 2: Dynamic ColorScheme System  
- **Multi-seed generation**: Primary habit color + accent colors
- **Adaptive tinting**: Different surface tinting per platform
- **Color harmonization**: Ensure custom colors blend with scheme

#### Phase 3: Theme Variants & Extensions
- **Built-in variants**: Light, Dark, High-contrast, Greyscale  
- **Custom themes**: User-defined color combinations
- **Semantic extensions**: Habit status colors, achievement colors

#### Phase 4: Greyscale Focus Mode
- **Intelligent conversion**: Preserve contrast ratios in greyscale
- **User controls**: Toggle between full-color and greyscale
- **Smart accents**: Minimal color hints for critical status

#### Phase 5: Theme Management
- **State management**: Riverpod providers for reactive theming
- **Persistence**: Save user preferences locally
- **Live preview**: Real-time theme switching

## 3. Detailed Implementation Plan

### 3.1 Color Tokens Structure
```dart
// color_tokens.dart
class AppColorTokens {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentBlue = Color(0xFF1976D2); 
  static const Color warningAmber = Color(0xFFF57C00);
  
  // Semantic Colors  
  static const Color habitSuccess = Color(0xFF4CAF50);
  static const Color habitMissed = Color(0xFFF44336);
  static const Color streakFire = Color(0xFFFF6F00);
  
  // Greyscale Palette
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey900 = Color(0xFF212121);
}
```

### 3.2 Dynamic ColorScheme Builder
```dart
// app_color_scheme.dart  
class AppColorSchemes {
  static ColorScheme buildScheme({
    required Brightness brightness,
    Color? primarySeed,
    Color? secondarySeed,
    bool useGreyscale = false,
  }) {
    if (useGreyscale) {
      return _buildGreyscaleScheme(brightness);
    }
    
    return _buildColorfulScheme(
      brightness: brightness,
      primarySeed: primarySeed ?? AppColorTokens.primaryGreen,
      secondarySeed: secondarySeed,
    );
  }
}
```

### 3.3 Theme Extensions for Habits
```dart
// color_extensions.dart
class HabitColorExtension extends ThemeExtension<HabitColorExtension> {
  final Color completedHabit;
  final Color partialHabit; 
  final Color missedHabit;
  final Color streakBadge;
  final Color achievementGold;
  
  // Implementation with lerp, copyWith, etc.
}
```

### 3.4 Greyscale Theme System
```dart
// greyscale_theme.dart
class GreyscaleTheme {
  static ThemeData build(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: brightness == Brightness.light 
        ? AppColorTokens.grey900 
        : AppColorTokens.grey50,
      brightness: brightness,
    );
    
    // Override with greyscale-only colors
    return ThemeData(
      colorScheme: baseScheme.copyWith(
        primary: _getGreyscalePrimary(brightness),
        secondary: _getGreyscaleSecondary(brightness),
        // Preserve only essential accent for critical states
        error: brightness == Brightness.light 
          ? Colors.red.shade800 
          : Colors.red.shade300,
      ),
      extensions: [
        HabitColorExtension.greyscale(brightness),
      ],
    );
  }
}
```

### 3.5 Riverpod Theme Providers
```dart
// theme_providers.dart
final themeVariantProvider = StateProvider<ThemeVariant>(
  (ref) => ThemeVariant.standard,
);

final isGreyscaleModeProvider = StateProvider<bool>(
  (ref) => false,
);

final lightThemeProvider = Provider<ThemeData>((ref) {
  final variant = ref.watch(themeVariantProvider);
  final isGreyscale = ref.watch(isGreyscaleModeProvider);
  
  if (isGreyscale) {
    return GreyscaleTheme.build(Brightness.light);
  }
  
  return AppThemes.buildLight(variant);
});
```

## 4. Implementation Checklist

### Phase 1: Streak Logic Fix (Immediate)
- [ ] Update `getCurrentStreak()` method for measurable habits
- [ ] Update `getLongestStreak()` method for measurable habits  
- [ ] Add `_isCompletedForDate()` helper method
- [ ] Test streak calculations with measurable habits
- [ ] Verify backward compatibility with simple habits

### Phase 2: Color Foundation (Week 1)
- [ ] Create `color_tokens.dart` with all app colors
- [ ] Implement `AppColorSchemes` class  
- [ ] Create theme extension for habit-specific colors
- [ ] Update existing widgets to use new color system
- [ ] Test color consistency across app

### Phase 3: Greyscale Theme (Week 1)  
- [ ] Implement `GreyscaleTheme` builder
- [ ] Create greyscale variants of habit colors
- [ ] Add accessibility contrast validation
- [ ] Implement toggle UI for greyscale mode
- [ ] Test usability in greyscale mode

### Phase 4: Theme Management (Week 2)
- [ ] Setup Riverpod theme providers
- [ ] Implement theme persistence with Hive
- [ ] Create theme selection UI
- [ ] Add live theme preview
- [ ] Test theme switching performance

### Phase 5: Advanced Features (Week 2)
- [ ] Multi-seed ColorScheme generation
- [ ] Platform-adaptive theming
- [ ] Custom theme creation UI
- [ ] Theme import/export functionality
- [ ] Performance optimization

## 5. Success Metrics

### Measurable Habits Fix:
- [ ] Streaks display correctly for measurable habits  
- [ ] Achievement milestones trigger properly
- [ ] UI shows accurate "days to next milestone"
- [ ] No regression in simple habit functionality

### Color System:
- [ ] Full customization of all app colors
- [ ] Seamless theme switching without rebuilds
- [ ] Greyscale mode maintains full functionality
- [ ] Theme preferences persist across app restarts
- [ ] Accessible contrast ratios in all modes

## 6. Future Extensibility

This architecture enables:
- **Dynamic themes**: Generate themes from user photos
- **Community themes**: Share custom themes with other users  
- **Seasonal themes**: Auto-switching based on time/season
- **Brand integration**: Automatically adapt to system accent colors
- **Accessibility modes**: High contrast, deuteranopia-friendly, etc.

## Next Steps
1. Fix measurable habits streak logic immediately
2. Begin color token extraction and centralization
3. Implement greyscale theme foundation
4. Set up theme state management infrastructure
5. Iterate based on user feedback and usability testing 