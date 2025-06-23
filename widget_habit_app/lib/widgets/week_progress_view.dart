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
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
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

    return Container(
      height: 75, // Increased to accommodate 44x44 tick boxes + spacing
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
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
                // Only apply animation to the active index
                final shouldAnimate = _activeIndex == index;
                return Transform.scale(
                  scale: (!isActiveDate || !isValidDay || isFuture)
                      ? 1.0
                      : shouldAnimate
                      ? _scaleAnimation.value
                      : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Date number (BRIGHTENED for better visibility)
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14, // Increased from 12
                          fontWeight: FontWeight.bold,
                          color: _getBrighterDateTextColor(
                            status,
                            isFuture,
                            isValidDay,
                            isActiveDate,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ), // Increased spacing for larger boxes
                      // Enhanced status indicator based on habit type
                      _buildSmartTickBox(
                        day,
                        status,
                        isFuture,
                        isValidDay,
                        isActiveDate,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
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
    final habitTheme = HabitTheme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: habitTheme.habitFuture,
        border: Border.all(color: habitTheme.cardBorder, width: 2.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.schedule, color: habitTheme.textSecondary, size: 18),
    );
  }

  // Build tick box for excluded days (not in frequency)
  Widget _buildExcludedTickBox() {
    final habitTheme = HabitTheme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: habitTheme.habitExcluded,
        border: Border.all(color: habitTheme.cardBorder, width: 2.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.block, color: habitTheme.textSecondary, size: 18),
    );
  }

  // Build tick box for inactive dates (outside date range)
  Widget _buildInactiveTickBox() {
    final habitTheme = HabitTheme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.3),
        border: Border.all(color: Colors.grey[600]!, width: 1.0),
        borderRadius: BorderRadius.circular(8),
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
        color: _getBackgroundColor(status),
        border: Border.all(color: _getBorderColor(status), width: 2.0),
        borderRadius: BorderRadius.circular(8),
        boxShadow: _getBoxShadow(status),
      ),
      child: _buildStatusIcon(status),
    );
  }

  // Build tick box for measurable habits with progress
  Widget _buildMeasurableTickBox(DateTime day, HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    final currentValue = widget.habit.getValueForDate(day);
    final targetValue = widget.habit.targetValue ?? 1;
    final progress = currentValue / targetValue;
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
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: _getMeasurableBoxShadow(status),
      ),
      child: Stack(
        children: [
          // Progress ring (only show if not missed and has progress)
          if (hasProgress && !isCompleted && !isMissed)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 2.5,
                backgroundColor: habitTheme.progressBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0
                      ? habitTheme.progressRingComplete
                      : habitTheme.progressRingPartial,
                ),
              ),
            ),

          // Content (progress text, completion icon, or missed icon)
          Center(
            child: isMissed
                ? Icon(Icons.close, color: habitTheme.habitMissed, size: 18)
                : isCompleted
                ? Icon(
                    Icons.check,
                    color: habitTheme.progressRingComplete,
                    size: 18,
                  )
                : hasProgress
                ? Text(
                    '$currentValue',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: habitTheme.textPrimary,
                    ),
                  )
                : Icon(Icons.add, color: habitTheme.textHint, size: 18),
          ),
        ],
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

  List<BoxShadow> _getMeasurableBoxShadow(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return [
          BoxShadow(
            color: habitTheme.progressRingComplete.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ];
      case HabitStatus.partial:
        return [
          BoxShadow(
            color: habitTheme.progressRingPartial.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ];
      case HabitStatus.missed:
        return [
          BoxShadow(
            color: habitTheme.habitMissed.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ];
      case HabitStatus.empty:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ];
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

  Color _getDateColor(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return habitTheme.habitCompleted;
      case HabitStatus.missed:
        return habitTheme.habitMissed;
      case HabitStatus.partial:
        return habitTheme.habitPartial;
      case HabitStatus.empty:
        return habitTheme.textPrimary;
    }
  }

  Color _getBackgroundColor(HabitStatus status) {
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

  Color _getBorderColor(HabitStatus status) {
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

  Widget _buildStatusIcon(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return Icon(
          Icons.check,
          color: habitTheme.habitCompleted,
          size: 18, // Increased from 14
        );
      case HabitStatus.missed:
        return Icon(
          Icons.close,
          color: habitTheme.habitMissed,
          size: 18, // Increased from 14
        );
      case HabitStatus.partial:
        return Icon(Icons.more_horiz, color: habitTheme.habitPartial, size: 18);
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
      case HabitStatus.partial:
        return HabitStatus.completed; // Partial -> Complete
    }
  }

  List<BoxShadow> _getBoxShadow(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return [
          BoxShadow(
            color: habitTheme.habitCompleted.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: habitTheme.habitCompleted.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
      case HabitStatus.missed:
        return [
          BoxShadow(
            color: habitTheme.habitMissed.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ];
      case HabitStatus.partial:
        return [
          BoxShadow(
            color: habitTheme.habitPartial.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ];
      case HabitStatus.empty:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ];
    }
  }
}
