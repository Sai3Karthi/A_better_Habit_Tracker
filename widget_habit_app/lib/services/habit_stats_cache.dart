import '../models/habit.dart';
import 'stats_service.dart';

/// Enhanced cached statistics with ALL expensive operations
class CachedHabitStats {
  final int currentStreak;
  final int currentFailStreak;
  final int longestStreak;
  final double completionRate;
  final StreakTier streakTier;
  final bool isOnFire;
  final int daysUntilNextMilestone;
  final List<Achievement> achievements;
  final CompletionStats completionStats;
  final String dateRangeText;
  final DateTime cacheTime;
  final String habitDataHash;

  const CachedHabitStats({
    required this.currentStreak,
    required this.currentFailStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.streakTier,
    required this.isOnFire,
    required this.daysUntilNextMilestone,
    required this.achievements,
    required this.completionStats,
    required this.dateRangeText,
    required this.cacheTime,
    required this.habitDataHash,
  });

  /// Create cached stats from a habit - NOW INCLUDES ALL EXPENSIVE OPERATIONS
  factory CachedHabitStats.fromHabit(Habit habit) {
    final statsService = StatsService();
    final streakStats = statsService.calculateStreakStats(habit);
    final achievements = statsService.getAchievements(habit);

    // CACHE the expensive operations that were causing frame drops
    final completionStats = habit.getCompletionStats();
    final dateRangeText = habit.getDateRangeText();
    final currentFailStreak = habit.getCurrentFailStreak();

    return CachedHabitStats(
      currentStreak: streakStats.current,
      currentFailStreak: currentFailStreak,
      longestStreak: streakStats.longest,
      completionRate: streakStats.completionRate,
      streakTier: streakStats.streakTier,
      isOnFire: streakStats.isOnFire,
      daysUntilNextMilestone: streakStats.daysUntilNextMilestone,
      achievements: achievements,
      completionStats: completionStats,
      dateRangeText: dateRangeText,
      cacheTime: DateTime.now(),
      habitDataHash: _generateHabitHash(habit),
    );
  }

  /// Check if cache is still valid for this habit
  bool isValid(Habit habit) {
    // Cache expires after 30 seconds
    final cacheAge = DateTime.now().difference(cacheTime);
    if (cacheAge.inSeconds > 30) return false;

    // Check if habit data has changed
    final currentHash = _generateHabitHash(habit);
    return currentHash == habitDataHash;
  }

  /// Enhanced hash that includes completion and date range data
  static String _generateHabitHash(Habit habit) {
    return '${habit.completedDates.length}-${habit.missedDates.length}-${habit.dailyValues.length}-${habit.creationDate.millisecondsSinceEpoch}-${habit.startDate?.millisecondsSinceEpoch ?? 0}-${habit.endDate?.millisecondsSinceEpoch ?? 0}';
  }

  /// Convert to StreakStats for compatibility
  StreakStats toStreakStats() {
    return StreakStats(
      current: currentStreak,
      currentFails: currentFailStreak,
      longest: longestStreak,
      completionRate: completionRate,
      streakTier: streakTier,
      isOnFire: isOnFire,
      daysUntilNextMilestone: daysUntilNextMilestone,
    );
  }
}

/// High-performance caching service for habit statistics
class HabitStatsCache {
  static final Map<String, CachedHabitStats> _cache = {};
  static const int _maxCacheSize = 100; // Prevent memory bloat

  /// Get cached stats or calculate if needed
  static CachedHabitStats getStats(Habit habit) {
    final cached = _cache[habit.id];

    // Return cached if valid
    if (cached != null && cached.isValid(habit)) {
      return cached;
    }

    // Recalculate and cache
    final stats = CachedHabitStats.fromHabit(habit);
    _setCache(habit.id, stats);
    return stats;
  }

  /// Get StreakStats (for backward compatibility)
  static StreakStats getStreakStats(Habit habit) {
    return getStats(habit).toStreakStats();
  }

  /// Get achievements (for backward compatibility)
  static List<Achievement> getAchievements(Habit habit) {
    return getStats(habit).achievements;
  }

  /// NEW: Get cached fail streak - PREVENTS 365-DAY LOOPS!
  static int getFailStreak(Habit habit) {
    return getStats(habit).currentFailStreak;
  }

  /// NEW: Get cached completion stats - PREVENTS EXPENSIVE LOOPS!
  static CompletionStats getCompletionStats(Habit habit) {
    return getStats(habit).completionStats;
  }

  /// NEW: Get cached date range text - PREVENTS FORMATTING ON EVERY REBUILD!
  static String getDateRangeText(Habit habit) {
    return getStats(habit).dateRangeText;
  }

  /// Invalidate cache for a specific habit
  static void invalidate(String habitId) {
    _cache.remove(habitId);
  }

  /// Invalidate cache for multiple habits
  static void invalidateMultiple(List<String> habitIds) {
    for (final id in habitIds) {
      _cache.remove(id);
    }
  }

  /// Clear all cached data
  static void clear() {
    _cache.clear();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getDebugInfo() {
    final validEntries = _cache.values
        .where(
          (cached) =>
              DateTime.now().difference(cached.cacheTime).inSeconds <= 30,
        )
        .length;

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': _cache.length - validEntries,
      'maxCacheSize': _maxCacheSize,
      'cacheHitRate':
          validEntries / (_cache.length + 1), // Avoid division by zero
    };
  }

  /// Internal method to set cache with size management
  static void _setCache(String habitId, CachedHabitStats stats) {
    // Clean expired entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      _cleanExpiredEntries();
    }

    // Add new entry
    _cache[habitId] = stats;
  }

  /// Clean expired cache entries
  static void _cleanExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      final age = now.difference(entry.value.cacheTime);
      if (age.inSeconds > 30) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
}
