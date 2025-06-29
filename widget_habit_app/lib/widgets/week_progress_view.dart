import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add for haptic feedback
import '../models/habit.dart';
import '../themes/habit_theme.dart';

class WeekProgressView extends StatefulWidget {
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
  State<WeekProgressView> createState() => _WeekProgressViewState();
}

class _WeekProgressViewState extends State<WeekProgressView>
    with SingleTickerProviderStateMixin {
  late AnimationController _sharedController;
  late Animation<double> _scaleAnimation;
  int? _activeIndex; // Track which day is currently animating

  @override
  void initState() {
    super.initState();
    // Single shared animation controller (instead of 7)
    _sharedController = AnimationController(
      duration: const Duration(milliseconds: 150), // Reduced from 200ms
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      // Less dramatic scale
      CurvedAnimation(
        parent: _sharedController,
        curve: Curves.easeOutCubic, // Smoother curve for better performance
      ),
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

  // Check if a date is in the future
  bool _isFutureDate(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.isAfter(normalizedToday);
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

  @override
  Widget build(BuildContext context) {
    final weekStart = widget.currentWeekStart ?? _getWeekStart(DateTime.now());

    return RepaintBoundary(
      // Add repaint boundary
      child: Container(
        height: 75,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            final status = widget.habit.getStatusForDate(day);
            final isValidDay = _isValidDay(day);
            final isActiveDate = widget.habit.isActiveOnDate(day);
            final isFuture = _isFutureDate(day);

            return RepaintBoundary(
              // Add repaint boundary for each day
              child: GestureDetector(
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
                      child: child!,
                    );
                  },
                  child: Column(
                    // Make child const for better performance
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getBrighterDateTextColor(
                            status,
                            isFuture,
                            isValidDay,
                            isActiveDate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildSmartTickBox(
                        day,
                        status,
                        isFuture,
                        isValidDay,
                        isActiveDate,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Check if a day is valid according to habit frequency
  bool _isValidDay(DateTime date) {
    if (widget.habit.frequency.isEmpty) {
      return true; // All days valid if no frequency set
    }
    return widget.habit.frequency.contains(date.weekday);
  }

  // Get appropriate tap handler based on habit type and day validity
  VoidCallback? _getOnTapHandler(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    // Phase 3A.2.2: Check active date FIRST
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
      // Simple habit: cycle through states
      return () {
        final nextStatus = _getNextStatus(status);
        widget.onDateTap!(day, nextStatus);
      };
    } else {
      // FIXED: Measurable habit - smart tap logic with missed status handling
      return () {
        // Provide haptic feedback for better UX
        HapticFeedback.lightImpact();

        if (status == HabitStatus.completed) {
          // If completed, reset to empty (allow user to restart)
          widget.habit.resetValueForDate(day);
        } else if (status == HabitStatus.missed) {
          // If missed, reset to empty (allow user to retry)
          widget.habit.resetValueForDate(day);
        } else {
          // If empty or partial, increment value as before
          widget.habit.incrementValue(day);
        }

        // Trigger update through the callback
        widget.onDateTap!(day, widget.habit.getStatusForDate(day));
      };
    }
  }

  // NEW: Long press handler for advanced interactions
  VoidCallback? _getLongPressHandler(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    // Only provide long press for valid, active, non-future days
    if (!isActiveDate || !isValidDay || isFuture) {
      return null;
    }

    if (widget.onDateTap == null) return null;

    // Long press behavior for both habit types
    return () {
      // Provide stronger haptic feedback for long press
      HapticFeedback.mediumImpact();

      if (widget.habit.type == HabitType.simple) {
        // Simple habit: long press cycles to missed or empty
        HabitStatus nextStatus;
        if (status == HabitStatus.missed) {
          nextStatus = HabitStatus.empty; // Missed -> Empty
        } else {
          nextStatus = HabitStatus.missed; // Any other -> Missed
        }
        widget.onDateTap!(day, nextStatus);
      } else {
        // Measurable habit: long press toggles missed state
        if (status == HabitStatus.missed) {
          // If already missed, reset to empty
          widget.habit.resetValueForDate(day);
        } else {
          // Mark as missed (set to 0 and explicitly mark as missed)
          widget.habit.resetValueForDate(day);
          widget.habit.setStatusForDate(day, HabitStatus.missed);
        }

        // Trigger update through the callback
        widget.onDateTap!(day, widget.habit.getStatusForDate(day));
      }

      // Show feedback to user about long press action
      _showLongPressFeedback(status);
    };
  }

  // NEW: Show feedback for long press actions
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

  // Build smart tick box based on habit type and day state
  Widget _buildSmartTickBox(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    // Phase 3A.2.2: Check active date FIRST
    if (!isActiveDate) {
      return _buildInactiveTickBox();
    }

    if (!isValidDay) {
      return _buildExcludedTickBox();
    }

    if (isFuture) {
      return _buildFutureTickBox();
    }

    if (widget.habit.type == HabitType.simple) {
      return _buildSimpleTickBox(status);
    } else {
      return _buildMeasurableTickBox(day, status);
    }
  }

  // Build tick box for future dates
  Widget _buildFutureTickBox() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent like month view
        border: Border.all(color: Colors.grey[600]!, width: 1.5),
        borderRadius: BorderRadius.circular(6), // Match month view
      ),
      child: Icon(Icons.schedule, color: Colors.grey[500], size: 16),
    );
  }

  // Build tick box for excluded days (not in frequency)
  Widget _buildExcludedTickBox() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent like month view
        border: Border.all(color: Colors.grey[600]!, width: 1.5),
        borderRadius: BorderRadius.circular(6), // Match month view
      ),
      child: Icon(Icons.block, color: Colors.grey[500], size: 16),
    );
  }

  // Build tick box for inactive dates (outside date range)
  Widget _buildInactiveTickBox() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent like month view
        border: Border.all(color: Colors.grey[600]!, width: 1.5),
        borderRadius: BorderRadius.circular(6), // Match month view
      ),
      child: Icon(
        Icons.calendar_today_outlined,
        color: Colors.grey[500],
        size: 16,
      ),
    );
  }

  // Build tick box for simple habits
  Widget _buildSimpleTickBox(HabitStatus status) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getMeasurableBackgroundColor(status), // Use same as measurable
        border: Border.all(
          color: _getMeasurableBorderColor(status), // Use same as measurable
          width: 1.5, // Match month view
        ),
        borderRadius: BorderRadius.circular(6), // Match month view
      ),
      child: _buildStatusIcon(status),
    );
  }

  // Build tick box for measurable habits with progress
  Widget _buildMeasurableTickBox(DateTime day, HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    final currentValue = widget.habit.getValueForDate(day);
    final isCompleted = status == HabitStatus.completed;
    final isMissed = status == HabitStatus.missed;
    final hasProgress = currentValue > 0;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getMeasurableBackgroundColor(status),
        border: Border.all(
          color: _getMeasurableBorderColor(status),
          width: 1.5, // Reduced from 2.0 to match month view
        ),
        borderRadius: BorderRadius.circular(
          6,
        ), // Reduced from 8 to match month view
      ),
      child: Center(
        child: isMissed
            ? Icon(
                Icons.close,
                color: habitTheme.habitMissed,
                size: 16,
              ) // Reduced from 18
            : isCompleted
            ? Icon(
                Icons.check,
                color: habitTheme.progressRingComplete,
                size: 16, // Reduced from 18
              )
            : hasProgress
            ? Text(
                '$currentValue',
                style: TextStyle(
                  fontSize: 16, // Increased from 12 to match month view
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Changed to white for consistency
                ),
              )
            : const SizedBox(width: 16, height: 16), // Clean empty state
      ),
    );
  }

  // Get BRIGHTER date text color based on state (improved visibility)
  Color _getBrighterDateTextColor(
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
    bool isActiveDate,
  ) {
    final habitTheme = HabitTheme.of(context);

    // Phase 3A.2.2: Check active date FIRST - only grey out if truly outside range
    if (!isActiveDate) {
      return Colors.grey[400]!; // Brighter than before (was grey[600])
    }

    if (!isValidDay) {
      return Colors.grey[300]!; // Brighter for excluded days
    }

    if (isFuture) {
      return Colors.grey[300]!; // Brighter for future dates
    }

    // Make status-based colors much brighter
    switch (status) {
      case HabitStatus.completed:
        return Colors.white; // Bright white for completed
      case HabitStatus.missed:
        return Colors.white; // Bright white for missed
      case HabitStatus.partial:
        return Colors.white; // Bright white for partial
      case HabitStatus.empty:
        return Colors.white; // Bright white for empty (was textPrimary)
    }
  }

  // Color helpers for measurable habits
  Color _getMeasurableBackgroundColor(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return habitTheme.progressRingComplete.withValues(alpha: 0.1);
      case HabitStatus.partial:
        return habitTheme.progressRingPartial.withValues(alpha: 0.1);
      case HabitStatus.missed:
        return habitTheme.habitMissed.withValues(alpha: 0.1);
      case HabitStatus.empty:
        return Colors.transparent;
    }
  }

  Color _getMeasurableBorderColor(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return habitTheme.progressRingComplete;
      case HabitStatus.partial:
        return habitTheme.progressRingPartial;
      case HabitStatus.missed:
        return habitTheme.habitMissed;
      case HabitStatus.empty:
        return habitTheme.cardBorder;
    }
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

  Widget _buildStatusIcon(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return Icon(
          Icons.check,
          color: habitTheme
              .progressRingComplete, // Use progress color for consistency
          size: 16, // Reduced from 18 to match month view
        );
      case HabitStatus.missed:
        return Icon(
          Icons.close,
          color: habitTheme.habitMissed,
          size: 16, // Reduced from 18 to match month view
        );
      case HabitStatus.partial:
        return Icon(
          Icons.more_horiz,
          color: habitTheme.progressRingPartial,
          size: 16,
        );
      case HabitStatus.empty:
        return const SizedBox(
          width: 16,
          height: 16,
        ); // Clean empty state like month view
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
      case HabitStatus.partial:
        return HabitStatus.completed; // Partial -> Complete
    }
  }
}
