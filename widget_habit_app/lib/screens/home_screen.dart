import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../widgets/habit_list_view.dart';
import '../widgets/home_screen_header.dart';
import '../widgets/week_view.dart';
import '../widgets/side_menu.dart';
import '../widgets/month_page_view.dart';
import 'add_edit_habit_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;
  DateTime _currentWeekStart = DateTime.now();
  static const int _initialPage = 1000; // Make const
  ViewMode _currentViewMode = ViewMode.week; // Add view mode state

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysFromMonday));
  }

  DateTime _getWeekStartForPage(int page) {
    final weeksOffset = page - _initialPage;
    return _getWeekStart(DateTime.now()).add(Duration(days: weeksOffset * 7));
  }

  String _getMonthYearText(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    const months = [
      // Make const without static
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

    if (_currentViewMode == ViewMode.week) {
      // Week mode: show week range
      if (weekStart.month == weekEnd.month) {
        return '${months[weekStart.month - 1]} ${weekStart.year}';
      } else {
        return '${months[weekStart.month - 1]} - ${months[weekEnd.month - 1]} ${weekStart.year}';
      }
    } else {
      // Month mode: show just month
      return '${months[weekStart.month - 1]} ${weekStart.year}';
    }
  }

  void _onViewModeChanged(ViewMode newMode) {
    setState(() {
      _currentViewMode = newMode;
    });
  }

  // FIXED: Async habit update handler for month view
  Future<void> _handleMonthHabitUpdate(
    DateTime date,
    HabitStatus newStatus,
  ) async {
    // Use microtasks to prevent blocking UI thread
    await Future.microtask(() async {
      // This is handled in MonthCalendarGrid's tap handler
      // No additional processing needed here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeScreenHeader(),
      drawer: SideMenu(
        currentViewMode: _currentViewMode,
        onViewModeChanged: _onViewModeChanged,
      ),
      body: Column(
        children: [
          // Month/Year header with navigation (only show in week mode)
          if (_currentViewMode == ViewMode.week) _buildNavigationHeader(),

          // Show week headers only in week mode
          if (_currentViewMode == ViewMode.week) const WeekView(),

          // Content based on view mode
          Expanded(
            child: _currentViewMode == ViewMode.week
                ? _buildWeekPageView()
                : RepaintBoundary(
                    // Add boundary for month view
                    child: MonthPageView(
                      onDateTap:
                          _handleMonthHabitUpdate, // FIXED: Proper callback
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // Extract navigation header to reduce build method complexity
  Widget _buildNavigationHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              if (_pageController.hasClients) {
                _pageController.previousPage(
                  duration: const Duration(
                    milliseconds: 200, // Even faster for less UI blocking
                  ),
                  curve: Curves.easeOut, // Simpler curve
                );
              }
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getMonthYearText(_currentWeekStart),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Week View',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70, // More performant than withValues
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              if (_pageController.hasClients) {
                _pageController.nextPage(
                  duration: const Duration(
                    milliseconds: 200, // Even faster for less UI blocking
                  ),
                  curve: Curves.easeOut, // Simpler curve
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Extract page view to reduce rebuilds
  Widget _buildWeekPageView() {
    return RepaintBoundary(
      // Add boundary
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          // Use microtask to prevent blocking during page change
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _currentWeekStart = _getWeekStartForPage(page);
              });
            }
          });
        },
        pageSnapping: true,
        physics: const PageScrollPhysics(), // Better snapping
        itemBuilder: (context, page) {
          final weekStart = _getWeekStartForPage(page);
          return HabitListView(
            key: ValueKey(weekStart), // Add key for better caching
            currentWeekStart: weekStart,
            viewMode: _currentViewMode,
          );
        },
      ),
    );
  }

  // Extract FAB to const widget
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddEditHabitScreen()),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
