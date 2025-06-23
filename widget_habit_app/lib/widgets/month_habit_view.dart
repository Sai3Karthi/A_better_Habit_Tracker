import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers.dart';
import 'month_calendar_grid.dart';

class MonthHabitView extends StatefulWidget {
  final DateTime month; // First day of the month
  final Function(DateTime, HabitStatus)? onDateTap;

  const MonthHabitView({super.key, required this.month, this.onDateTap});

  @override
  State<MonthHabitView> createState() => _MonthHabitViewState();
}

class _MonthHabitViewState extends State<MonthHabitView> {
  late PageController _habitPageController;
  int _currentHabitIndex = 0;

  @override
  void initState() {
    super.initState();
    _habitPageController = PageController();
  }

  @override
  void dispose() {
    _habitPageController.dispose();
    super.dispose();
  }

  String _getMonthYearText() {
    const months = [
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
    return '${months[widget.month.month - 1]} ${widget.month.year}';
  }

  // Calculate month statistics for current habit
  Map<String, dynamic> _calculateMonthStats(Habit habit) {
    final firstDay = DateTime(widget.month.year, widget.month.month, 1);
    final lastDay = DateTime(widget.month.year, widget.month.month + 1, 0);

    int completedDays = 0;
    int missedDays = 0;
    int totalValidDays = 0;

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(widget.month.year, widget.month.month, day);

      // Only count days that are valid for this habit
      if (habit.isActiveOnDate(date) &&
          (habit.frequency.isEmpty || habit.frequency.contains(date.weekday))) {
        totalValidDays++;

        final status = habit.getStatusForDate(date);
        if (status == HabitStatus.completed) {
          completedDays++;
        } else if (status == HabitStatus.missed) {
          missedDays++;
        }
      }
    }

    final completionRate = totalValidDays > 0
        ? (completedDays / totalValidDays * 100)
        : 0.0;

    return {
      'completed': completedDays,
      'missed': missedDays,
      'total': totalValidDays,
      'rate': completionRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final habits = ref.watch(
          habitsProvider,
        ); // Direct List<Habit>, not AsyncValue

        if (habits.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Month header with habit counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month/Year
                  Text(
                    _getMonthYearText(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // Habit counter and navigation
                  Row(
                    children: [
                      // Left arrow
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: _currentHabitIndex > 0
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        onPressed: _currentHabitIndex > 0
                            ? () => _habitPageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                            : null,
                      ),

                      // Habit counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentHabitIndex + 1}/${habits.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Right arrow
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: _currentHabitIndex < habits.length - 1
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        onPressed: _currentHabitIndex < habits.length - 1
                            ? () => _habitPageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal habit scroller
            Expanded(
              child: PageView.builder(
                controller: _habitPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentHabitIndex = index;
                  });
                },
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return MonthCalendarGrid(
                    habit: habit,
                    month: widget.month,
                    onDateTap: (date, status) {
                      // Habit is already updated in MonthCalendarGrid tap handler
                      // Don't call setStatusForDate again to avoid overriding incremented values
                      ref.read(habitsProvider.notifier).updateHabit(habit);

                      // Force local UI rebuild (month view specific fix)
                      setState(() {});

                      // Callback for any additional handling
                      if (widget.onDateTap != null) {
                        widget.onDateTap!(date, status);
                      }
                    },
                  );
                },
              ),
            ),

            // Month navigation hint (dots indicator)
            if (habits.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(habits.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentHabitIndex
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No habits for ${_getMonthYearText()}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some habits to get started!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          // Helpful hint
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.grey[500],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Swipe up/down to navigate months\nSwipe left/right for different habits',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
