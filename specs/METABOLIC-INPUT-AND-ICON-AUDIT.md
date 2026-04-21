# Monch Metabolic Input And Icon Audit

**Date:** April 19, 2026  
**Status:** Proposed  
**Scope:** Product boundary, input simplification, intelligence impacts, icon consistency

## Goal

Shift Monch away from being a first-party food logger and toward being a metabolic intelligence layer:

- external apps and HealthKit own detailed nutrition logging
- Monch owns timing, context, subjective state, biometrics, and interpretation
- Monch uses its own visual language consistently where custom icons already exist

## Recommendation

Adopt a phased migration with three product defaults:

1. Meal timing owns "late meal" semantics.
2. Caffeine and alcohol become event-based inputs, not quantified inputs.
3. Supplements are de-scoped from the core product.

For UI, use:

- custom Monch icons for domain concepts and insight types where assets already exist
- SF Symbols for utility and interface chrome
- mascot art for emotional state
- emoji only as a temporary fallback where no custom asset exists yet

## Why This Direction

### User impact

This reduces friction in the highest-friction part of the product. Logging "I had caffeine" or "I ate dinner" is much easier than assembling foods from unreliable libraries.

### Maintainability

The current food search stack is fairly self-contained, which makes it removable. Emoji usage is more scattered and should be normalized through shared icon APIs instead of one-off replacements.

### Product differentiation

Monch's differentiated value is correlation and interpretation, not food search, barcode lookup, or nutrition database coverage.

### Risk

The main risk is losing precision for insights that currently depend on grams or milligrams. The engine should be redesigned to degrade gracefully from exact nutrition to timing/event signals.

## Product Boundary

### Monch should own

- meal occurrence and timing
- manual meal naming when useful
- caffeine event
- alcohol event
- subjective vibe check
- passive workout and sleep context
- interpreted insights, patterns, streaks, and dashboard UX

### Monch should stop owning as a core workflow

- food search
- Open Food Facts lookups
- cart-based meal construction
- serving-size scaling as a primary interaction
- supplement stack logging
- quantified caffeine entry in the primary UX

## Current Code Audit

## Food input flows

### High-confidence removal candidates

These files are tightly coupled to the deprecated "full meal logger" direction:

- [monch/Services/OpenFoodFactsClient.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/OpenFoodFactsClient.swift)
- [monch/Views/FoodLogger/FoodSearchView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/FoodLogger/FoodSearchView.swift)
- [monch/Views/FoodLogger/FoodSearchViewModel.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/FoodLogger/FoodSearchViewModel.swift)
- [monch/Models/CartItem.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/CartItem.swift)
- [monchTests/OpenFoodFactsClientTests.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monchTests/OpenFoodFactsClientTests.swift)

### Keep but simplify

- [monch/Models/MealLog.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/MealLog.swift)
- [monch/Views/Cards/FoodCardView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Cards/FoodCardView.swift)
- [monch/Views/Timeline/TimelineView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Timeline/TimelineView.swift)
- [monch/Views/Dashboard/TodayView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Dashboard/TodayView.swift)

`MealLog` should remain for now, but its role should narrow to "meal event plus optional enrichment" instead of "structured food record."

### De-scope from core v1

- [monch/Views/Logging/SupplementStackView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Logging/SupplementStackView.swift)

This can be removed or hidden behind an internal flag later if needed, but it should stop influencing core product direction.

## Event model recommendations

### Late meal

Recommendation: derive from timestamp only.

Do not keep a manual "late meal" primary input. The current engine already uses timing windows for late-meal logic in places like:

- [monch/Services/InsightEngine.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/InsightEngine.swift)

If backfilling becomes important later, add an internal override tag, not a front-door user control.

### Caffeine

Recommendation: event-based input first.

Replace quantified presets with a simpler event flow:

- `Coffee`
- `Tea`
- `Energy Drink`
- `Caffeine`

Store occurrence and timestamp. Avoid cups or milligrams in primary UX.

Current quantified dependencies:

- [monch/Views/Logging/CaffeineQuickAddView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Logging/CaffeineQuickAddView.swift)
- [monch/Services/InsightEngine.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/InsightEngine.swift) `detectCaffeineJitter`
- [monch/Services/InsightEngine.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/InsightEngine.swift) `detectDeepSleepRobber`

### Alcohol

Recommendation: explicit event input, unquantified.

The app currently infers alcohol via HRV suppression:

- [monch/Services/InsightEngine.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/InsightEngine.swift) `detectAlcoholImpact`

This should be augmented with an explicit `Alcohol event` so the engine has a first-party signal instead of relying on inference alone.

### Supplements

Recommendation: remove from core scope.

The current implementation mostly acts as a convenience logger with weak connection to the strongest product loop. If brought back later, it should be justified by clear user value or detector value.

## Intelligence Impacts

## Logic that currently depends on exact nutrition

These areas likely need redesign or tiered certainty:

- `detectSugarSpike(for:)` uses `meal.carbs`
- `detectCaffeineJitter(for:)` sums `meal.caffeine`
- `detectDeepSleepRobber(in:)` checks `meal.caffeine`
- `detectRecoveryGap(for:in:)` compares calories burned with calories consumed
- `detectMealImpactScore(for:)` assumes a meal object with meaningful nutritional context

