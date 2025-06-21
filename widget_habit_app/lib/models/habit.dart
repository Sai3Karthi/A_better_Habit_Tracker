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
