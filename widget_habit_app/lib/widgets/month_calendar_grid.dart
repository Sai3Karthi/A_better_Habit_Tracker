import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../themes/habit_theme.dart';

class MonthCalendarGrid extends StatefulWidget {
  final Habit habit;
  final DateTime month; // First day of the month
  final Function(DateTime, HabitStatus)? onDateTap;

  const MonthCalendarGrid({
    super.key,
    required this.habit,
    required this.month,
    this.onDateTap,
  });

  @override
  State<MonthCalendarGrid> createState() => _MonthCalendarGridState();
}

class _MonthCalendarGridState extends State<MonthCalendarGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _sharedController;
  late Animation<double> _scaleAnimation;
  int? _activeIndex; // Track which day is currently animating

  @override
  void initState() {
    super.initState();
    _sharedController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _sharedController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sharedController.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    _activeIndex = index;
    _sharedController.forward();
  }

  void _onTapUp(int index) {
    if (_activeIndex == index) {
      _sharedController.reverse();
      _activeIndex = null;
    }
  }

  // Generate calendar grid (42 days: 6 weeks × 7 days)
  List<DateTime?> _generateCalendarDays() {
    final firstDay = DateTime(widget.month.year, widget.month.month, 1);
    final lastDay = DateTime(widget.month.year, widget.month.month + 1, 0);

    // Start from Monday of the first week
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    List<DateTime?> days = [];
    for (int i = 0; i < 42; i++) {
      final day = startDate.add(Duration(days: i));
      // Only include days that belong to this month
      if (day.month == widget.month.month && day.year == widget.month.year) {
        days.add(day);
      } else {
        days.add(null); // Empty cell for other months
      }
    }
    return days;
  }

  bool _isFutureDate(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.isAfter(normalizedToday);
  }

  bool _isValidDay(DateTime date) {
    if (widget.habit.frequency.isEmpty) return true;
    return widget.habit.frequency.contains(date.weekday);
  }

  @override
  Widget build(BuildContext context) {
    final calendarDays = _generateCalendarDays();

    return Column(
      children: [
        // Month header with habit name
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                widget.habit.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Month stats
              Text(
                _getMonthStatsText(),
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Week day headers
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Calendar grid (6 rows × 7 columns)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final day = calendarDays[index];

                if (day == null) {
                  // Empty cell for days outside current month
                  return const SizedBox.shrink();
                }

                final status = widget.habit.getStatusForDate(day);
                final isValidDay = _isValidDay(day);
                final isActiveDate = widget.habit.isActiveOnDate(day);
                final isFuture = _isFutureDate(day);

                return GestureDetector(
                  onTapDown: (!isActiveDate || !isValidDay || isFuture)
                      ? null
                      : (_) => _onTapDown(index),
                  onTapUp: (!isActiveDate || !isValidDay || isFuture)
                      ? null
                      : (_) => _onTapUp(index),
                  onTapCancel: (!isActiveDate || !isValidDay || isFuture)
                      ? null
                      : () => _onTapUp(index),
                  onTap: _getOnTapHandler(
                    day,
                    status,
                    isFuture,
                    isValidDay,
                    isActiveDate,
                  ),
                  onLongPress: _getLongPressHandler(
                    day,
                    status,
                    isFuture,
                    isValidDay,
                    isActiveDate,
                  ),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      final shouldAnimate = _activeIndex == index;
                      return Transform.scale(
                        scale: (!isActiveDate || !isValidDay || isFuture)
                            ? 1.0
                            : shouldAnimate
                            ? _scaleAnimation.value
                            : 1.0,
                        child: _buildDayCell(
                          day,
                          status,
                          isFuture,
                          isValidDay,
                          isActiveDate,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _getCellBackgroundColor(
          status,
          isFuture,
          isValidDay,
          isActiveDate,
        ),
        border: Border.all(
          color: _getCellBorderColor(
            status,
            isFuture,
            isValidDay,
            isActiveDate,
          ),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getDateTextColor(
                status,
                isFuture,
                isValidDay,
                isActiveDate,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Status indicator
          _buildStatusIndicator(
            day,
            status,
            isFuture,
            isValidDay,
            isActiveDate,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    if (!isActiveDate) {
      return Icon(
        Icons.calendar_today_outlined,
        size: 10,
        color: Colors.grey[600],
      );
    }

    if (!isValidDay) {
      return Icon(Icons.block, size: 10, color: Colors.grey[500]);
    }

    if (isFuture) {
      return Icon(Icons.schedule, size: 10, color: Colors.grey[500]);
    }

    if (widget.habit.type == HabitType.simple) {
      return _buildSimpleStatusIcon(status);
    } else {
      return _buildMeasurableStatusIndicator(day, status);
    }
  }

  Widget _buildSimpleStatusIcon(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return Icon(Icons.check, color: habitTheme.habitCompleted, size: 12);
      case HabitStatus.missed:
        return Icon(Icons.close, color: habitTheme.habitMissed, size: 12);
      case HabitStatus.partial:
        return Icon(Icons.more_horiz, color: habitTheme.habitPartial, size: 12);
      case HabitStatus.empty:
        return const SizedBox(width: 12, height: 12);
    }
  }

  Widget _buildMeasurableStatusIndicator(DateTime day, HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    final currentValue = widget.habit.getValueForDate(day);
    final targetValue = widget.habit.targetValue ?? 1;

    if (status == HabitStatus.missed) {
      return Icon(Icons.close, color: habitTheme.habitMissed, size: 12);
    } else if (status == HabitStatus.completed) {
      return Icon(
        Icons.check,
        color: habitTheme.progressRingComplete,
        size: 12,
      );
    } else if (currentValue > 0) {
      return Text(
        '$currentValue',
        style: TextStyle(
          fontSize: 16, // Increased from 12 to 16 for better visibility
          fontWeight: FontWeight.bold,
          color: Colors
              .white, // Changed from habitTheme.textPrimary to white for contrast
        ),
      );
    } else {
      return const SizedBox(width: 12, height: 12);
    }
  }

  // Color helpers (reusing logic from WeekProgressView)
  Color _getCellBackgroundColor(
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    if (!isActiveDate) return Colors.grey[800]!.withValues(alpha: 0.3);
    if (!isValidDay) return Colors.grey[700]!.withValues(alpha: 0.3);
    if (isFuture) return Colors.grey[700]!.withValues(alpha: 0.3);

    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return habitTheme.habitCompleted.withValues(alpha: 0.1);
      case HabitStatus.missed:
        return habitTheme.habitMissed.withValues(alpha: 0.1);
      case HabitStatus.partial:
        return habitTheme.habitPartial.withValues(alpha: 0.1);
      case HabitStatus.empty:
        return Colors.transparent;
    }
  }

  Color _getCellBorderColor(
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    if (!isActiveDate || !isValidDay || isFuture) {
      return Colors.grey[600]!;
    }

    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return habitTheme.habitCompleted;
      case HabitStatus.missed:
        return habitTheme.habitMissed;
      case HabitStatus.partial:
        return habitTheme.habitPartial;
      case HabitStatus.empty:
        return habitTheme.cardBorder;
    }
  }

  Color _getDateTextColor(
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    if (!isActiveDate) return Colors.grey[500]!;
    if (!isValidDay) return Colors.grey[400]!;
    if (isFuture) return Colors.grey[400]!;
    return Colors.white;
  }

  // Tap handlers (enhanced with feedback like WeekProgressView)
  VoidCallback? _getOnTapHandler(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    // Provide feedback for invalid interactions
    if (!isActiveDate) {
      return () => _showInactiveDateFeedback();
    }

    if (!isValidDay) {
      return () => _showExcludedDayFeedback();
    }

    if (isFuture) {
      return _showFutureDateFeedback;
    }

    if (widget.onDateTap == null) return null;

    if (widget.habit.type == HabitType.simple) {
      return () {
        final nextStatus = _getNextStatus(status);
        widget.onDateTap!(day, nextStatus);
      };
    } else {
      return () {
        HapticFeedback.lightImpact();
        if (status == HabitStatus.missed) {
          // If missed, reset to empty (allow user to retry)
          widget.habit.resetValueForDate(day);
        } else {
          // For measurable habits: always increment (until max), then reset
          final currentValue = widget.habit.getValueForDate(day);
          final maxValue = widget.habit.targetValue ?? 1;

          if (currentValue >= maxValue) {
            // If at max value, reset to 0
            widget.habit.resetValueForDate(day);
          } else {
            // Otherwise, increment value
            widget.habit.incrementValue(day);
          }
        }
        widget.onDateTap!(day, widget.habit.getStatusForDate(day));
      };
    }
  }

  VoidCallback? _getLongPressHandler(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    // Only provide long press for valid, active, non-future days
    if (!isActiveDate || !isValidDay || isFuture || widget.onDateTap == null) {
      return null;
    }

    return () {
      HapticFeedback.mediumImpact();
      final previousStatus = status;

      if (widget.habit.type == HabitType.simple) {
        HabitStatus nextStatus = status == HabitStatus.missed
            ? HabitStatus.empty
            : HabitStatus.missed;
        widget.onDateTap!(day, nextStatus);
      } else {
        if (status == HabitStatus.missed) {
          widget.habit.resetValueForDate(day);
        } else {
          widget.habit.resetValueForDate(day);
          widget.habit.setStatusForDate(day, HabitStatus.missed);
        }
        widget.onDateTap!(day, widget.habit.getStatusForDate(day));
      }

      // Show feedback to user about long press action
      _showLongPressFeedback(previousStatus);
    };
  }

  HabitStatus _getNextStatus(HabitStatus currentStatus) {
    switch (currentStatus) {
      case HabitStatus.empty:
        return HabitStatus.completed;
      case HabitStatus.completed:
        return HabitStatus.missed;
      case HabitStatus.missed:
        return HabitStatus.empty;
      case HabitStatus.partial:
        return HabitStatus.completed;
    }
  }

  // Show feedback when user tries to tap future date
  void _showFutureDateFeedback() {
    final habitTheme = HabitTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Can't complete future habits"),
        duration: const Duration(seconds: 2),
        backgroundColor: habitTheme.habitPartial,
      ),
    );
  }

  // Show feedback when user tries to tap excluded day
  void _showExcludedDayFeedback() {
    final habitTheme = HabitTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("This day is not included in habit frequency"),
        duration: const Duration(seconds: 2),
        backgroundColor: habitTheme.habitExcluded,
      ),
    );
  }

  // Show feedback when user tries to tap inactive date
  void _showInactiveDateFeedback() {
    final habitTheme = HabitTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "This habit is not active on this date (outside date range)",
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: habitTheme.habitFuture,
      ),
    );
  }

  // Show feedback for long press actions
  void _showLongPressFeedback(HabitStatus previousStatus) {
    final habitTheme = HabitTheme.of(context);
    String message;
    Color color;

    if (previousStatus == HabitStatus.missed) {
      message = "Reset to empty";
      color = habitTheme.textSecondary;
    } else {
      message = "Marked as missed";
      color = habitTheme.habitMissed;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getMonthStatsText() {
    final firstDay = DateTime(widget.month.year, widget.month.month, 1);
    final lastDay = DateTime(widget.month.year, widget.month.month + 1, 0);

    int completedDays = 0;
    int totalValidDays = 0;

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(widget.month.year, widget.month.month, day);

      // Skip future dates
      if (_isFutureDate(date)) continue;

      // Only count days that are valid for this habit
      if (widget.habit.isActiveOnDate(date) && _isValidDay(date)) {
        totalValidDays++;

        final status = widget.habit.getStatusForDate(date);
        if (status == HabitStatus.completed) {
          completedDays++;
        }
      }
    }

    final currentStreak = widget.habit.getCurrentStreak();
    final completionRate = totalValidDays > 0
        ? (completedDays / totalValidDays * 100)
        : 0.0;

    if (totalValidDays == 0) {
      return "No active days this month";
    }

    return "${completionRate.round()}% completed • ${currentStreak} day streak";
  }
}
