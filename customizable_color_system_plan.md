# Customizable Color System & Greyscale Theme Implementation Plan

## Research Summary: Modern Flutter Theming (2024)

Based on latest Flutter documentation and Material Design 3:

### Key Technologies:
- **Material Design 3**: Uses ColorScheme with semantic color roles
- **ThemeData.colorScheme**: Central source of truth for all colors
- **ThemeExtensions**: Custom themes that integrate with Material theming
- **Dynamic Color**: Platform-native color generation (Android 12+)
- **Seed Colors**: Generate full ColorScheme from single seed color

### Architecture Pattern:
```dart
// 1. Define custom theme extension
class HabitTheme extends ThemeExtension<HabitTheme> {
  final Color streakColor;
  final Color achievementColor;
  // ... other custom colors
}

// 2. Integrate with Material ColorScheme
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: userSelectedColor),
  extensions: [habitTheme],
)

// 3. Access colors consistently
Theme.of(context).extension<HabitTheme>()!.streakColor
```

## Implementation Plan

### Phase 1: Color System Foundation
**Goal**: Create extensible foundation that supports multiple themes

#### 1.1 Create Theme Models
- `AppThemeType` enum (light, dark, greyscale, custom)
- `HabitColors` class with semantic color definitions
- `ThemePreferences` for user settings storage

#### 1.2 Theme Extension Implementation
```dart
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
  final Color buttonPrimary;
  final Color buttonSecondary;
  
  // Required ThemeExtension methods
  @override
  ThemeExtension<HabitTheme> copyWith({...});
  
  @override
  ThemeExtension<HabitTheme> lerp(ThemeExtension<HabitTheme>? other, double t);
}
```

#### 1.3 Predefined Theme Definitions
Create 4 base themes:
1. **Default Light**: Colorful, vibrant (current behavior)
2. **Default Dark**: Dark mode with accent colors
3. **Greyscale Focus**: Monochrome for minimal distraction
4. **Custom**: User-defined seed color with generated palette

### Phase 2: Greyscale "Focus Nerd" Theme
**Goal**: Distraction-free theme for productivity enthusiasts

#### 2.1 Greyscale Color Palette
```dart
class GreyscaleHabitTheme {
  // High contrast monochrome
  static const Color primary = Color(0xFF1A1A1A);      // Almost black
  static const Color secondary = Color(0xFF4A4A4A);    // Dark grey
  static const Color surface = Color(0xFFF5F5F5);      // Light grey
  static const Color onSurface = Color(0xFF2A2A2A);    // Text
  
  // Streak indicators (subtle contrast)
  static const Color streakActive = Color(0xFF3A3A3A);  // Darker for active
  static const Color streakInactive = Color(0xFFB0B0B0); // Lighter for inactive
  
  // Status indicators (using grayscale + minimal accent)
  static const Color completed = Color(0xFF1A1A1A);     // Black checkmark
  static const Color partial = Color(0xFF6A6A6A);       // Medium grey
  static const Color missed = Color(0xFF8A8A8A);        // Light grey X
  static const Color excluded = Color(0xFFD0D0D0);      // Very light grey
}
```

#### 2.2 Focus-Oriented UX Features
- **Minimal Visual Noise**: Remove all color distractions
- **High Contrast Text**: Excellent readability
- **Subtle Animations**: Reduced motion, fade transitions only
- **Typography Focus**: Strong font weights and clear hierarchy
- **Shape over Color**: Use icons, borders, shadows for distinction

### Phase 3: Theme Management System
**Goal**: User-friendly theme switching with persistence

#### 3.1 Theme Manager Service
```dart
class ThemeManager extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.light;
  Color? _customSeedColor;
  
  // Persist theme choice
  Future<void> setTheme(AppThemeType theme) async {
    _currentTheme = theme;
    await _saveToPreferences();
    notifyListeners();
  }
  
  // Generate ThemeData
  ThemeData getThemeData(Brightness brightness) {
    switch (_currentTheme) {
      case AppThemeType.greyscale:
        return _buildGreyscaleTheme(brightness);
      case AppThemeType.custom:
        return _buildCustomTheme(_customSeedColor!, brightness);
      default:
        return _buildDefaultTheme(brightness);
    }
  }
}
```

#### 3.2 Theme Settings UI
- **Theme Selector**: Radio buttons with live previews
- **Custom Color Picker**: HSV/RGB picker for custom themes
- **Preview Cards**: Show habit cards in each theme
- **Quick Toggle**: Floating action for greyscale mode

### Phase 4: Color Code Refactoring
**Goal**: Replace all hardcoded colors with theme-aware alternatives

#### 4.1 Current Hardcoded Colors to Replace:
- Streak fire emoji colors
- Achievement badge colors  
- Progress ring colors (orange/green)
- Card background colors
- Button colors
- Icon colors

#### 4.2 Refactoring Strategy:
```dart
// OLD: Hardcoded
Color(0xFFFF6B35) // Orange

// NEW: Theme-aware
Theme.of(context).extension<HabitTheme>()!.progressRingPartial
```

### Phase 5: Advanced Features (Future-Ready)
**Goal**: Enterprise-level customization capabilities

#### 5.1 Custom Theme Builder
- **Brand Color Integration**: Company colors
- **Accessibility Compliance**: WCAG AA/AAA support
- **Export/Import**: Share theme configurations
- **Theme Presets**: Seasonal, mood-based themes

#### 5.2 Dynamic Theming
- **Time-based**: Auto-switch to dark/greyscale during focus hours
- **Context-aware**: Different themes for different habit categories
- **System Integration**: Follow Android 12+ Material You

## Implementation Timeline

### Week 1: Foundation
- [ ] Create theme models and extensions
- [ ] Implement ThemeManager service
- [ ] Build greyscale theme definition

### Week 2: UI Integration
- [ ] Replace hardcoded colors in existing widgets
- [ ] Create theme settings screen
- [ ] Add theme persistence

### Week 3: Advanced Features  
- [ ] Custom color picker
- [ ] Theme preview system
- [ ] Polish and testing

### Week 4: Future-Proofing
- [ ] Dynamic theming infrastructure
- [ ] Export/import system
- [ ] Documentation and examples

## File Structure
```
lib/
├── themes/
│   ├── app_theme.dart           # Main theme definitions
│   ├── habit_theme.dart         # Custom theme extension
│   ├── greyscale_theme.dart     # Focus nerd theme
│   ├── theme_manager.dart       # Theme switching logic
│   └── theme_constants.dart     # Color constants
├── screens/
│   └── theme_settings_screen.dart # Theme configuration UI
└── widgets/
    └── theme_preview_card.dart   # Preview widgets
```

## Pre-Requisites for Implementation
1. ✅ **Measurable Habits Streak Logic Fixed** (just completed)
2. 🔄 **Color Audit**: Identify all hardcoded colors
3. 🔄 **Theme Extension Setup**: Create base infrastructure
4. 🔄 **Greyscale Theme Definition**: Design focus-friendly palette
5. 🔄 **Theme Manager Integration**: Connect to existing widgets

This system will allow easy addition of new themes (seasonal, brand-specific, accessibility-focused) while maintaining consistency and performance. 