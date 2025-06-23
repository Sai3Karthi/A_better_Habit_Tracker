import 'package:flutter/material.dart';
import 'month_habit_view.dart';
import '../models/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class MonthPageView extends ConsumerStatefulWidget {
  final Function(DateTime, HabitStatus)? onDateTap;

  const MonthPageView({super.key, this.onDateTap});

  @override
  ConsumerState<MonthPageView> createState() => _MonthPageViewState();
}

class _MonthPageViewState extends ConsumerState<MonthPageView> {
  late PageController _monthPageController;
  late PageController _sharedHabitPageController; // SHARED HABIT CONTROLLER
  late DateTime _currentMonth;
  final int _initialPage = 1000;
  int _currentHabitIndex = 0; // CENTRALIZED HABIT INDEX

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _monthPageController = PageController(initialPage: _initialPage);
    _sharedHabitPageController = PageController(); // SHARED CONTROLLER
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _sharedHabitPageController.dispose(); // DISPOSE SHARED CONTROLLER
    super.dispose();
  }

  DateTime _getMonthForPage(int page) {
    final monthsOffset = page - _initialPage;
    final now = DateTime.now();
    final baseMonth = DateTime(now.year, now.month, 1);

    if (monthsOffset == 0) {
      return baseMonth;
    } else if (monthsOffset > 0) {
      return DateTime(baseMonth.year, baseMonth.month + monthsOffset, 1);
    } else {
      return DateTime(baseMonth.year, baseMonth.month + monthsOffset, 1);
    }
  }

  String _getMonthYearText(DateTime month) {
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
    return '${months[month.month - 1]} ${month.year}';
  }

  // CENTRALIZED HABIT NAVIGATION - this ensures all months stay in sync
  void _onHabitIndexChanged(int newIndex) {
    final habits = ref.read(habitsProvider);

    // BOUNDS CHECK: Ensure index is valid
    if (newIndex < 0 || newIndex >= habits.length) {
      return;
    }

    if (newIndex != _currentHabitIndex) {
      setState(() {
        _currentHabitIndex = newIndex;
      });

      // Animate shared controller to new index if it has clients and is properly initialized
      if (_sharedHabitPageController.hasClients &&
          _sharedHabitPageController.positions.isNotEmpty) {
        // Use Future.microtask to prevent potential animation conflicts
        Future.microtask(() {
          if (mounted && _sharedHabitPageController.hasClients) {
            _sharedHabitPageController.animateToPage(
              newIndex,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  // UPDATE HABIT INDEX BOUNDS when habits change
  void _updateHabitBounds(List<Habit> habits) {
    if (habits.isEmpty) {
      if (_currentHabitIndex != 0) {
        setState(() {
          _currentHabitIndex = 0;
        });
      }
      return;
    }

    // Ensure current index is within bounds
    if (_currentHabitIndex >= habits.length) {
      final newIndex = habits.length - 1;
      setState(() {
        _currentHabitIndex = newIndex;
      });

      // Update shared controller if needed with additional safety checks
      if (_sharedHabitPageController.hasClients &&
          _sharedHabitPageController.positions.isNotEmpty) {
        Future.microtask(() {
          if (mounted &&
              _sharedHabitPageController.hasClients &&
              _sharedHabitPageController.positions.isNotEmpty) {
            _sharedHabitPageController.animateToPage(
              newIndex,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch habits to handle bounds checking
    final habits = ref.watch(habitsProvider);

    // Update habit bounds when habits change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHabitBounds(habits);
    });

    return Column(
      children: [
        // Simple month navigation header
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                onPressed: () {
                  _monthPageController.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                },
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getMonthYearText(_currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Month View',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
                onPressed: () {
                  _monthPageController.nextPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ],
          ),
        ),

        // Month scroller with FIXED state management
        Expanded(
          child: PageView.builder(
            controller: _monthPageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (page) {
              setState(() {
                _currentMonth = _getMonthForPage(page);
              });
            },
            itemBuilder: (context, page) {
              final month = _getMonthForPage(page);

              // USE STABLE KEY based on month to prevent unnecessary rebuilds
              return MonthHabitView(
                key: ValueKey('${month.year}-${month.month}'), // STABLE KEY
                month: month,
                onDateTap: widget.onDateTap,
                sharedHabitPageController:
                    _sharedHabitPageController, // PASS SHARED CONTROLLER
                currentHabitIndex: _currentHabitIndex, // PASS CURRENT INDEX
                onHabitIndexChanged:
                    _onHabitIndexChanged, // CENTRALIZED CALLBACK
              );
            },
          ),
        ),
      ],
    );
  }
}
