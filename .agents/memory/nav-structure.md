---
name: Nav structure
description: Current navigation layout and what was removed — needed for future habits re-integration work.
---

# Navigation Structure

## Current (2 tabs)
- Tab 0: Quests (`TasksScreen`) — always shown
- Tab 1: Shop (`ShopScreen`)
- FAB: always visible (adds a new task regardless of active tab)

## Removed
- **Habits tab** — removed from nav; `HabitsScreen`, `habit_card.dart`, `add_habit_sheet.dart`, `habits_provider.dart` still exist in the codebase for future use. Plan is to integrate habits into the Tasks tab later.
- **Stats tab** — `stats_screen.dart` deleted entirely. Wallet ledger data still lives in `wallet_provider.dart` if a stats view is needed later.

## Why
User decision: keep nav minimal. Habits will return as part of a combined Tasks+Habits tab in a future update.

## How to apply
When re-integrating habits: add a tab back to `_GlassBottomBar._items` in `app_shell.dart` and add the screen to the `screens` list. Do NOT add a new habits screen from scratch — `lib/screens/habits_screen.dart` does not exist anymore; build the combined view in `tasks_screen.dart` instead.
