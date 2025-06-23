import '../models/habit.dart';
import 'habit_stats_cache.dart';
import 'stats_service.dart';

/// Ultra-fast habit lookup service that precomputes and caches all expensive operations
/// This completely eliminates expensive calculations during UI rebuilds
class HabitLookupService {
  static final Map<String, _HabitSnapshot> _snapshots = {};
  static final Map<String, DateTime> _lastUpdated = {};
  static const Duration _cacheValidityDuration = Duration(seconds: 30);

  /// Get a complete habit snapshot with all precomputed values
  /// Returns StreakStats for public API compatibility
  static StreakStats getStreakStats(Habit habit) {
    return _getSnapshot(habit).toStreakStats();
  }

  /// Internal method to get snapshot
  static _HabitSnapshot _getSnapshot(Habit habit) {
    final cached = _snapshots[habit.id];
    final lastUpdate = _lastUpdated[habit.id];

    // Check if cache is still valid
    if (cached != null &&
        lastUpdate != null &&
        DateTime.now().difference(lastUpdate) < _cacheValidityDuration &&
        cached.isValidFor(habit)) {
      return cached;
    }

    // Compute new snapshot
    final snapshot = _HabitSnapshot.fromHabit(habit);
    _snapshots[habit.id] = snapshot;
    _lastUpdated[habit.id] = DateTime.now();

    return snapshot;
  }

  /// Invalidate snapshot for specific habit
  static void invalidate(String habitId) {
    _snapshots.remove(habitId);
    _lastUpdated.remove(habitId);
  }

  /// Clear all snapshots
  static void clear() {
    _snapshots.clear();
    _lastUpdated.clear();
  }

  /// Get debug info - returns Map<String, Object?> for public API
  static Map<String, Object?> getDebugInfo() {
    return {
      'snapshotCount': _snapshots.length,
      'oldestSnapshot': _lastUpdated.values.isNotEmpty
          ? _lastUpdated.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
    };
  }
}

/// Precomputed snapshot of all expensive habit operations
class _HabitSnapshot {
  final String habitId;
  final String habitDataHash;
  final DateTime snapshotTime;

  // All precomputed values
  final int currentStreak;
  final int currentFailStreak;
  final int longestStreak;
  final double completionRate;
  final CompletionStats completionStats;
  final String dateRangeText;
  final List<Achievement> achievements;
  final StreakTier streakTier;
  final bool isOnFire;
  final int daysUntilNextMilestone;

  const _HabitSnapshot({
    required this.habitId,
    required this.habitDataHash,
    required this.snapshotTime,
    required this.currentStreak,
    required this.currentFailStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.completionStats,
    required this.dateRangeText,
    required this.achievements,
    required this.streakTier,
    required this.isOnFire,
    required this.daysUntilNextMilestone,
  });

  /// Create snapshot from habit - computes ALL expensive operations once
  factory _HabitSnapshot.fromHabit(Habit habit) {
    // Get all cached stats in one call
    final cachedStats = HabitStatsCache.getStats(habit);

    return _HabitSnapshot(
      habitId: habit.id,
      habitDataHash: _generateHabitHash(habit),
      snapshotTime: DateTime.now(),
      currentStreak: cachedStats.currentStreak,
      currentFailStreak: cachedStats.currentFailStreak,
      longestStreak: cachedStats.longestStreak,
      completionRate: cachedStats.completionRate,
      completionStats: cachedStats.completionStats,
      dateRangeText: cachedStats.dateRangeText,
      achievements: cachedStats.achievements,
      streakTier: cachedStats.streakTier,
      isOnFire: cachedStats.isOnFire,
      daysUntilNextMilestone: cachedStats.daysUntilNextMilestone,
    );
  }

  /// Check if snapshot is still valid for this habit
  bool isValidFor(Habit habit) {
    return habitDataHash == _generateHabitHash(habit);
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

  /// Generate hash for habit data validation
  static String _generateHabitHash(Habit habit) {
    return '${habit.completedDates.length}-${habit.missedDates.length}-${habit.dailyValues.length}-${habit.name}-${habit.creationDate.millisecondsSinceEpoch}';
  }
}

/// Extension on Habit for easy snapshot access
extension HabitSnapshotExtension on Habit {
  /// Get ultra-fast snapshot with all precomputed values
  _HabitSnapshot get _snapshot => HabitLookupService._getSnapshot(this);

  /// Fast accessors for common operations
  int get fastCurrentStreak => _snapshot.currentStreak;
  int get fastFailStreak => _snapshot.currentFailStreak;
  int get fastLongestStreak => _snapshot.longestStreak;
  CompletionStats get fastCompletionStats => _snapshot.completionStats;
  String get fastDateRangeText => _snapshot.dateRangeText;
  List<Achievement> get fastAchievements => _snapshot.achievements;
  StreakStats get fastStreakStats => _snapshot.toStreakStats();
}
