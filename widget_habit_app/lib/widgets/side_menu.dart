import 'package:flutter/material.dart';
import '../themes/habit_theme.dart';

enum ViewMode { week, month }

class SideMenu extends StatelessWidget {
  final ViewMode currentViewMode;
  final Function(ViewMode) onViewModeChanged;

  const SideMenu({
    super.key,
    required this.currentViewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final habitTheme = HabitTheme.of(context);

    return Drawer(
      backgroundColor: Colors.grey[900], // Match dark theme
      child: SafeArea(
        child: Column(
          children: [
            // Simple header - no branding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              color: Colors.grey[850],
              child: Text(
                'VIEW MODE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: habitTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // View Mode Options
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Week View Option
                  _buildViewOption(
                    context,
                    icon: Icons.view_week,
                    title: 'Week View',
                    subtitle: '7-day progress grid',
                    isSelected: currentViewMode == ViewMode.week,
                    onTap: () => _selectViewMode(context, ViewMode.week),
                  ),

                  const SizedBox(height: 12),

                  // Month View Option
                  _buildViewOption(
                    context,
                    icon: Icons.calendar_month,
                    title: 'Month View',
                    subtitle: 'Monthly calendar layout',
                    isSelected: currentViewMode == ViewMode.month,
                    onTap: () => _selectViewMode(context, ViewMode.month),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.grey),

            // Settings Section
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings screen
              },
            ),

            // About Section
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white),
              title: Text('About', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),

            const Spacer(),

            // Simple footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'v1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final habitTheme = HabitTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[800] : Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: habitTheme.buttonPrimary, width: 2)
                : Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? habitTheme.buttonPrimary : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? habitTheme.buttonPrimary
                            : Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: habitTheme.buttonPrimary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectViewMode(BuildContext context, ViewMode mode) {
    Navigator.pop(context); // Close drawer
    onViewModeChanged(mode);
  }

  void _showAboutDialog(BuildContext context) {
    final habitTheme = HabitTheme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('About', style: TextStyle(color: Colors.white)),
        content: Text(
          'Elysian Goals - Habit Tracker\n\n'
          'Features:\n'
          '• Simple & Measurable habits\n'
          '• Smart streak calculations\n'
          '• Achievement system\n'
          '• Performance optimized\n'
          '• Frequency customization\n\n'
          'Version: 1.0.0 (Phase 3A)',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: habitTheme.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
