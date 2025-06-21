import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers.dart';
import '../services/stats_service.dart';
import 'week_progress_view.dart';
import 'achievements_screen.dart';

class HabitListItem extends ConsumerWidget {
  final Habit habit;
  final DateTime? currentWeekStart;

  const HabitListItem({super.key, required this.habit, this.currentWeekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsService = StatsService();
    final streakStats = statsService.calculateStreakStats(habit);
    final achievements = statsService.getAchievements(habit);

    return Container(
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
          WeekProgressView(
            habit: habit,
            currentWeekStart: currentWeekStart,
            onDateTap: (date, newStatus) {
              habit.setStatusForDate(date, newStatus);
              ref.read(habitsProvider.notifier).updateHabit(habit);
            },
          ),

          // ALWAYS show stats summary
          const SizedBox(height: 8),
          _buildStatsSummary(context, streakStats, achievements),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(
    BuildContext context,
    StreakStats stats,
    List<Achievement> achievements,
  ) {
    return GestureDetector(
      onTap: () => _showAchievementsScreen(context, achievements, stats),
      child: Container(
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
            Text(_getStreakIcon(stats), style: const TextStyle(fontSize: 14)),
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

            // Completion rate if available
            if (stats.completionRate > 0) ...[
              Flexible(
                child: Text(
                  '${(stats.completionRate * 100).toInt()}%',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
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
