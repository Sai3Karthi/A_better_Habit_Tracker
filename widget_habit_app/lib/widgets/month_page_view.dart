import 'package:flutter/material.dart';
import 'month_habit_view.dart';
import '../models/habit.dart';

class MonthPageView extends StatefulWidget {
  final Function(DateTime, HabitStatus)? onDateTap;

  const MonthPageView({super.key, this.onDateTap});

  @override
  State<MonthPageView> createState() => _MonthPageViewState();
}

class _MonthPageViewState extends State<MonthPageView> {
  late PageController _monthPageController;
  late DateTime _currentMonth;
  final int _initialPage = 1000; // Start from middle for infinite scroll

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _monthPageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  // Get month for specific page
  DateTime _getMonthForPage(int page) {
    final monthsOffset = page - _initialPage;
    final now = DateTime.now();
    final baseMonth = DateTime(now.year, now.month, 1);

    if (monthsOffset == 0) {
      return baseMonth;
    } else if (monthsOffset > 0) {
      // Future months
      return DateTime(baseMonth.year, baseMonth.month + monthsOffset, 1);
    } else {
      // Past months
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month navigation header
        Container(
          height: 58, // Match existing header height
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  if (_monthPageController.hasClients) {
                    _monthPageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
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
                  Text(
                    'Month View',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  if (_monthPageController.hasClients) {
                    _monthPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // Vertical month scroller (fills remaining screen)
        Expanded(
          child: PageView.builder(
            controller: _monthPageController,
            scrollDirection: Axis.vertical, // Vertical scrolling for months
            onPageChanged: (page) {
              setState(() {
                _currentMonth = _getMonthForPage(page);
              });
            },
            itemBuilder: (context, page) {
              final month = _getMonthForPage(page);
              return MonthHabitView(month: month, onDateTap: widget.onDateTap);
            },
          ),
        ),
      ],
    );
  }
}
