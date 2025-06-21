import 'package:flutter/material.dart';
import '../models/habit.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Can't complete future habits"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
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

          return GestureDetector(
            onTapDown: isFuture ? null : (_) => _onTapDown(index),
            onTapUp: isFuture ? null : (_) => _onTapUp(index),
            onTapCancel: isFuture ? null : () => _onTapUp(index),
            onTap: isFuture
                ? _showFutureDateFeedback
                : (widget.onDateTap != null
                      ? () {
                          final nextStatus = _getNextStatus(status);
                          widget.onDateTap!(day, nextStatus);
                        }
                      : null),
            child: AnimatedBuilder(
              animation: _scaleAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: isFuture ? 1.0 : _scaleAnimations[index].value,
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
                          color: isFuture
                              ? Colors.grey[500]
                              : _getDateColor(status),
                        ),
                      ),
                      const SizedBox(height: 4), // Increased spacing
                      // Enhanced status indicator (dramatic size)
                      _buildDramaticTickBox(status, isFuture),
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

  Widget _buildDramaticTickBox(HabitStatus status, bool isFuture) {
    return Container(
      width: 36, // Increased from 24
      height: 36, // Increased from 24
      decoration: BoxDecoration(
        color: isFuture ? Colors.grey[800] : _getBackgroundColor(status),
        border: Border.all(
          color: isFuture ? Colors.grey[600]! : _getBorderColor(status),
          width: 2.0, // Increased border width
        ),
        borderRadius: BorderRadius.circular(8), // Slightly larger radius
        boxShadow: isFuture ? [] : _getBoxShadow(status),
      ),
      child: isFuture ? _buildFutureIcon() : _buildStatusIcon(status),
    );
  }

  Widget _buildFutureIcon() {
    return Icon(Icons.schedule, color: Colors.grey[500], size: 16);
  }

  List<BoxShadow> _getBoxShadow(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
      case HabitStatus.missed:
        return [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
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
        return const Icon(
          Icons.check,
          color: Colors.green,
          size: 18, // Increased from 14
        );
      case HabitStatus.missed:
        return const Icon(
          Icons.close,
          color: Colors.red,
          size: 18, // Increased from 14
        );
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
