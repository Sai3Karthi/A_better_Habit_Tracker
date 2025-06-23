# Theme System Fix Implementation Plan

## Problem
The streak lightning color was set to black in the theme file but still showing as blue in the app.

## Root Cause Analysis
1. The streak lightning color was defined in `HabitTheme.darkTheme()` correctly as black
2. However, the `_getStreakColor` method in `habit_list_item.dart` was using hardcoded colors instead of the theme

## Solution Implemented
1. Updated `_getStreakColor` method in `habit_list_item.dart` to use theme colors:
   - Now using `habitTheme.streakLightningColor` for StreakTier.none
   - Using achievement colors from theme for other streak tiers
   - Fixed context passing to ensure theme access works properly

## Testing
- App runs successfully with the theme changes
- The streak lightning color should now correctly show as black as defined in the theme

## Next Steps
- Verify that the streak lightning color is now black in the UI
- Check if any other hardcoded colors need to be replaced with theme values
- Consider implementing a more comprehensive theme system if needed in the future 