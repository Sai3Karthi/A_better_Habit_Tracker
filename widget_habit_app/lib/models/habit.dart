import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
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

  Habit({
    required this.id,
    required this.name,
    required this.iconId,
    required this.colorHex,
    required this.frequency,
    required this.creationDate,
    List<DateTime>? completedDates,
    List<DateTime>? missedDates,
  }) : completedDates = completedDates ?? [],
       missedDates = missedDates ?? [];

  // Helper method to get the status of a specific date
  HabitStatus getStatusForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

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
  }

  // Helper method to set status for a specific date
  void setStatusForDate(DateTime date, HabitStatus status) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

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
        // Do nothing, already removed from both lists
        break;
    }
  }

  // FIXED: Proper Streak Calculations

  /// Calculate the current active streak from today backwards
  int getCurrentStreak() {
    if (completedDates.isEmpty) return 0;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    int streak = 0;

    // Start from today and count backwards
    for (int i = 0; i < 365; i++) {
      final checkDate = normalizedToday.subtract(Duration(days: i));

      // Check if this date was completed (and is not in the future)
      bool isCompleted = false;
      for (final completedDate in completedDates) {
        final normalizedCompleted = DateTime(
          completedDate.year,
          completedDate.month,
          completedDate.day,
        );

        // CRITICAL FIX: Only count completed dates that are NOT in the future
        if (normalizedCompleted.isAfter(normalizedToday)) {
          continue; // Skip future dates
        }

        if (normalizedCompleted.year == checkDate.year &&
            normalizedCompleted.month == checkDate.month &&
            normalizedCompleted.day == checkDate.day) {
          isCompleted = true;
          break;
        }
      }

      if (isCompleted) {
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
    if (completedDates.isEmpty) return 0;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Filter out future dates and sort completed dates
    final validDates =
        completedDates
            .map((date) => DateTime(date.year, date.month, date.day))
            .where(
              (date) => !date.isAfter(normalizedToday),
            ) // CRITICAL: Only past/today dates
            .toList()
          ..sort();

    if (validDates.isEmpty) return 0;

    int maxStreak = 1; // At least 1 if we have any completed dates
    int currentStreak = 1;

    // Compare each date with the next one
    for (int i = 1; i < validDates.length; i++) {
      final prevDate = validDates[i - 1];
      final currentDate = validDates[i];

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

    // Count completed days within the valid period
    int completedCount = 0;
    for (final date in completedDates) {
      final normalizedDate = _normalizeDate(date);
      if (!normalizedDate.isBefore(normalizedCreation) &&
          !normalizedDate.isAfter(normalizedNow)) {
        // Check if this completed date is on a valid day for this habit
        final weekday = normalizedDate.weekday;
        final isValidDay = frequency.isEmpty || frequency.contains(weekday);
        if (isValidDay) {
          completedCount++;
        }
      }
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

enum HabitStatus { empty, completed, missed }
