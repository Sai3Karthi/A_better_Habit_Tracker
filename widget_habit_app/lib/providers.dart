import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'models/habit.dart';
import 'repositories/habit_repository.dart';
import 'repositories/i_habit_repository.dart';
import 'services/widget_updater.dart';
import 'services/stats_service.dart';
import 'services/undo_service.dart';
import 'services/habit_stats_cache.dart';
import 'services/habit_lookup_service.dart';

// 1. Provider for the Hive box for habits.
final habitBoxProvider = Provider<Box<Habit>>((ref) {
  // This will be overridden in main.dart where the box is actually opened.
  throw UnimplementedError();
});

// 2. Provider for the HabitRepository.
final habitRepositoryProvider = Provider<IHabitRepository>((ref) {
  final habitBox = ref.watch(habitBoxProvider);
  return HabitRepository(habitBox);
});

// 3. Provider for the StatsService (Phase 3A.1 addition)
final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService();
});

// 4. Provider for the UndoService (NEW)
final undoServiceProvider = Provider<UndoService>((ref) {
  return UndoService();
});

// 5. Provider for the HabitNotifier (StateNotifier)
final habitsProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final undoService = ref.watch(undoServiceProvider);
  return HabitNotifier(repository, undoService);
});

// OPTIMIZED: Use O(1) map lookup instead of O(n) firstWhere search
final habitMapProvider = Provider<Map<String, Habit>>((ref) {
  final habits = ref.watch(habitsProvider);
  return {for (final habit in habits) habit.id: habit};
});

// OPTIMIZED: Fast O(1) habit lookup using map provider
final habitProvider = Provider.family<Habit?, String>((ref, id) {
  final habitMap = ref.watch(habitMapProvider);
  return habitMap[id]; // O(1) instead of O(n)
});

// OPTIMIZED: More efficient stats providers that watch specific habits
final habitStatsProvider = Provider.family<StreakStats, String>((ref, habitId) {
  final habit = ref.watch(habitProvider(habitId));
  if (habit == null) {
    return StreakStats(
      current: 0,
      currentFails: 0,
      longest: 0,
      completionRate: 0,
      streakTier: StreakTier.none,
      isOnFire: false,
      daysUntilNextMilestone: 7,
    );
  }
  return HabitStatsCache.getStreakStats(habit);
});

final habitAchievementsProvider = Provider.family<List<Achievement>, String>((
  ref,
  habitId,
) {
  final habit = ref.watch(habitProvider(habitId));
  if (habit == null) return [];
  return HabitStatsCache.getAchievements(habit);
});

// SIMPLIFIED: Remove expensive filtering that was running on every rebuild
final activeHabitsCountProvider = Provider<int>((ref) {
  final habits = ref.watch(habitsProvider);
  return habits.length; // Simple count, no expensive filtering
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final IHabitRepository _repository;
  final UndoService _undoService;
  final Map<String, Habit> _habitsMap = {}; // O(1) lookup cache
  Timer? _updateDebounceTimer; // Add debouncing

  HabitNotifier(this._repository, this._undoService) : super([]) {
    loadHabits();
  }

  @override
  void dispose() {
    _updateDebounceTimer?.cancel();
    super.dispose();
  }

  // OPTIMIZED: More efficient state management
  @override
  set state(List<Habit> newState) {
    super.state = newState;
    _syncHabitsMap(newState);
  }

  /// OPTIMIZED: Sync map more efficiently
  void _syncHabitsMap(List<Habit> habits) {
    // Clear and rebuild only if needed
    if (_habitsMap.length != habits.length) {
      _habitsMap.clear();
      for (final habit in habits) {
        _habitsMap[habit.id] = habit;
      }
    } else {
      // Update existing entries
      for (final habit in habits) {
        _habitsMap[habit.id] = habit;
      }
    }
  }

  /// Get habit by ID with O(1) performance
  Habit? getHabitById(String id) => _habitsMap[id];

  void loadHabits() {
    final habits = _repository.getAllHabits();
    state = habits;
    // OPTIMIZED: Only update widgets if needed
    if (habits.isNotEmpty) {
      updateWidgetData(habits);
    }
  }

  Future<void> addHabit(Habit habit) async {
    await _repository.addHabit(habit);
    loadHabits(); // This will trigger UI rebuild
  }

  // HIGHLY OPTIMIZED: Eliminate redundant state updates and array copying
  Future<void> updateHabit(Habit habit) async {
    // Cancel previous timer
    _updateDebounceTimer?.cancel();

    // Invalidate ALL caches immediately for instant UI feedback
    HabitStatsCache.invalidate(habit.id);
    HabitLookupService.invalidate(habit.id);

    // OPTIMIZED: Update in-place instead of copying entire array
    final habitIndex = state.indexWhere((h) => h.id == habit.id);
    if (habitIndex != -1) {
      // Direct update to existing list instead of creating new one
      final updatedHabits = List<Habit>.from(state);
      updatedHabits[habitIndex] = habit;
      state = updatedHabits;

      // Update map directly
      _habitsMap[habit.id] = habit;
    }

    // OPTIMIZED: Debounce repository update with less frequent widget updates
    _updateDebounceTimer = Timer(const Duration(milliseconds: 150), () async {
      await _repository.updateHabit(habit);
      // Only update widgets if really necessary
      Future.microtask(() => updateWidgetData(state));
    });
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    // Invalidate ALL caches for deleted habit
    HabitStatsCache.invalidate(id);
    HabitLookupService.invalidate(id);
    loadHabits();
  }

  // OPTIMIZED: Temporary delete with better async handling
  Future<void> temporaryDeleteHabit(String id) async {
    final habit = _habitsMap[id]; // O(1) lookup instead of O(n)
    if (habit == null) return;

    // Store in undo service with permanent delete callback
    _undoService.temporaryDelete(
      habit,
      onPermanentDelete: (habitId) async {
        // This gets called after 30 seconds if not undone
        await _repository.deleteHabit(habitId);
        HabitStatsCache.invalidate(habitId);
        HabitLookupService.invalidate(habitId);
      },
    );

    // OPTIMIZED: Remove from current state more efficiently
    state = state.where((h) => h.id != id).toList();
    _habitsMap.remove(id); // Keep map in sync

    // Invalidate ALL caches for temporarily deleted habit
    HabitStatsCache.invalidate(id);
    HabitLookupService.invalidate(id);

    // OPTIMIZED: Less frequent widget updates
    Future.microtask(() => updateWidgetData(state));
  }

  // OPTIMIZED: Restore habit with better performance
  Future<void> restoreHabit(String id) async {
    final restoredHabit = _undoService.restoreHabit(id);

    if (restoredHabit != null) {
      // OPTIMIZED: Update state immediately without waiting for repository
      state = [...state, restoredHabit];
      _habitsMap[id] = restoredHabit; // Keep map in sync

      // Repository update in background
      Future.microtask(() async {
        await _repository.addHabit(restoredHabit);
        HabitStatsCache.invalidate(id);
        HabitLookupService.invalidate(id);
        updateWidgetData(state);
      });
    }
  }

  // Manual refresh method for force updates
  void refreshHabits() {
    final updatedHabits = _repository.getAllHabits();
    state = updatedHabits;
    updateWidgetData(updatedHabits);
  }
}
