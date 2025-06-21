import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'models/habit.dart';
import 'repositories/habit_repository.dart';
import 'repositories/i_habit_repository.dart';
import 'services/widget_updater.dart';

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

// 3. Provider for the HabitNotifier (StateNotifier)
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
    loadHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.updateHabit(habit);
    loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    loadHabits();
  }
}
