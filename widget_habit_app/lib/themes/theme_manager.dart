import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme_type.dart';
import 'habit_theme.dart';
import 'greyscale_theme.dart';

/// Service for managing application themes and user preferences
class ThemeManager extends ChangeNotifier {
  static const String _themePreferenceKey = 'selected_theme';
  static const String _customColorKey = 'custom_seed_color';

  AppThemeType _currentTheme = AppThemeType.light;
  Color? _customSeedColor;
  bool _isInitialized = false;

  // Getters
  AppThemeType get currentTheme => _currentTheme;
  Color? get customSeedColor => _customSeedColor;
  bool get isInitialized => _isInitialized;
  bool get isGreyscaleMode => _currentTheme == AppThemeType.greyscale;
  bool get isCustomMode => _currentTheme == AppThemeType.custom;

  /// Initialize the theme manager and load saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme type
      final savedThemeIndex = prefs.getInt(_themePreferenceKey);
      if (savedThemeIndex != null &&
          savedThemeIndex < AppThemeType.values.length) {
        _currentTheme = AppThemeType.values[savedThemeIndex];
      }

      // Load custom color if it exists
      final savedColorValue = prefs.getInt(_customColorKey);
      if (savedColorValue != null) {
        _customSeedColor = Color(savedColorValue);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ThemeManager: $e');
      _isInitialized =
          true; // Still mark as initialized to prevent infinite retry
    }
  }

  /// Change the current theme
  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Set a custom seed color for the custom theme
  Future<void> setCustomSeedColor(Color color) async {
    _customSeedColor = color;
    await _saveCustomColor();

    // Auto-switch to custom theme when color is set
    if (_currentTheme != AppThemeType.custom) {
      await setTheme(AppThemeType.custom);
    } else {
      notifyListeners();
    }
  }

  /// Toggle between normal and greyscale mode (quick action)
  Future<void> toggleGreyscaleMode() async {
    if (_currentTheme == AppThemeType.greyscale) {
      await setTheme(AppThemeType.light); // Return to light mode
    } else {
      await setTheme(AppThemeType.greyscale); // Switch to greyscale
    }
  }

  /// Generate ThemeData for the current theme and brightness
  ThemeData getThemeData(Brightness brightness) {
    final baseTheme = _buildBaseTheme(brightness);
    final habitTheme = _buildHabitTheme(brightness);

    return baseTheme.copyWith(extensions: [habitTheme]);
  }

  /// Build base Material Design theme
  ThemeData _buildBaseTheme(Brightness brightness) {
    switch (_currentTheme) {
      case AppThemeType.greyscale:
        return _buildGreyscaleBaseTheme(brightness);
      case AppThemeType.custom:
        return _buildCustomBaseTheme(brightness);
      case AppThemeType.dark:
        return _buildDarkBaseTheme();
      case AppThemeType.light:
        return _buildLightBaseTheme();
    }
  }

  /// Build HabitTheme extension for current theme
  HabitTheme _buildHabitTheme(Brightness brightness) {
    switch (_currentTheme) {
      case AppThemeType.greyscale:
        return brightness == Brightness.dark
            ? GreyscaleTheme.dark()
            : GreyscaleTheme.light();
      case AppThemeType.custom:
        return _buildCustomHabitTheme(brightness);
      case AppThemeType.dark:
        return _buildDarkHabitTheme();
      case AppThemeType.light:
        return _buildLightHabitTheme();
    }
  }

  // Base theme builders
  ThemeData _buildLightBaseTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF),
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData _buildDarkBaseTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF),
        brightness: Brightness.dark,
      ),
    );
  }

  ThemeData _buildGreyscaleBaseTheme(Brightness brightness) {
    // Greyscale base theme with minimal colors
    final seedColor = brightness == Brightness.dark
        ? const Color(0xFF404040)
        : const Color(0xFF808080);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
    );
  }

  ThemeData _buildCustomBaseTheme(Brightness brightness) {
    final seedColor = _customSeedColor ?? const Color(0xFF007AFF);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
    );
  }

  // HabitTheme builders
  HabitTheme _buildLightHabitTheme() {
    return HabitTheme.defaultLightTheme();
  }

  HabitTheme _buildDarkHabitTheme() {
    // Create a dark variant of the default theme
    return const HabitTheme(
      // Streak Colors - Adapted for dark
      streakFireColor: Color(0xFFFF8A65), // Lighter orange
      streakLightningColor: Color(0xFF42A5F5), // Lighter blue
      // Achievement Colors
      achievementBronze: Color(0xFFDDBF94), // Lighter bronze
      achievementSilver: Color(0xFF87CEEB), // Light steel blue
      achievementGold: Color(0xFFDAA520), // Goldenrod
      achievementPlatinum: Color(0xFFBA68C8), // Light purple
      // Habit Status Colors
      habitCompleted: Color(0xFF66BB6A), // Light green
      habitPartial: Color(0xFFFFB74D), // Light orange
      habitMissed: Color(0xFFEF5350), // Light red
      habitEmpty: Color(0xFF757575), // Medium grey
      habitExcluded: Color(0xFF616161), // Dark grey
      habitFuture: Color(0xFF424242), // Darker grey
      // Progress Indicators
      progressRingComplete: Color(0xFF66BB6A), // Light green
      progressRingPartial: Color(0xFFFFB74D), // Light orange
      progressBackground: Color(0xFF424242), // Dark grey
      // UI Elements
      cardBackground: Color(0xFF1E1E1E), // Dark card
      cardBorder: Color(0xFF424242), // Dark border
      cardSelectedBorder: Color(0xFF42A5F5), // Blue
      buttonPrimary: Color(0xFF42A5F5), // Blue
      buttonSecondary: Color(0xFF757575), // Grey
      textPrimary: Color(0xFFFFFFFF), // White
      textSecondary: Color(0xFFBDBDBD), // Light grey
      textHint: Color(0xFF757575), // Medium grey
    );
  }

  HabitTheme _buildCustomHabitTheme(Brightness brightness) {
    final seedColor = _customSeedColor ?? const Color(0xFF007AFF);

    // Generate a habit theme based on the seed color
    // This is a simplified version - in future, we could use more sophisticated color generation
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return HabitTheme(
      // Use generated colors from the color scheme
      streakFireColor: colorScheme.primary,
      streakLightningColor: colorScheme.secondary,
      achievementBronze: colorScheme.tertiary,
      achievementSilver: colorScheme.secondary,
      achievementGold: colorScheme.primary,
      achievementPlatinum: colorScheme.inversePrimary,
      habitCompleted: colorScheme.primary,
      habitPartial: colorScheme.secondary,
      habitMissed: colorScheme.error,
      habitEmpty: colorScheme.outline,
      habitExcluded: colorScheme.outlineVariant,
      habitFuture: colorScheme.surfaceContainerHighest,
      progressRingComplete: colorScheme.primary,
      progressRingPartial: colorScheme.secondary,
      progressBackground: colorScheme.surfaceContainerHigh,
      cardBackground: colorScheme.surface,
      cardBorder: colorScheme.outline,
      cardSelectedBorder: colorScheme.primary,
      buttonPrimary: colorScheme.primary,
      buttonSecondary: colorScheme.secondary,
      textPrimary: colorScheme.onSurface,
      textSecondary: colorScheme.onSurfaceVariant,
      textHint: colorScheme.outline,
    );
  }

  // Persistence methods
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, _currentTheme.index);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  Future<void> _saveCustomColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customSeedColor != null) {
        await prefs.setInt(_customColorKey, _customSeedColor!.toARGB32());
      }
    } catch (e) {
      debugPrint('Error saving custom color: $e');
    }
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    _currentTheme = AppThemeType.light;
    _customSeedColor = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themePreferenceKey);
      await prefs.remove(_customColorKey);
    } catch (e) {
      debugPrint('Error resetting theme: $e');
    }

    notifyListeners();
  }
}
