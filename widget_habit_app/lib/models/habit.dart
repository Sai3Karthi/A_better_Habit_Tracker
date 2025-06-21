import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
enum HabitType {
  @HiveField(0)
  simple,
  @HiveField(1)
  measurable,
}

@HiveType(typeId: 1)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int iconId;

  @HiveField(3)
  late String colorHex;

  @HiveField(4)
  late List<int> frequency; // List of weekdays, e.g., [1, 2, 3] for Mon, Tue, Wed

  @HiveField(5)
  late DateTime creationDate;

  @HiveField(6)
  late List<DateTime> completedDates;

  @HiveField(7)
  late List<DateTime> missedDates;

  // NEW FIELDS for Advanced Habit Types
  @HiveField(8)
  late HabitType type;

  @HiveField(9)
  late int? targetValue; // null for simple habits, target number for measurable

  @HiveField(10)
  late String? unit; // null for simple habits, "glasses", "steps", etc.

  @HiveField(11)
  late Map<String, int> dailyValues; // "2024-06-21": 3 (current progress for measurable habits)

  @HiveField(12)
  late double completionThreshold; // 0.75 = need 75% of target to count as completed (default 1.0)

  Habit({
    required this.id,
    required this.name,
    required this.iconId,
    required this.colorHex,
    required this.frequency,
    required this.creationDate,
    List<DateTime>? completedDates,
    List<DateTime>? missedDates,
    // New parameters with defaults for backward compatibility
    this.type = HabitType.simple,
    this.targetValue,
    this.unit,
    Map<String, int>? dailyValues,
    this.completionThreshold = 1.0, // 100% by default
  }) : completedDates = completedDates ?? [],
       missedDates = missedDates ?? [],
       dailyValues = dailyValues ?? {};

  // Helper method to get the status of a specific date (updated for measurable habits)
  HabitStatus getStatusForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = _getDateKey(normalizedDate);

    if (type == HabitType.simple) {
      // Simple habit: check completed/missed dates as before
      final isCompleted = completedDates.any(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );

      if (isCompleted) return HabitStatus.completed;

      final isMissed = missedDates.any(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );

      if (isMissed) return HabitStatus.missed;

      return HabitStatus.empty;
    } else {
      // Measurable habit: check if target threshold was reached
      final currentValue = dailyValues[dateKey] ?? 0;
      final target = targetValue ?? 1;
      final threshold = (target * completionThreshold).ceil();

      if (currentValue >= threshold) {
        return HabitStatus.completed;
      } else if (currentValue > 0) {
        return HabitStatus.partial; // New status for measurable habits
      } else {
        return HabitStatus.empty;
      }
    }
  }

  // Helper method to set status for a specific date (updated for measurable habits)
  void setStatusForDate(DateTime date, HabitStatus status) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = _getDateKey(normalizedDate);

    if (type == HabitType.simple) {
      // Simple habit: use existing logic
      // Remove from both lists first
      completedDates.removeWhere(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );
      missedDates.removeWhere(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );

      // Add to appropriate list based on status
      switch (status) {
        case HabitStatus.completed:
          completedDates.add(normalizedDate);
          break;
        case HabitStatus.missed:
          missedDates.add(normalizedDate);
          break;
        case HabitStatus.empty:
        case HabitStatus.partial:
          // Do nothing, already removed from both lists
          break;
      }
    } else {
      // Measurable habit: this method is less relevant, use incrementValue/resetValue instead
      // But for compatibility, we can set target value if completed
      if (status == HabitStatus.completed) {
        dailyValues[dateKey] = targetValue ?? 1;
      } else if (status == HabitStatus.empty) {
        dailyValues.remove(dateKey);
      }
    }
  }

  // NEW METHODS for measurable habits

  /// Get current progress for a specific date
  int getValueForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    return dailyValues[dateKey] ?? 0;
  }

  /// Increment value for a specific date
  void incrementValue(DateTime date, {int amount = 1}) {
    final dateKey = _getDateKey(date);
    final currentValue = dailyValues[dateKey] ?? 0;
    final newValue = currentValue + amount;
    final maxValue = (targetValue ?? 1) * 2; // Allow 200% of target max

    dailyValues[dateKey] = newValue.clamp(0, maxValue);
  }

  /// Set specific value for a date
  void setValueForDate(DateTime date, int value) {
    final dateKey = _getDateKey(date);
    final maxValue = (targetValue ?? 1) * 2; // Allow 200% of target max

    if (value <= 0) {
      dailyValues.remove(dateKey);
    } else {
      dailyValues[dateKey] = value.clamp(1, maxValue);
    }
  }

  /// Reset value for a specific date
  void resetValueForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    dailyValues.remove(dateKey);
  }

  /// Get progress percentage for a date (0.0 to 1.0+)
  double getProgressForDate(DateTime date) {
    if (type == HabitType.simple) {
      return getStatusForDate(date) == HabitStatus.completed ? 1.0 : 0.0;
    }

    final currentValue = getValueForDate(date);
    final target = targetValue ?? 1;
    return currentValue / target;
  }

  /// Check if habit is completed for a date (considering threshold)
  bool isCompletedForDate(DateTime date) {
    return getStatusForDate(date) == HabitStatus.completed;
  }

  /// Get display text for current progress
  String getProgressText(DateTime date) {
    if (type == HabitType.simple) {
      final status = getStatusForDate(date);
      switch (status) {
        case HabitStatus.completed:
          return "✓";
        case HabitStatus.missed:
          return "✗";
        case HabitStatus.empty:
          return "";
        case HabitStatus.partial:
          return "~"; // Shouldn't happen for simple
      }
    } else {
      final currentValue = getValueForDate(date);
      final target = targetValue ?? 1;
      final unitText = unit ?? "";
      return "$currentValue/$target $unitText".trim();
    }
  }

  // Helper method to generate date key for dailyValues map
  String _getDateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return "${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}";
  }

  // FIXED: Proper Streak Calculations

  /// Helper method to check if a habit was completed on a specific date
  /// Works for both simple and measurable habits
  bool _isCompletedForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (type == HabitType.simple) {
      // Simple habit: check if date exists in completedDates
      return completedDates.any(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );
    } else {
      // Measurable habit: check if target threshold was reached
      final dateKey = _getDateKey(normalizedDate);
      final currentValue = dailyValues[dateKey] ?? 0;
      final target = targetValue ?? 1;
      final threshold = (target * completionThreshold).ceil();
      return currentValue >= threshold;
    }
  }

  /// Calculate the current active streak from today backwards
  int getCurrentStreak() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    int streak = 0;

    // Start from today and count backwards
    for (int i = 0; i < 365; i++) {
      final checkDate = normalizedToday.subtract(Duration(days: i));

      // Skip future dates (should not happen with this logic, but safety check)
      if (checkDate.isAfter(normalizedToday)) {
        continue;
      }

      // Check if this date was completed using unified method
      if (_isCompletedForDate(checkDate)) {
        streak++;
      } else {
        // FIXED: Only break if we've found at least one completion
        // This allows us to skip non-completed recent days and find the actual streak
        if (streak > 0) {
          break; // We found the end of our streak
        }
        // If streak is still 0, keep looking backwards for the start of a recent streak
      }
    }

    return streak;
  }

  /// Calculate the longest streak - Fixed Algorithm
  int getLongestStreak() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // For simple habits, get all completed dates
    // For measurable habits, get all dates where target was reached
    List<DateTime> validCompletedDates = [];

    if (type == HabitType.simple) {
      // Filter out future dates from completedDates
      validCompletedDates = completedDates
          .map((date) => DateTime(date.year, date.month, date.day))
          .where((date) => !date.isAfter(normalizedToday))
          .toList();
    } else {
      // For measurable habits, check all days with values
      for (final entry in dailyValues.entries) {
        final dateKey = entry.key;
        final value = entry.value;

        // Parse date from key (format: "YYYY-MM-DD")
        final dateParts = dateKey.split('-');
        if (dateParts.length == 3) {
          final year = int.tryParse(dateParts[0]);
          final month = int.tryParse(dateParts[1]);
          final day = int.tryParse(dateParts[2]);

          if (year != null && month != null && day != null) {
            final date = DateTime(year, month, day);

            // Only include non-future dates where target was reached
            if (!date.isAfter(normalizedToday)) {
              final target = targetValue ?? 1;
              final threshold = (target * completionThreshold).ceil();
              if (value >= threshold) {
                validCompletedDates.add(date);
              }
            }
          }
        }
      }
    }

    if (validCompletedDates.isEmpty) return 0;

    // Sort dates
    validCompletedDates.sort();

    int maxStreak = 1; // At least 1 if we have any completed dates
    int currentStreak = 1;

    // Compare each date with the next one
    for (int i = 1; i < validCompletedDates.length; i++) {
      final prevDate = validCompletedDates[i - 1];
      final currentDate = validCompletedDates[i];

      // Check if dates are consecutive (1 day apart)
      final daysDifference = currentDate.difference(prevDate).inDays;

      if (daysDifference == 1) {
        // Consecutive days
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (daysDifference == 0) {
        // Same day (duplicate), ignore
        continue;
      } else {
        // Gap in dates, reset streak
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// Calculate completion rate as percentage (0.0 - 1.0)
  double getCompletionRate() {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedCreation = DateTime(
      creationDate.year,
      creationDate.month,
      creationDate.day,
    );

    // Calculate total expected days since creation
    int totalExpectedDays = 0;
    DateTime currentDate = normalizedCreation;

    while (currentDate.isBefore(normalizedNow) ||
        _isSameDay(currentDate, normalizedNow)) {
      final weekday = currentDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);

      if (isValidDay) {
        totalExpectedDays++;
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (totalExpectedDays == 0) return 0.0;

    // Count completed days within the valid period using unified method
    int completedCount = 0;
    currentDate = normalizedCreation;

    while (currentDate.isBefore(normalizedNow) ||
        _isSameDay(currentDate, normalizedNow)) {
      final weekday = currentDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);

      if (isValidDay && _isCompletedForDate(currentDate)) {
        completedCount++;
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return completedCount / totalExpectedDays;
  }

  // Helper methods for streak calculations

  DateTime _getPreviousValidDay(DateTime date) {
    DateTime currentDate = date.subtract(const Duration(days: 1));

    while (true) {
      final weekday = currentDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);

      if (isValidDay) return currentDate;

      currentDate = currentDate.subtract(const Duration(days: 1));

      // Don't go before creation date
      if (currentDate.isBefore(creationDate)) return creationDate;
    }
  }

  DateTime _getNextValidDay(DateTime date) {
    DateTime currentDate = date.add(const Duration(days: 1));

    while (true) {
      final weekday = currentDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);

      if (isValidDay) return currentDate;

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic> toJson() {
    final today = DateTime.now();
    final status = getStatusForDate(today);
    return {
      'name': name,
      'completed': status == HabitStatus.completed,
      'missed': status == HabitStatus.missed,
    };
  }
}

enum HabitStatus { empty, completed, missed, partial }
