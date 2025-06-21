enum AppThemeType { light, dark, greyscale, custom }

extension AppThemeTypeExtension on AppThemeType {
  String get displayName {
    switch (this) {
      case AppThemeType.light:
        return 'Light Theme';
      case AppThemeType.dark:
        return 'Dark Theme';
      case AppThemeType.greyscale:
        return 'Greyscale Focus';
      case AppThemeType.custom:
        return 'Custom Theme';
    }
  }

  String get description {
    switch (this) {
      case AppThemeType.light:
        return 'Colorful and vibrant for daily use';
      case AppThemeType.dark:
        return 'Dark mode with accent colors';
      case AppThemeType.greyscale:
        return 'Minimal distraction for focus sessions';
      case AppThemeType.custom:
        return 'Your personalized color scheme';
    }
  }
}
