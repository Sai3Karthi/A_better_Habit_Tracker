import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/stats_service.dart';

class AchievementsScreen extends StatelessWidget {
  final Habit habit;
  final List<Achievement> achievements;
  final StreakStats streakStats;

  const AchievementsScreen({
    super.key,
    required this.habit,
    required this.achievements,
    required this.streakStats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.name} - Achievements'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Stats Card
            _buildCurrentStatsCard(),
            const SizedBox(height: 20),

            // Earned Achievements
            if (achievements.isNotEmpty) ...[
              Text(
                'Earned Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...achievements.map(
                (achievement) => _buildAchievementCard(achievement),
              ),
              const SizedBox(height: 20),
            ],

            // All Milestones Progress
            Text(
              'Milestone Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMilestoneProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        border: streakStats.isOnFire
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Current Streak
              Expanded(
                child: Column(
                  children: [
                    Text(
                      streakStats.isOnFire ? '🔥' : '⚡',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${streakStats.current}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Current Streak',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Longest Streak
              Expanded(
                child: Column(
                  children: [
                    Text('👑', style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      '${streakStats.longest}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Best Streak',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Completion Rate
              Expanded(
                child: Column(
                  children: [
                    Text('📈', style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      '${(streakStats.completionRate * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Completion Rate',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getAchievementColor(achievement.tier),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Achievement Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getAchievementColor(achievement.tier),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                achievement.iconData,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Achievement Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),

          // Tier Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getAchievementColor(achievement.tier),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getTierName(achievement.tier),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress() {
    final milestones = [
      {'days': 7, 'title': 'Week Warrior', 'icon': '🔥'},
      {'days': 30, 'title': 'Month Master', 'icon': '💪'},
      {'days': 100, 'title': 'Century Champion', 'icon': '👑'},
      {'days': 365, 'title': 'Year Legend', 'icon': '🏆'},
    ];

    return Column(
      children: milestones.map((milestone) {
        final days = milestone['days'] as int;
        final title = milestone['title'] as String;
        final icon = milestone['icon'] as String;

        final achieved = streakStats.longest >= days;
        final progress = achieved
            ? 1.0
            : (streakStats.current / days).clamp(0.0, 1.0);
        final remaining = achieved ? 0 : days - streakStats.current;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: achieved
                ? Colors.green[900]!.withValues(alpha: 0.3)
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: achieved
                ? Border.all(color: Colors.green[400]!, width: 2)
                : Border.all(color: Colors.grey[600]!, width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: achieved ? Colors.green[400] : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          achieved ? 'Achieved!' : '$remaining days remaining',
                          style: TextStyle(
                            color: achieved
                                ? Colors.green[300]
                                : Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (achieved) ...[
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[400],
                      size: 24,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  achieved ? Colors.green[400]! : Colors.blue[400]!,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${streakStats.current}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  Text(
                    '$days days',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
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

  String _getTierName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.platinum:
        return 'PLATINUM';
      case AchievementTier.gold:
        return 'GOLD';
      case AchievementTier.silver:
        return 'SILVER';
      case AchievementTier.bronze:
        return 'BRONZE';
    }
  }
}
