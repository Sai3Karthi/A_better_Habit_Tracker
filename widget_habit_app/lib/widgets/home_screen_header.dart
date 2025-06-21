import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('E').format(now).toUpperCase();
    final dayOfMonth = now.day;
    final month = DateFormat('MMM').format(now);

    return AppBar(
      title: const Text('Goals', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dayOfWeek,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$dayOfMonth $month', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
