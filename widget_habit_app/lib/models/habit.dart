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

  // NEW FIELDS for Date Ranges (Phase 3A.2.2)
  @HiveField(13)
  DateTime? startDate; // When habit becomes active (optional)

  @HiveField(14)
  DateTime? endDate; // When habit expires (optional)

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
    // Date range parameters (Phase 3A.2.2)
    this.startDate,
    this.endDate,
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
      // FIXED: Measurable habit - check missed dates first, then values
      final isMissed = missedDates.any(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );

      if (isMissed) return HabitStatus.missed;

      // Then check if target threshold was reached
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

    // Phase 3A.2.2: Check if date is within active range
    if (!isActiveOnDate(normalizedDate)) {
      return; // Don't allow updates outside date range
    }

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
      // FIXED: Measurable habit - handle all statuses properly
      // Remove from missed dates first (cleanup)
      missedDates.removeWhere(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );

      switch (status) {
        case HabitStatus.completed:
          dailyValues[dateKey] = targetValue ?? 1;
          break;
        case HabitStatus.missed:
          // Clear any progress and add to missed dates
          dailyValues.remove(dateKey);
          missedDates.add(normalizedDate);
          break;
        case HabitStatus.empty:
          // Clear any progress, already removed from missed dates
          dailyValues.remove(dateKey);
          break;
        case HabitStatus.partial:
          // Keep existing value if it exists, otherwise set minimal value
          if (!dailyValues.containsKey(dateKey) || dailyValues[dateKey] == 0) {
            dailyValues[dateKey] = 1; // Minimal progress
          }
          break;
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
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Phase 3A.2.2: Check if date is within active range
    if (!isActiveOnDate(normalizedDate)) {
      return; // Don't allow updates outside date range
    }

    final dateKey = _getDateKey(normalizedDate);
    final currentValue = dailyValues[dateKey] ?? 0;
    final newValue = currentValue + amount;
    final maxValue = (targetValue ?? 1) * 2; // Allow 200% of target max

    dailyValues[dateKey] = newValue.clamp(0, maxValue);

    // FIXED: Remove from missed dates when incrementing (allows consecutive increments)
    missedDates.removeWhere(
      (d) =>
          d.year == normalizedDate.year &&
          d.month == normalizedDate.month &&
          d.day == normalizedDate.day,
    );
  }

  /// Set specific value for a date
  void setValueForDate(DateTime date, int value) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Phase 3A.2.2: Check if date is within active range
    if (!isActiveOnDate(normalizedDate)) {
      return; // Don't allow updates outside date range
    }

    final dateKey = _getDateKey(normalizedDate);
    final maxValue = (targetValue ?? 1) * 2; // Allow 200% of target max

    if (value <= 0) {
      dailyValues.remove(dateKey);
    } else {
      dailyValues[dateKey] = value.clamp(1, maxValue);
    }
  }

  /// Reset value for a specific date
  void resetValueForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Phase 3A.2.2: Check if date is within active range
    if (!isActiveOnDate(normalizedDate)) {
      return; // Don't allow updates outside date range
    }

    final dateKey = _getDateKey(normalizedDate);

    // Remove from daily values
    dailyValues.remove(dateKey);

    // FIXED: Also remove from missed dates to allow proper reset
    missedDates.removeWhere(
      (d) =>
          d.year == normalizedDate.year &&
          d.month == normalizedDate.month &&
          d.day == normalizedDate.day,
    );
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

    // FIXED: Start from yesterday unless today is already completed
    // This prevents streak from dropping to 0 just because today isn't updated yet
    DateTime currentDate = _getStreakStartDate(normalizedToday);

    // Start counting streak
    int currentStreak = 0;

    // Go back up to 365 days to find streak
    for (int i = 0; i < 365; i++) {
      // Check if this date is a valid day for this habit (frequency)
      final weekday = currentDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);

      // Check if this date is within habit's active range
      final isActiveDate = isActiveOnDate(currentDate);

      // ONLY check status for days that should be tracked
      if (isValidDay && isActiveDate) {
        final status = getStatusForDate(currentDate);

        if (status == HabitStatus.completed) {
          currentStreak++;
        } else if (status == HabitStatus.missed) {
          // Missed day found - streak resets to 0 immediately
          break;
        } else {
          // Empty status - streak broken (no action taken on a day that should have been done)
          break;
        }
      }
      // IMPORTANT: If day is not valid (excluded by frequency) or not active,
      // we continue without breaking the streak

      // Move to previous day
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return currentStreak;
  }

  /// Helper method to determine streak calculation start date
  /// Returns today if completed, otherwise yesterday
  DateTime _getStreakStartDate(DateTime today) {
    // Check if today should be counted (must be valid day and completed)
    final weekday = today.weekday;
    final isValidDay = frequency.isEmpty || frequency.contains(weekday);
    final isActiveDate = isActiveOnDate(today);

    if (isValidDay && isActiveDate) {
      final todayStatus = getStatusForDate(today);
      if (todayStatus == HabitStatus.completed) {
        // Today is completed, include it in streak calculation
        return today;
      }
    }

    // Today is not completed or not a valid day, start from yesterday
    return today.subtract(const Duration(days: 1));
  }

  /// Calculate the current fail streak (consecutive missed days from today backwards)
  int getCurrentFailStreak() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Start from today and go backwards, checking each valid day
    int currentFailStreak = 0;
    DateTime currentDate = normalizedToday;

    // Go back up to 365 days to find fail streak
    for (int i = 0; i < 365; i++) {
      // Check if this date is a valid day for this habit (frequency)
      final weekday = currentDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);

      // Check if this date is within habit's active range
      final isActiveDate = isActiveOnDate(currentDate);

      // ONLY check status for days that should be tracked
      if (isValidDay && isActiveDate) {
        final status = getStatusForDate(currentDate);

        if (status == HabitStatus.missed) {
          currentFailStreak++;
        } else if (status == HabitStatus.completed) {
          // Completed day found - fail streak resets to 0 immediately
          break;
        } else {
          // Empty status - no activity yet, continue checking backwards
          // (for fail streaks, empty doesn't count as failed)
        }
      }
      // IMPORTANT: If day is not valid (excluded by frequency) or not active,
      // we continue without affecting the fail streak

      // Move to previous day
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return currentFailStreak;
  }

  /// Calculate the longest streak - FIXED to handle frequency exclusions properly
  int getLongestStreak() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Get all valid completed dates (only days that were supposed to be done)
    List<DateTime> validCompletedDates = _getValidCompletedDatesForFrequency(
      normalizedToday,
    );

    if (validCompletedDates.isEmpty) return 0;

    // Sort dates in ascending order
    validCompletedDates.sort();

    int maxStreak = 1; // At least 1 if we have any completed dates
    int currentStreak = 1;

    // Check consecutive completion considering frequency
    for (int i = 1; i < validCompletedDates.length; i++) {
      final prevDate = validCompletedDates[i - 1];
      final currentDate = validCompletedDates[i];

      // Check if these dates are consecutive VALID days (skipping excluded days)
      if (_areConsecutiveValidDays(prevDate, currentDate)) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        // Gap found (missed a valid day), reset streak
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// Check if two dates are consecutive valid days considering frequency
  bool _areConsecutiveValidDays(DateTime date1, DateTime date2) {
    DateTime checkDate = date1.add(const Duration(days: 1));

    // Walk forward from date1 to date2, looking for the next valid day
    while (checkDate.isBefore(date2) || _isSameDay(checkDate, date2)) {
      final weekday = checkDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);
      final isActiveDate = isActiveOnDate(checkDate);

      if (isValidDay && isActiveDate) {
        // This is a valid day - it should be date2 for them to be consecutive
        return _isSameDay(checkDate, date2);
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    return false;
  }

  /// Get valid completed dates that respect frequency restrictions
  List<DateTime> _getValidCompletedDatesForFrequency(DateTime maxDate) {
    List<DateTime> validCompletedDates = [];

    if (type == HabitType.simple) {
      // Filter completed dates to only include days that were supposed to be done
      for (final date in completedDates) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (!normalizedDate.isAfter(maxDate)) {
          final weekday = normalizedDate.weekday;
          final isValidDay = frequency.isEmpty || frequency.contains(weekday);
          final isActiveDate = isActiveOnDate(normalizedDate);

          if (isValidDay && isActiveDate) {
            validCompletedDates.add(normalizedDate);
          }
        }
      }
    } else {
      // For measurable habits, check all days with values that meet threshold
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

            // Only include non-future dates where target was reached AND day was valid
            if (!date.isAfter(maxDate)) {
              final weekday = date.weekday;
              final isValidDay =
                  frequency.isEmpty || frequency.contains(weekday);
              final isActiveDate = isActiveOnDate(date);

              if (isValidDay && isActiveDate) {
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
    }

    // Remove duplicates and return
    return validCompletedDates.toSet().toList();
  }

  /// Calculate completion rate as percentage (0.0 - 1.0)
  double getCompletionRate() {
    final stats = getCompletionStats();
    return stats.total > 0 ? stats.completed / stats.total : 0.0;
  }

  /// Get detailed completion statistics
  CompletionStats getCompletionStats() {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);

    // Use start date if available, otherwise creation date
    final startDate = this.startDate ?? creationDate;
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    // Calculate total expected days and completed days
    int totalValidDays = 0;
    int completedDays = 0;
    DateTime currentDate = normalizedStart;

    while (currentDate.isBefore(normalizedNow) ||
        _isSameDay(currentDate, normalizedNow)) {
      // Check if this date is a valid day for this habit (frequency)
      final weekday = currentDate.weekday;
      final isValidDay = frequency.isEmpty || frequency.contains(weekday);

      // Check if this date is within habit's active range
      final isActiveDate = isActiveOnDate(currentDate);

      if (isValidDay && isActiveDate) {
        totalValidDays++;

        if (_isCompletedForDate(currentDate)) {
          completedDays++;
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    final percentage = totalValidDays > 0
        ? (completedDays / totalValidDays)
        : 0.0;

    return CompletionStats(
      completed: completedDays,
      total: totalValidDays,
      percentage: percentage,
    );
  }

  // Helper methods for streak calculations

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Date Range Helper Methods (Phase 3A.2.2)

  /// Check if habit is active on a specific date
  bool isActiveOnDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (startDate != null) {
      final normalizedStart = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
      );
      if (normalizedDate.isBefore(normalizedStart)) {
        return false;
      }
    }

    if (endDate != null) {
      final normalizedEnd = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
      );
      if (normalizedDate.isAfter(normalizedEnd)) {
        return false;
      }
    }

    return true;
  }

  /// Get formatted date range text for UI display
  String getDateRangeText() {
    if (startDate == null && endDate == null) return "";
    if (startDate != null && endDate == null) {
      return "From ${_formatDate(startDate!)}";
    }
    if (startDate == null && endDate != null) {
      return "Until ${_formatDate(endDate!)}";
    }
    return "${_formatDate(startDate!)} - ${_formatDate(endDate!)}";
  }

  /// Format date for display (helper method)
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${months[date.month - 1]} ${date.day}${date.year != DateTime.now().year ? ', ${date.year}' : ''}";
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

/// Data class for completion statistics
class CompletionStats {
  final int completed;
  final int total;
  final double percentage;

  const CompletionStats({
    required this.completed,
    required this.total,
    required this.percentage,
  });

  /// Get formatted display text like "15/20 (75%)"
  String getDisplayText() {
    final percentageInt = (percentage * 100).round();
    return '$completed/$total ($percentageInt%)';
  }
}
