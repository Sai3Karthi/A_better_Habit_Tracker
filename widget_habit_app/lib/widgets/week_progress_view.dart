import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    // Create animation controllers for each day
    _animationControllers = List.generate(
      7,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) => Tween<double>(begin: 1.0, end: 0.85).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTapDown(int index) {
    _animationControllers[index].forward();
  }

  void _onTapUp(int index) {
    _animationControllers[index].reverse();
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

  @override
  Widget build(BuildContext context) {
    final weekStart = widget.currentWeekStart ?? _getWeekStart(DateTime.now());

    return Container(
      height: 54, // Increased to accommodate larger tick boxes
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final status = widget.habit.getStatusForDate(day);
          final isFuture = _isFutureDate(day);
          final isValidDay = _isValidDay(day);

          return GestureDetector(
            onTapDown: (isFuture || !isValidDay)
                ? null
                : (_) => _onTapDown(index),
            onTapUp: (isFuture || !isValidDay) ? null : (_) => _onTapUp(index),
            onTapCancel: (isFuture || !isValidDay)
                ? null
                : () => _onTapUp(index),
            onTap: _getOnTapHandler(day, status, isFuture, isValidDay),
            child: AnimatedBuilder(
              animation: _scaleAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: (isFuture || !isValidDay)
                      ? 1.0
                      : _scaleAnimations[index].value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Date number (aligned with header)
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getDateTextColor(
                            status,
                            isFuture,
                            isValidDay,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4), // Increased spacing
                      // Enhanced status indicator based on habit type
                      _buildSmartTickBox(day, status, isFuture, isValidDay),
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
  ) {
    if (isFuture) {
      return _showFutureDateFeedback;
    }

    if (!isValidDay) {
      return () => _showExcludedDayFeedback();
    }

    if (widget.onDateTap == null) return null;

    if (widget.habit.type == HabitType.simple) {
      // Simple habit: cycle through states
      return () {
        final nextStatus = _getNextStatus(status);
        widget.onDateTap!(day, nextStatus);
      };
    } else {
      // Measurable habit: increment value
      return () {
        widget.habit.incrementValue(day);
        // Trigger update through the callback
        widget.onDateTap!(day, widget.habit.getStatusForDate(day));
      };
    }
  }

  // Build smart tick box based on habit type and day state
  Widget _buildSmartTickBox(
    DateTime day,
    HabitStatus status,
    bool isFuture,
    bool isValidDay,
  ) {
    if (isFuture) {
      return _buildFutureTickBox();
    }

    if (!isValidDay) {
      return _buildExcludedTickBox();
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: habitTheme.habitFuture,
        border: Border.all(color: habitTheme.cardBorder, width: 2.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.schedule, color: habitTheme.textSecondary, size: 16),
    );
  }

  // Build tick box for excluded days (not in frequency)
  Widget _buildExcludedTickBox() {
    final habitTheme = HabitTheme.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: habitTheme.habitExcluded,
        border: Border.all(color: habitTheme.cardBorder, width: 2.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.block, color: habitTheme.textSecondary, size: 16),
    );
  }

  // Build tick box for simple habits
  Widget _buildSimpleTickBox(HabitStatus status) {
    return Container(
      width: 36,
      height: 36,
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
    final hasProgress = currentValue > 0;

    return Container(
      width: 36,
      height: 36,
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
          // Progress ring
          if (hasProgress && !isCompleted)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 2,
                backgroundColor: habitTheme.progressBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0
                      ? habitTheme.progressRingComplete
                      : habitTheme.progressRingPartial,
                ),
              ),
            ),

          // Content (progress text or completion icon)
          Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    color: habitTheme.progressRingComplete,
                    size: 16,
                  )
                : hasProgress
                ? Text(
                    '$currentValue',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: habitTheme.textPrimary,
                    ),
                  )
                : Icon(Icons.add, color: habitTheme.textHint, size: 16),
          ),
        ],
      ),
    );
  }

  // Get date text color based on state
  Color _getDateTextColor(HabitStatus status, bool isFuture, bool isValidDay) {
    final habitTheme = HabitTheme.of(context);
    if (isFuture || !isValidDay) {
      return habitTheme.textHint;
    }
    return _getDateColor(status);
  }

  // Color helpers for measurable habits
  Color _getMeasurableBackgroundColor(HabitStatus status) {
    final habitTheme = HabitTheme.of(context);
    switch (status) {
      case HabitStatus.completed:
        return habitTheme.progressRingComplete.withValues(alpha: 0.1);
      case HabitStatus.partial:
        return habitTheme.progressRingPartial.withValues(alpha: 0.1);
      case HabitStatus.empty:
      case HabitStatus.missed:
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
      case HabitStatus.empty:
      case HabitStatus.missed:
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
      case HabitStatus.empty:
      case HabitStatus.missed:
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
