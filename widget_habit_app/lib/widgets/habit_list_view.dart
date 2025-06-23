import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers.dart';
import '../widgets/side_menu.dart'; // Import for ViewMode
import 'habit_list_item.dart';

class HabitListView extends ConsumerWidget {
  final DateTime? currentWeekStart;
  final ViewMode viewMode;

  const HabitListView({
    super.key,
    this.currentWeekStart,
    this.viewMode = ViewMode.week, // Default to week mode
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);

    if (habits.isEmpty) {
      return const Center(child: Text('No habits yet. Add one!'));
    }

    // Use CustomScrollView with SliverList for better performance
    return CustomScrollView(
      // Performance optimizations
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 1000, // Cache more items for smoother scrolling
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final habit = habits[index];
              // Each item wrapped in AutomaticKeepAlive for selective caching
              return _HabitItemWrapper(
                key: ValueKey(habit.id),
                habit: habit,
                currentWeekStart: currentWeekStart,
                viewMode: viewMode,
              );
            },
            childCount: habits.length,
            // Add item extent callback for fixed height optimization
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            addSemanticIndexes: false, // Reduce overhead
          ),
        ),
      ],
    );
  }
}

// Wrapper widget for better performance isolation
class _HabitItemWrapper extends StatelessWidget {
  final Habit habit;
  final DateTime? currentWeekStart;
  final ViewMode viewMode;

  const _HabitItemWrapper({
    super.key,
    required this.habit,
    this.currentWeekStart,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2), // Minimal padding
      child: RepaintBoundary(
        child: HabitListItem(
          habit: habit,
          currentWeekStart: currentWeekStart,
          viewMode: viewMode,
        ),
      ),
    );
  }
}
