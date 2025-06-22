# Phase 2: Performance Optimizations Plan

## Target: 120fps Performance for Month View Readiness

### 🎯 Current Performance Bottlenecks
1. **Expensive streak calculations** - Called on every rebuild
2. **Linear habit lookup** - O(n) searches in providers.dart  
3. **7 animation controllers** - WeekProgressView creates too many
4. **No caching** - Recalculates stats repeatedly
5. **Full rebuilds** - Entire habit list rebuilds on single change

### 🔧 Optimization 1: Habit Stats Caching (HIGH IMPACT)
**Problem**: `getCurrentStreak()`, `getLongestStreak()`, `getCompletionStats()` are expensive
**Solution**: Cache results with invalidation on data change

```dart
// New service: lib/services/habit_stats_cache.dart
class HabitStatsCache {
  static final Map<String, CachedHabitStats> _cache = {};
  
  static CachedHabitStats getStats(Habit habit) {
    final cached = _cache[habit.id];
    
    // Check if cache is valid (data unchanged)
    if (cached != null && cached.isValid(habit)) {
      return cached;
    }
    
    // Recalculate and cache
    final stats = CachedHabitStats.fromHabit(habit);
    _cache[habit.id] = stats;
    return stats;
  }
  
  static void invalidate(String habitId) => _cache.remove(habitId);
  static void clear() => _cache.clear();
}
```

### 🔧 Optimization 2: Map-Based Habit Lookup (MEDIUM IMPACT)
**Problem**: `state.firstWhere((h) => h.id == id)` is O(n)
**Solution**: Maintain parallel Map for O(1) access

```dart
// In providers.dart HabitNotifier
class HabitNotifier extends StateNotifier<List<Habit>> {
  final Map<String, Habit> _habitsMap = {};
  
  @override
  set state(List<Habit> newState) {
    super.state = newState;
    _habitsMap.clear();
    for (final habit in newState) {
      _habitsMap[habit.id] = habit;
    }
  }
  
  Habit? getHabitById(String id) => _habitsMap[id]; // O(1) lookup
}
```

### 🔧 Optimization 3: WeekProgressView Animation Pool (MEDIUM IMPACT)
**Problem**: 7 AnimationControllers per habit = memory overhead
**Solution**: Shared animation controller with index-based scaling

```dart
// Replace 7 controllers with 1 shared controller
class _WeekProgressViewState extends State<WeekProgressView> with SingleTickerProviderStateMixin {
  late AnimationController _sharedController;
  int? _activeIndex; // Which day is currently animating
  
  void _onTapDown(int index) {
    _activeIndex = index;
    _sharedController.forward();
  }
}
```

### 🔧 Optimization 4: Granular Widget Rebuilds (HIGH IMPACT)
**Problem**: Entire HabitListItem rebuilds when only status changes
**Solution**: Split into smaller, targeted widgets

```dart
// New widget: HabitStatusIndicator (only rebuilds when status changes)
class HabitStatusIndicator extends ConsumerWidget {
  final String habitId;
  final DateTime date;
  
  // Only rebuilds when this specific habit's status changes
}
```

### 🔧 Optimization 5: Const Constructors & Builders (LOW IMPACT, EASY WINS)
**Areas to optimize**:
- Add `const` to all possible widget constructors
- Use `ListView.builder` instead of `Column` for habit lists
- Implement proper `shouldRebuild` logic in providers

## Implementation Order (Careful & Surgical)

### Step 1: Habit Stats Caching (30 min)
- Create `HabitStatsCache` service
- Integrate with `StatsService.calculateStreakStats()`
- Add cache invalidation on habit updates

### Step 2: Map-Based Lookup (15 min)  
- Add `_habitsMap` to `HabitNotifier`
- Replace `firstWhere` calls with map lookup
- Test thoroughly

### Step 3: Animation Optimization (20 min)
- Refactor WeekProgressView animations
- Single controller with smart index tracking
- Verify smooth 120fps performance

### Step 4: Granular Rebuilds (30 min)
- Split large widgets into smaller ones
- Add targeted provider selectors
- Minimize rebuild scope

### Step 5: Const & Builder Optimizations (15 min)
- Add const constructors where missing
- Convert to builder patterns where beneficial

## Performance Validation

### Before Optimization
- [ ] Measure current rebuild frequency
- [ ] Profile animation smoothness
- [ ] Check memory usage baseline

### After Each Step  
- [ ] Verify 120fps target maintained
- [ ] Confirm no functionality broken
- [ ] Test edge cases thoroughly

### Final Validation
- [ ] Smooth scrolling through 20+ habits
- [ ] Fast habit status updates
- [ ] Memory usage under 50MB
- [ ] Ready for month view implementation

## Risk Mitigation
- **Small, isolated changes** - Test each optimization individually
- **Preserve all functionality** - No feature removal, only performance
- **Rollback plan** - Can revert any change if issues arise
- **Thorough testing** - Manual testing after each step

---
**Success Criteria**: Consistent 120fps, <100ms habit updates, Month view ready 