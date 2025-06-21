import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import 'habit_list_item.dart';

class HabitListView extends ConsumerWidget {
  final DateTime? currentWeekStart;

  const HabitListView({super.key, this.currentWeekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);

    if (habits.isEmpty) {
      return const Center(child: Text('No habits yet. Add one!'));
    }

    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitListItem(habit: habit, currentWeekStart: currentWeekStart);
      },
    );
  }
}
