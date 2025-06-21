import '../models/habit.dart';

abstract class IHabitRepository {
  Future<void> addHabit(Habit habit);
  Future<Habit?> getHabit(String id);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String id);
  List<Habit> getAllHabits();
}
