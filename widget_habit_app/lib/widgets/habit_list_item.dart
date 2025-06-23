import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers.dart';
import '../services/stats_service.dart';
import '../services/habit_stats_cache.dart';
import '../themes/habit_theme.dart';
import '../widgets/side_menu.dart'; // Import for ViewMode
import 'week_progress_view.dart';
import 'achievements_screen.dart';

class HabitListItem extends ConsumerWidget {
  final Habit habit;
  final DateTime? currentWeekStart;
  final ViewMode viewMode;

  const HabitListItem({
    super.key,
    required this.habit,
    this.currentWeekStart,
    this.viewMode = ViewMode.week, // Default to week mode
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use cached stats for better performance
    final streakStats = HabitStatsCache.getStreakStats(habit);
    final achievements = HabitStatsCache.getAchievements(habit);

    return GestureDetector(
      onLongPress: () {
        _showDeleteConfirmation(context, ref);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: streakStats.isOnFire
              ? Border.all(
                  color: _getStreakColor(streakStats.streakTier),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with habit name and streak badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // ALWAYS show streak badge, even if 0
                _buildStreakBadge(context, streakStats, achievements),
              ],
            ),

            // Achievement badges row (if any)
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildAchievementBadges(achievements),
            ],

            const SizedBox(height: 8),

            // Show progress view based on current view mode
            if (viewMode == ViewMode.week)
              WeekProgressView(
                habit: habit,
                currentWeekStart: currentWeekStart,
                onDateTap: (date, newStatus) {
                  habit.setStatusForDate(date, newStatus);
                  ref.read(habitsProvider.notifier).updateHabit(habit);
                },
              )
            else
              // TODO: Implement MonthProgressView
              Text(
                'Month view coming soon...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),

            // ALWAYS show stats summary
            const SizedBox(height: 8),
            _buildStatsSummary(context, streakStats, achievements),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge(
    BuildContext context,
    StreakStats stats,
    List<Achievement> achievements,
  ) {
    final failStreak = habit.getCurrentFailStreak();

    return GestureDetector(
      onTap: () => _showAchievementsScreen(context, achievements, stats),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStreakColor(stats.streakTier),
              borderRadius: BorderRadius.circular(12),
              boxShadow: stats.isOnFire
                  ? [
                      BoxShadow(
                        color: _getStreakColor(
                          stats.streakTier,
                        ).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStreakIcon(stats),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '${stats.current}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Fail streak badge (only if there are fails)
          if (failStreak > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💔', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$failStreak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStreakIcon(StreakStats stats) {
    if (stats.current == 0) return '⚡';
    if (stats.current < 7) return '⚡'; // Lightning for 1-6 days
    return '🔥'; // Fire for 7+ days (on fire)
  }

  Widget _buildAchievementBadges(List<Achievement> achievements) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: achievements.take(3).map((achievement) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getAchievementColor(achievement.tier),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.iconData,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 2),
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSummary(
    BuildContext context,
    StreakStats stats,
    List<Achievement> achievements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // ALWAYS show best streak (removed redundant current)
            Text(
              'Best: ${stats.longest}',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
            const SizedBox(width: 8),

            // Completion stats (NEW)
            Text(
              habit.getCompletionStats().getDisplayText(),
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),

            // Date range info if available (Phase 3A.2.2)
            if (habit.getDateRangeText().isNotEmpty) ...[
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today, size: 10, color: Colors.grey),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  habit.getDateRangeText(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const Spacer(),

            // Achievement tap hint if available
            if (achievements.isNotEmpty) ...[
              Flexible(
                child: Text(
                  'Tap for achievements',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),

        // ALWAYS show milestone countdown
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () => _showAchievementsScreen(context, achievements, stats),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[400]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag, color: Colors.blue[400], size: 10),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${stats.daysUntilNextMilestone} days to achieve next milestone',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAchievementsScreen(
    BuildContext context,
    List<Achievement> achievements,
    StreakStats streakStats,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AchievementsScreen(
          habit: habit,
          achievements: achievements,
          streakStats: streakStats,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final habitTheme = HabitTheme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: habitTheme.cardBackground,
          title: Text(
            'Delete Habit',
            style: TextStyle(color: habitTheme.textPrimary),
          ),
          content: Text(
            'Bro you damn sure you want to delete this habit? "${habit.name}"? i give you 5 fucking seconds to change your mind dont cry later.',
            style: TextStyle(color: habitTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: habitTheme.textHint),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                // Store habit info before async operations to avoid context issues
                final habitId = habit.id;
                final habitName = habit.name;

                try {
                  await ref
                      .read(habitsProvider.notifier)
                      .temporaryDeleteHabit(habitId);

                  // Show success feedback with working undo
                  if (context.mounted) {
                    _showDeleteFeedback(context, ref, habitId, habitName);
                  }
                } catch (e) {
                  // TODO: Show error dialog if needed
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(color: habitTheme.habitMissed),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFeedback(
    BuildContext context,
    WidgetRef ref,
    String habitId,
    String habitName,
  ) {
    final habitTheme = HabitTheme.of(context);

    // Store the provider container when creating the SnackBar, not when undo is clicked
    final container = ProviderScope.containerOf(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: habitTheme.cardBackground,
        content: Text(
          'Habit "$habitName" deleted',
          style: TextStyle(color: habitTheme.textPrimary),
        ),
        duration: const Duration(seconds: 5), // Match undo timeout
        action: SnackBarAction(
          label: 'Undo',
          textColor: habitTheme.habitCompleted,
          onPressed: () {
            // Use the stored container directly, no context needed
            _performUndoWithContainer(container, context, habitId, habitName);
          },
        ),
      ),
    );
  }

  void _performUndoWithContainer(
    ProviderContainer container,
    BuildContext snackBarContext,
    String habitId,
    String habitName,
  ) {
    try {
      final habitNotifier = container.read(habitsProvider.notifier);

      habitNotifier
          .restoreHabit(habitId)
          .then((_) {
            // Show restore confirmation - use the snackbar's context
            try {
              // Check if context is still mounted before using it
              if (snackBarContext.mounted) {
                final habitTheme = HabitTheme.of(snackBarContext);
                ScaffoldMessenger.of(snackBarContext).hideCurrentSnackBar();
                ScaffoldMessenger.of(snackBarContext).showSnackBar(
                  SnackBar(
                    backgroundColor: habitTheme.cardBackground,
                    content: Text(
                      'Habit "$habitName" restored',
                      style: TextStyle(color: habitTheme.habitCompleted),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              // Could not show restore confirmation
            }
          })
          .catchError((e) {
            try {
              // Check if context is still mounted before using it
              if (snackBarContext.mounted) {
                final habitTheme = HabitTheme.of(snackBarContext);
                ScaffoldMessenger.of(snackBarContext).showSnackBar(
                  SnackBar(
                    backgroundColor: habitTheme.cardBackground,
                    content: Text(
                      'Could not restore habit. It may have expired.',
                      style: TextStyle(color: habitTheme.habitMissed),
                    ),
                  ),
                );
              }
            } catch (e) {
              // Could not show error message
            }
          });
    } catch (e) {
      // Error using ProviderContainer
    }
  }

  Color _getStreakColor(StreakTier tier) {
    switch (tier) {
      case StreakTier.platinum:
        return const Color(0xFFE6E6FA); // Lavender
      case StreakTier.gold:
        return const Color(0xFFFFD700); // Gold
      case StreakTier.silver:
        return const Color(0xFF007AFF); // Blue
      case StreakTier.bronze:
        return const Color(0xFFFF9500); // Orange
      case StreakTier.none:
        return Colors.grey[600]!;
    }
  }

  Color _getAchievementColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.platinum:
        return const Color(0xFF9932CC); // Dark Orchid
      case AchievementTier.gold:
        return const Color(0xFFB8860B); // Dark Goldenrod
      case AchievementTier.silver:
        return const Color(0xFF4682B4); // Steel Blue
      case AchievementTier.bronze:
        return const Color(0xFFCD853F); // Peru
    }
  }
}
