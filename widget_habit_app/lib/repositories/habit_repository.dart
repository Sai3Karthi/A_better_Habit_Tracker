import 'package:hive/hive.dart';
import '../models/habit.dart';
import 'i_habit_repository.dart';

class HabitRepository implements IHabitRepository {
  final Box<Habit> _habitBox;

  HabitRepository(this._habitBox);

  @override
  Future<void> addHabit(Habit habit) async {
    await _habitBox.put(habit.id, habit);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _habitBox.delete(id);
  }

  @override
  List<Habit> getAllHabits() {
    return _habitBox.values.toList();
  }

  @override
  Future<Habit?> getHabit(String id) async {
    return _habitBox.get(id);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _habitBox.put(habit.id, habit);
  }
}
