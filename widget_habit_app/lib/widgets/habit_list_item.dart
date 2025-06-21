import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers.dart';
import 'week_progress_view.dart';

class HabitListItem extends ConsumerWidget {
  final Habit habit;
  final DateTime? currentWeekStart;

  const HabitListItem({super.key, required this.habit, this.currentWeekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            habit.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          WeekProgressView(
            habit: habit,
            currentWeekStart: currentWeekStart,
            onDateTap: (date, newStatus) {
              habit.setStatusForDate(date, newStatus);
              ref.read(habitsProvider.notifier).updateHabit(habit);
            },
          ),
        ],
      ),
    );
  }
}