## Suggested detection tiers

### Tier A: full nutrition + biometrics

Use when HealthKit or a richer import provides usable nutrition.

### Tier B: event/timing + biometrics

Use for:

- late eating
- caffeine recency
- alcohol recency
- workout refuel timing
- meal-adjacent HR or HRV changes

### Tier C: biometrics + subjective input

Use when only sleep, HR, HRV, workouts, and vibe check are present.

## Migration strategy for the engine

### Keep

- meal timing logic
- workout context logic
- sleep-derived insights
- mood refresh behavior

### Rewrite

- caffeine logic from mg thresholds to recency/event heuristics
- alcohol logic to combine explicit events with biomarker confirmation
- calorie-dependent recovery gap logic, or downgrade it behind a higher-confidence requirement

### De-emphasize

- macro-centric dashboard framing
- exact calorie summaries as a primary indicator of app usefulness

## Emoji And Icon Audit

## Existing custom assets already available

The repo already has custom icons for:

- `meal_kawaii`
- `coffee_kawaii`
- `tea_kawaii`
- `alcohol_kawaii`
- `supplement_kawaii`
- `sleep_kawaii`
- `workout_kawaii`
- `insight_spike_kawaii`
- `insight_recovery_kawaii`
- `brain_fog_kawaii`
- `hrv_high_kawaii`
- `hrv_low_kawaii`
- `fasting_kawaii`
- `mineral_kawaii`

Assets live under:

- [/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Assets.xcassets/River/Icons](</Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Assets.xcassets/River/Icons>)

## Recommended icon system

### Use custom assets

For:

- meals
- caffeine
- alcohol
- supplements if kept at all
- sleep
- workouts
- insight types and dashboard insight summaries

### Use SF Symbols

For:

- navigation
- disclosure chevrons
- settings/actions
- utility controls

### Keep mascot art

For:

- emotional state
- onboarding mood/state visuals

### Avoid emoji in core UI

Emoji are currently being used as a substitute for a design system. That should stop anywhere a custom asset already exists.

## Emoji hotspots by file

### Highest-priority cleanup

- [monch/Views/Cards/InsightCardView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Cards/InsightCardView.swift)
  - `InsightType.icon`
  - severity tag copy
  - linked meal row
- [monch/Views/Dashboard/TodayView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Dashboard/TodayView.swift)
  - quick stat pills
  - insight row card
- [monch/Views/Dashboard/WeekView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Dashboard/WeekView.swift)
  - weekly summary pills
- [monch/Services/DashboardDataService.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/DashboardDataService.swift)
  - pattern icons
- [monch/Views/Timeline/TimelineView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Timeline/TimelineView.swift)
  - tag-to-emoji mapping for auto-tags
- [monch/Models/MealLog.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/MealLog.swift)
  - `MealType.icon`

### Medium-priority cleanup

- [monch/Views/Logging/CaffeineQuickAddView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Logging/CaffeineQuickAddView.swift)
- [monch/Views/Logging/SupplementStackView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Logging/SupplementStackView.swift)
- [monch/Views/Logging/VibeCheckView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Logging/VibeCheckView.swift)
- [monch/Models/VibeCheck.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/VibeCheck.swift)
- [monch/Models/DashboardModels.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/DashboardModels.swift)
- [monch/Models/WorkoutLog.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/WorkoutLog.swift)
- [monch/Managers/NotificationManager.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Managers/NotificationManager.swift)

### Lower-priority or design-choice cleanup

- [monch/Views/Onboarding/OnboardingView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Onboarding/OnboardingView.swift)
  - food chips for example content only
- [monch/Views/Logging/SleepLogView.swift](/Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Logging/SleepLogView.swift)
  - subjective sleep-quality visuals

## Suggested icon implementation pattern

Do not keep raw emoji strings as the main icon API.

Instead, introduce a small icon abstraction with one of:

- `enum MonchIconAsset: String`
- `enum MonchIcon`
- per-domain computed properties returning asset names or SF Symbol names

This avoids scattering `Image("...")`, emoji literals, and symbol names across models and views.

## Recommended implementation order

1. Remove or hide food search entry points from primary UX.
2. Replace quantified caffeine flow with event-based quick logging.
3. Add alcohol event logging.
4. De-scope supplements from primary navigation.
5. Refactor icon APIs and replace emoji where custom assets already exist.
6. Rewrite insight logic to use timing/event tiers before deleting old nutrition-heavy code.
7. Remove Open Food Facts stack and related tests after replacement flows are stable.

## Validation checklist

- Timeline still feels useful with no nutrition database usage.
- Dashboard still feels populated with timing, workout, sleep, and insight data.
- Caffeine and alcohol insights still behave credibly without dose entry.
- No core surfaces mix emoji and custom Monch icons for the same concept.
- Onboarding and empty states reflect the new product boundary.

## Open questions

- Should `MealLog` gain a lightweight `source` field now, or only when HealthKit nutrition import is built?
- Do we want one generic "meal event" flow, or multiple quick event flows like `Breakfast`, `Dinner`, `Snack`?
- Should vibe check keep expressive faces, or should it move to a calmer Monch-native scale later?
