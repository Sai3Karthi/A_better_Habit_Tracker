import '../models/habit.dart';

/// Centralized service for habit statistics and gamification
class StatsService {
  static const StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;
  const StatsService._internal();

  /// Calculate comprehensive streak statistics for a habit
  StreakStats calculateStreakStats(Habit habit) {
    final currentStreak = habit.getCurrentStreak();
    final longestStreak = habit.getLongestStreak();
    final completionRate = habit.getCompletionRate();

    // EMERGENCY: Ensure we always show SOMETHING
    final displayCurrent = currentStreak > 0 ? currentStreak : 0;
    final displayLongest = longestStreak > displayCurrent
        ? longestStreak
        : displayCurrent;
    final displayRate = completionRate > 0 ? completionRate : 0.0;

    // Force milestone calculation to show something
    final daysUntilNextMilestone = _getDaysUntilNextMilestone(displayCurrent);

    return StreakStats(
      current: displayCurrent,
      longest: displayLongest,
      completionRate: displayRate,
      streakTier: _getStreakTier(displayCurrent),
      isOnFire: displayCurrent >= 7,
      daysUntilNextMilestone: daysUntilNextMilestone,
    );
  }

  /// Get achievements earned by a habit
  List<Achievement> getAchievements(Habit habit) {
    final achievements = <Achievement>[];
    final longestStreak = habit.getLongestStreak();
    final completionRate = habit.getCompletionRate();

    // Streak achievements
    if (longestStreak >= 7) {
      achievements.add(
        Achievement(
          type: AchievementType.streak,
          title: 'Week Warrior',
          description: '7-day streak achieved!',
          iconData: '🔥',
          tier: AchievementTier.bronze,
        ),
      );
    }

    if (longestStreak >= 30) {
      achievements.add(
        Achievement(
          type: AchievementType.streak,
          title: 'Month Master',
          description: '30-day streak achieved!',
          iconData: '💪',
          tier: AchievementTier.silver,
        ),
      );
    }

    if (longestStreak >= 100) {
      achievements.add(
        Achievement(
          type: AchievementType.streak,
          title: 'Century Champion',
          description: '100-day streak achieved!',
          iconData: '👑',
          tier: AchievementTier.gold,
        ),
      );
    }

    if (longestStreak >= 365) {
      achievements.add(
        Achievement(
          type: AchievementType.streak,
          title: 'Year Legend',
          description: '365-day streak achieved!',
          iconData: '🏆',
          tier: AchievementTier.platinum,
        ),
      );
    }

    // Consistency achievements
    if (completionRate >= 0.5) {
      achievements.add(
        Achievement(
          type: AchievementType.consistency,
          title: 'Steady Progress',
          description: '50% consistency maintained!',
          iconData: '📈',
          tier: AchievementTier.bronze,
        ),
      );
    }

    if (completionRate >= 0.8) {
      achievements.add(
        Achievement(
          type: AchievementType.consistency,
          title: 'High Achiever',
          description: '80% consistency maintained!',
          iconData: '⭐',
          tier: AchievementTier.silver,
        ),
      );
    }

    if (completionRate >= 0.95) {
      achievements.add(
        Achievement(
          type: AchievementType.consistency,
          title: 'Perfectionist',
          description: '95% consistency maintained!',
          iconData: '💎',
          tier: AchievementTier.gold,
        ),
      );
    }

    return achievements;
  }

  /// Calculate points for gamification system
  int calculatePoints(List<Habit> habits) {
    int totalPoints = 0;

    for (final habit in habits) {
      final stats = calculateStreakStats(habit);

      // Points for current streak
      totalPoints += stats.current * 10;

      // Bonus points for long streaks
      if (stats.current >= 7) totalPoints += 50;
      if (stats.current >= 30) totalPoints += 200;
      if (stats.current >= 100) totalPoints += 500;

      // Points for completion rate
      totalPoints += (stats.completionRate * 100).round();
    }

    return totalPoints;
  }

  /// Get streak tier based on current streak
  StreakTier _getStreakTier(int streak) {
    if (streak >= 100) return StreakTier.platinum;
    if (streak >= 30) return StreakTier.gold;
    if (streak >= 7) return StreakTier.silver;
    if (streak >= 1) return StreakTier.bronze;
    return StreakTier.none;
  }

  /// Calculate days until next milestone
  int _getDaysUntilNextMilestone(int currentStreak) {
    const milestones = [7, 30, 100, 365];

    // EMERGENCY: Always return a visible number
    if (currentStreak <= 0) return 7; // Show 7 days to first milestone

    // Find the next milestone the user hasn't achieved yet
    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return milestone - currentStreak;
      }
    }

    // Already at highest milestone (365+), show next century milestone
    final nextCenturyMilestone = ((currentStreak ~/ 100) + 1) * 100;
    return nextCenturyMilestone - currentStreak;
  }
}

/// Data class for streak statistics
class StreakStats {
  final int current;
  final int longest;
  final double completionRate;
  final StreakTier streakTier;
  final bool isOnFire;
  final int daysUntilNextMilestone;

  const StreakStats({
    required this.current,
    required this.longest,
    required this.completionRate,
    required this.streakTier,
    required this.isOnFire,
    required this.daysUntilNextMilestone,
  });
}

/// Achievement data class
class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final String iconData;
  final AchievementTier tier;

  const Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.iconData,
    required this.tier,
  });
}

/// Types of achievements
enum AchievementType { streak, consistency, completion, milestone }

/// Achievement tiers for visual distinction
enum AchievementTier { bronze, silver, gold, platinum }

/// Streak tiers for visual indication
enum StreakTier { none, bronze, silver, gold, platinum }
