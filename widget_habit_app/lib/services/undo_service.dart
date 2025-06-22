import 'dart:async';
import '../models/habit.dart';

/// Internal class to track deleted habits with timestamps
class _DeletedHabit {
  final Habit habit;
  final DateTime deletedAt;
  Timer? cleanupTimer;

  _DeletedHabit({
    required this.habit,
    required this.deletedAt,
    this.cleanupTimer,
  });
}

/// Service for managing temporary deletion and undo functionality
class UndoService {
  static final Map<String, _DeletedHabit> _deletedHabits = {};
  static const Duration _undoTimeout = Duration(seconds: 5);

  /// Temporarily delete a habit (can be undone)
  void temporaryDelete(Habit habit, {Function(String)? onPermanentDelete}) {
    // Cancel any existing timer for this habit
    _deletedHabits[habit.id]?.cleanupTimer?.cancel();

    // Create cleanup timer
    final timer = Timer(_undoTimeout, () {
      _permanentlyDelete(habit.id);
      onPermanentDelete?.call(habit.id);
    });

    // Store the deleted habit
    _deletedHabits[habit.id] = _DeletedHabit(
      habit: habit,
      deletedAt: DateTime.now(),
      cleanupTimer: timer,
    );

    print(
      'DEBUG: Habit ${habit.name} temporarily deleted, ${_undoTimeout.inSeconds}s to undo',
    );
  }

  /// Restore a temporarily deleted habit
  Habit? restoreHabit(String habitId) {
    final deletedHabit = _deletedHabits[habitId];
    if (deletedHabit == null) {
      print(
        'DEBUG: Cannot restore habit $habitId - not found in temporary storage',
      );
      return null;
    }

    // Cancel the cleanup timer
    deletedHabit.cleanupTimer?.cancel();

    // Remove from temporary storage
    _deletedHabits.remove(habitId);

    print(
      'DEBUG: Habit ${deletedHabit.habit.name} restored from temporary deletion',
    );
    return deletedHabit.habit;
  }

  /// Check if a habit can be restored
  bool canRestore(String habitId) {
    return _deletedHabits.containsKey(habitId);
  }

  /// Get the deleted habit (for testing/debugging)
  Habit? getDeletedHabit(String habitId) {
    return _deletedHabits[habitId]?.habit;
  }

  /// Get remaining time for undo (in seconds)
  int getRemainingUndoTime(String habitId) {
    final deletedHabit = _deletedHabits[habitId];
    if (deletedHabit == null) return 0;

    final elapsed = DateTime.now().difference(deletedHabit.deletedAt);
    final remaining = _undoTimeout - elapsed;
    return remaining.inSeconds.clamp(0, _undoTimeout.inSeconds);
  }

  /// Permanently delete a habit (private)
  void _permanentlyDelete(String habitId) {
    final deletedHabit = _deletedHabits.remove(habitId);
    if (deletedHabit != null) {
      print(
        'DEBUG: Habit ${deletedHabit.habit.name} permanently deleted after timeout',
      );
    }
  }

  /// Force permanent deletion of a specific habit
  void forceDelete(String habitId) {
    final deletedHabit = _deletedHabits[habitId];
    if (deletedHabit != null) {
      deletedHabit.cleanupTimer?.cancel();
      _deletedHabits.remove(habitId);
      print('DEBUG: Habit ${deletedHabit.habit.name} force deleted');
    }
  }

  /// Cleanup all expired habits and timers
  void cleanup() {
    final now = DateTime.now();
    final expired = <String>[];

    for (final entry in _deletedHabits.entries) {
      final elapsed = now.difference(entry.value.deletedAt);
      if (elapsed >= _undoTimeout) {
        entry.value.cleanupTimer?.cancel();
        expired.add(entry.key);
      }
    }

    for (final id in expired) {
      _deletedHabits.remove(id);
    }

    if (expired.isNotEmpty) {
      print('DEBUG: Cleaned up ${expired.length} expired deleted habits');
    }
  }

  /// Cancel all pending deletions (for testing)
  void cancelAll() {
    for (final deletedHabit in _deletedHabits.values) {
      deletedHabit.cleanupTimer?.cancel();
    }
    _deletedHabits.clear();
    print('DEBUG: All pending deletions cancelled');
  }

  /// Get count of temporarily deleted habits
  int get pendingCount => _deletedHabits.length;

  /// Get debug info
  Map<String, String> getDebugInfo() {
    return _deletedHabits.map(
      (id, deleted) => MapEntry(
        id,
        '${deleted.habit.name} (${getRemainingUndoTime(id)}s remaining)',
      ),
    );
  }
}
