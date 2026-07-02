---
name: Screech app overview
description: Key architecture decisions, design patterns, and future hooks in the Screech Flutter app — enough context to make targeted changes without re-reading everything.
---

# Screech App Overview

## Stack
- Flutter / Dart (SDK >=3.3.0 <4.0.0)
- Riverpod 2.x for state management
- Isar 3.x for local persistence (fast, no native build pain — intentional choice)
- flutter_local_notifications + timezone for exact alarm scheduling
- flutter_animate + confetti for interactions; BackdropFilter for glass UI

## Design Language — "Liquid Glass"
The signature UI element is `lib/widgets/liquid_glass.dart`: BackdropFilter blur + translucent tint + `_ShimmerSweep` animation. Heavy on GPU — the app exposes "Glass Intensity" sliders in Personalization so users can tone it down.

**Why:** The shimmer and blur are intentional brand differentiators, not decorative. Treat them as first-class — don't remove or stub them.

## Coin Economy
- Tasks: 5–28 coins by priority (low=5, medium=10, high=20, urgent=28)
- Habits: base coins + +1 per 5-day streak milestone, capped at 10 bonus
- Streak freeze: 2 per habit by default; consumed automatically on missed days
- Wallet ledger: last 50 entries only (`LedgerHistoryProvider`)

## Future Hooks Already Scaffolded
- `task.dart`: `createdByAi` (bool) + `pesterCount` (int) — hooks for AI task generation and escalating reminders. Not wired up yet.
- `notification_service.dart`: exact alarm scheduling is in place; `pesterCount` would drive re-schedule logic.

**How to apply:** When adding AI task generation or smart reminders, build on these existing fields rather than adding new ones.

## Key Patterns
- All Isar writes go through provider methods (never direct in UI)
- Settings persisted via SharedPreferences (not Isar) — lightweight prefs only
- Default rewards seeded in `rewards_provider.dart` on first run; check for empty collection before seeding

## Android Config
- Package: `com.subhu.questify`
- minSdkVersion: 21, targetSdkVersion: 34, multiDex enabled
