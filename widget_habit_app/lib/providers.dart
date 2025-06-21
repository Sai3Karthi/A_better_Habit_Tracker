import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'models/habit.dart';
import 'repositories/habit_repository.dart';
import 'repositories/i_habit_repository.dart';
import 'services/widget_updater.dart';
import 'services/stats_service.dart';

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

// 4. Provider for the HabitNotifier (StateNotifier)
final habitsProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return HabitNotifier(repository);
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final IHabitRepository _repository;

  HabitNotifier(this._repository) : super([]) {
    loadHabits();
  }

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
    // Force immediate state update for real-time UI changes
    final updatedHabits = _repository.getAllHabits();
    state = updatedHabits;
    updateWidgetData(updatedHabits);
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    loadHabits();
  }

  // Manual refresh method for force updates
  void refreshHabits() {
    final updatedHabits = _repository.getAllHabits();
    state = updatedHabits;
    updateWidgetData(updatedHabits);
  }
}
