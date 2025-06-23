import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers.dart';
import 'month_calendar_grid.dart';

class MonthHabitView extends ConsumerStatefulWidget {
  final DateTime month;
  final Function(DateTime, HabitStatus)? onDateTap;
  final PageController
  sharedHabitPageController; // SHARED CONTROLLER FROM PARENT
  final int currentHabitIndex; // CURRENT INDEX FROM PARENT
  final Function(int)? onHabitIndexChanged; // NOTIFY PARENT

  const MonthHabitView({
    super.key,
    required this.month,
    this.onDateTap,
    required this.sharedHabitPageController, // REQUIRED SHARED CONTROLLER
    required this.currentHabitIndex, // REQUIRED CURRENT INDEX
    this.onHabitIndexChanged,
  });

  @override
  ConsumerState<MonthHabitView> createState() => _MonthHabitViewState();
}

class _MonthHabitViewState extends ConsumerState<MonthHabitView> {
  late int _localHabitIndex; // LOCAL COPY FOR SYNCHRONIZATION

  @override
  void initState() {
    super.initState();
    _localHabitIndex = widget.currentHabitIndex;

    // Initialize shared controller if not already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureControllerSync();
    });
  }

  @override
  void didUpdateWidget(MonthHabitView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync local index with parent changes
    if (widget.currentHabitIndex != _localHabitIndex) {
      _localHabitIndex = widget.currentHabitIndex;
      _ensureControllerSync();
    }
  }

  // ENSURE CONTROLLER IS SYNCED WITH CURRENT INDEX
  void _ensureControllerSync() {
    if (widget.sharedHabitPageController.hasClients &&
        widget.sharedHabitPageController.positions.isNotEmpty &&
        mounted) {
      final habits = ref.read(habitsProvider);
      if (habits.isNotEmpty &&
          _localHabitIndex >= 0 &&
          _localHabitIndex < habits.length) {
        // Only animate if we're not already on the right page
        final currentPage = widget.sharedHabitPageController.page?.round();
        if (currentPage != _localHabitIndex) {
          Future.microtask(() {
            if (mounted &&
                widget.sharedHabitPageController.hasClients &&
                widget.sharedHabitPageController.positions.isNotEmpty) {
              widget.sharedHabitPageController.animateToPage(
                _localHabitIndex,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);

    if (habits.isEmpty) {
      return const Center(child: Text('No habits yet. Add one!'));
    }

    // Ensure local index is within bounds
    if (_localHabitIndex >= habits.length) {
      _localHabitIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onHabitIndexChanged?.call(0);
      });
    }

    return Column(
      children: [
        // IMPROVED habit navigation header with better state management
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: _localHabitIndex > 0 ? Colors.white : Colors.grey[600],
                ),
                onPressed: _localHabitIndex > 0
                    ? () => _navigateToHabit(_localHabitIndex - 1)
                    : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_localHabitIndex + 1}/${habits.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habits[_localHabitIndex].name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _localHabitIndex < habits.length - 1
                      ? Colors.white
                      : Colors.grey[600],
                ),
                onPressed: _localHabitIndex < habits.length - 1
                    ? () => _navigateToHabit(_localHabitIndex + 1)
                    : null,
              ),
            ],
          ),
        ),

        // ENHANCED habit scroller using shared controller
        Expanded(
          child: PageView.builder(
            controller:
                widget.sharedHabitPageController, // USE SHARED CONTROLLER
            onPageChanged: (index) {
              // Update local state and notify parent
              setState(() {
                _localHabitIndex = index;
              });
              widget.onHabitIndexChanged?.call(index);
            },
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];

              // ADD REPAINT BOUNDARY for better performance
              return RepaintBoundary(
                child: MonthCalendarGrid(
                  key: ValueKey(
                    '${habit.id}-${widget.month.year}-${widget.month.month}',
                  ), // STABLE KEY
                  habit: habit,
                  month: widget.month,
                  onDateTap: (date, status) {
                    habit.setStatusForDate(date, status);
                    ref.read(habitsProvider.notifier).updateHabit(habit);
                    widget.onDateTap?.call(date, status);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // HELPER METHOD for habit navigation with enhanced safety
  void _navigateToHabit(int newIndex) {
    final habits = ref.read(habitsProvider);

    // BOUNDS CHECK: Ensure index is valid
    if (newIndex < 0 || newIndex >= habits.length) {
      return;
    }

    // Use shared controller for navigation with safety checks
    if (widget.sharedHabitPageController.hasClients &&
        widget.sharedHabitPageController.positions.isNotEmpty) {
      Future.microtask(() {
        if (mounted &&
            widget.sharedHabitPageController.hasClients &&
            widget.sharedHabitPageController.positions.isNotEmpty) {
          widget.sharedHabitPageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Update local state and notify parent
    setState(() {
      _localHabitIndex = newIndex;
    });
    widget.onHabitIndexChanged?.call(newIndex);
  }
}
