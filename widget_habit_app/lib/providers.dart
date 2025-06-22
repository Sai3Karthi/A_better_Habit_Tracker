import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'models/habit.dart';
import 'repositories/habit_repository.dart';
import 'repositories/i_habit_repository.dart';
import 'services/widget_updater.dart';
import 'services/stats_service.dart';
import 'services/undo_service.dart';
import 'services/habit_stats_cache.dart';

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

class HabitNotifier extends StateNotifier<List<Habit>> {
  final IHabitRepository _repository;
  final UndoService _undoService;
  final Map<String, Habit> _habitsMap = {}; // O(1) lookup cache

  HabitNotifier(this._repository, this._undoService) : super([]) {
    loadHabits();
  }

  // Maintain map sync with state changes
  @override
  set state(List<Habit> newState) {
    super.state = newState;
    _updateHabitsMap(newState);
  }

  /// Update the internal map for O(1) lookups
  void _updateHabitsMap(List<Habit> habits) {
    _habitsMap.clear();
    for (final habit in habits) {
      _habitsMap[habit.id] = habit;
    }
  }

  /// Get habit by ID with O(1) performance
  Habit? getHabitById(String id) => _habitsMap[id];

  void loadHabits() {
    state = _repository.getAllHabits();
    updateWidgetData(state);
  }

  Future<void> addHabit(Habit habit) async {
    await _repository.addHabit(habit);
    loadHabits(); // This will trigger UI rebuild
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.updateHabit(habit);
    // Invalidate cache for updated habit
    HabitStatsCache.invalidate(habit.id);
    // Force immediate state update for real-time UI changes
    final updatedHabits = _repository.getAllHabits();
    state = updatedHabits;
    updateWidgetData(updatedHabits);
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    // Invalidate cache for deleted habit
    HabitStatsCache.invalidate(id);
    loadHabits();
  }

  // NEW: Temporary delete method
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
      },
    );

    // Remove from current state immediately (UI feedback)
    state = state.where((h) => h.id != id).toList();
    // Invalidate cache for temporarily deleted habit
    HabitStatsCache.invalidate(id);
    updateWidgetData(state);
  }

  // NEW: Restore habit method
  Future<void> restoreHabit(String id) async {
    final restoredHabit = _undoService.restoreHabit(id);

    if (restoredHabit != null) {
      // Add back to repository
      await _repository.addHabit(restoredHabit);
      // Invalidate cache for restored habit (will be recalculated)
      HabitStatsCache.invalidate(id);

      // Force immediate state update for real-time UI changes
      final updatedHabits = _repository.getAllHabits();
      state = updatedHabits;
      updateWidgetData(updatedHabits);
    }
  }

  // Manual refresh method for force updates
  void refreshHabits() {
    final updatedHabits = _repository.getAllHabits();
    state = updatedHabits;
    updateWidgetData(updatedHabits);
  }
}
