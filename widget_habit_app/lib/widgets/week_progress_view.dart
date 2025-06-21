import 'package:flutter/material.dart';
import '../models/habit.dart';

class WeekProgressView extends StatelessWidget {
  final Habit habit;
  final DateTime? currentWeekStart;
  final Function(DateTime, HabitStatus)? onDateTap;

  const WeekProgressView({
    super.key,
    required this.habit,
    this.currentWeekStart,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart = currentWeekStart ?? _getWeekStart(DateTime.now());

    return Container(
      height: 44, // Reduced to exactly match constraint
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final status = habit.getStatusForDate(day);

          return GestureDetector(
            onTap: onDateTap != null
                ? () {
                    final nextStatus = _getNextStatus(status);
                    onDateTap!(day, nextStatus);
                  }
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Date number (aligned with header)
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getDateColor(status),
                  ),
                ),
                const SizedBox(height: 2), // Reduced spacing
                // Status indicator (compact size)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(status),
                    border: Border.all(
                      color: _getBorderColor(status),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildStatusIcon(status),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the current week
    final daysFromMonday = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysFromMonday));
  }

  Color _getDateColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[400]!;
      case HabitStatus.missed:
        return Colors.red[400]!;
      case HabitStatus.empty:
        return Colors.white;
    }
  }

  Color _getBackgroundColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[100]!;
      case HabitStatus.missed:
        return Colors.red[100]!;
      case HabitStatus.empty:
        return Colors.transparent;
    }
  }

  Color _getBorderColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[400]!;
      case HabitStatus.missed:
        return Colors.red[400]!;
      case HabitStatus.empty:
        return Colors.grey[600]!;
    }
  }

  Widget _buildStatusIcon(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return const Icon(Icons.check, color: Colors.green, size: 14);
      case HabitStatus.missed:
        return const Icon(Icons.close, color: Colors.red, size: 14);
      case HabitStatus.empty:
        return const SizedBox.shrink();
    }
  }

  HabitStatus _getNextStatus(HabitStatus currentStatus) {
    switch (currentStatus) {
      case HabitStatus.empty:
        return HabitStatus.completed;
      case HabitStatus.completed:
        return HabitStatus.missed;
      case HabitStatus.missed:
        return HabitStatus.empty;
    }
  }
}
