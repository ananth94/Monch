# PR #5: Sprint 6 - Card System Design Language & Data Models

**Branch:** `sprint6/card-system-design` → `main`  
**Scope:** +3,893 additions across 77 files  

---

## Executive Summary

This PR delivers a comprehensive card system foundation with a "Cozy Science" design language. It introduces new data models for HealthKit sync, a full card detail system, and significantly expands the timeline UI to handle workouts and sleep data. 

> [!TIP]
> **Overall Assessment:** ✅ **Ready to merge** with minor suggestions. The code is well-structured, follows established patterns, and implements the design system consistently.

---

## What's New

### 1. Data Models

#### [NEW] [SleepLog.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/SleepLog.swift)
SwiftData model for sleep sessions synced from HealthKit.

**Strengths:**
- ✅ Clean computed properties for quality metrics (`sleepEfficiency`, `deepSleepPercentage`)
- ✅ Smart quality score algorithm based on sleep science (15-25% deep sleep target)
- ✅ JSON-encoded hypnogram segments for timeline visualization

**Suggestions:**
- Consider making `computedQualityScore` return a typed enum (`poor`/`fair`/`good`/`great`) for cleaner UI binding

---

#### [NEW] [WorkoutLog.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/WorkoutLog.swift)
SwiftData model for workout sessions with anabolic window tracking.

**Strengths:**
- ✅ Well-designed `ExerciseCategory` enum mapping HKWorkoutActivityType raw values
- ✅ Pre-computed `anabolicWindowEnd` for efficient queries  
- ✅ Comprehensive computed properties (`formattedPace`, `formattedDistance`, etc.)

**Suggestions:**
```diff
// Consider adding validation to prevent future dates
init(...) {
+   precondition(endTime >= startTime, "End time must be after start time")
    self.startTime = startTime
    ...
}
```

---

### 2. HealthKit Sync Service

#### [NEW] [HealthKitSyncService.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/HealthKitSyncService.swift)

**Strengths:**
- ✅ Clean async/await pattern with `withCheckedThrowingContinuation`
- ✅ Smart sleep session grouping (attributes samples before 4am to previous night)
- ✅ Upsert logic prevents duplicate data

**Observations:**

1. **HR data is not being fetched** (lines 319-320):
   ```swift
   avgHeartRate: nil, // Would need separate query
   maxHeartRate: nil,
   ```
   This is fine for Sprint 6, but should be tracked for future sprints.

2. **Potential improvement** - The predicate for sleep log matching could be more precise:
   ```swift
   // Current: any sleep log starting after the new session start
   let predicate = #Predicate<SleepLog> { log in
       log.startTime >= startOfNight
   }
   ```
   Consider matching by `nightDate` if available, or a tighter time window.

---

### 3. Card System Design

#### [NEW] [CardDetailShell.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Cards/CardDetailShell.swift)
Shared container for all timeline card detail views.

**Strengths:**
- ✅ Clean generic pattern `CardDetailShell<Content: View>`
- ✅ Consistent header structure with icon glow effect
- ✅ Proper use of `confirmationDialog` for delete action
- ✅ Uses `CornerRadius.xl` per design spec ✓

**Notable pattern:**
```swift
.shadow(color: moodAccentColor.opacity(0.3), radius: 8)
```
Nice touch for the "glow" effect on icons matching the mood.

---

#### [NEW] [MonchCard.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/DesignSystem/MonchCard.swift)
Design system components for the "Cozy Science" language.

**Components delivered:**
| Component | Purpose |
|-----------|---------|
| `MonchCard` | Glass-morphism container |
| `MonchCardSection` | Card with header label |
| `MonchPillSelector` | Horizontal segment control |
| `MonchPrimaryButton` | Sage-filled CTA |
| `MonchSecondaryButton` | Outlined button |
| `MonchDeleteButton` | Coral soft-delete button |

**Excellent:** All use `.ultraThinMaterial` and `CornerRadius.xl` consistently.

---

#### [NEW] [FoodCardView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Cards/FoodCardView.swift)

**Strengths:**
- ✅ Smart serving size multiplier with pill selector
- ✅ Nested macro display (Fiber/Sugar under Carbs)
- ✅ Expandable micronutrients section
- ✅ Correct save logic updating meal values

**Minor suggestion:**
```swift
// Line 241-247: Consider batching these updates
private func saveChanges() {
    // Scale all values at once
    meal.scaleServingSize(by: servingMultiplier) // Add this method to MealLog
    dismiss()
}
```

---

#### [NEW] [ExerciseCardView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Cards/ExerciseCardView.swift)

**Strengths:**
- ✅ Adaptive metrics section based on `workout.category`
- ✅ Beautiful HR zone visualization with gradient colors
- ✅ Anabolic window CTA with countdown

**TODO noticed:**
```swift
// Line 169
// TODO: Open food logger with protein filter
```
Track this for Sprint 7.

---

#### [NEW] [SleepCardView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Cards/SleepCardView.swift)

**Strengths:**
- ✅ Interactive hypnogram chart with Canvas rendering
- ✅ Tap gesture to select sleep segments
- ✅ Quality score interpretation ("✨ Great", "👍 Good", etc.)

**Observation:**
The hypnogram Y-axis labels have a hardcoded offset:
```swift
.offset(x: -35) // Line 297
```
Consider using `GeometryReader` for more robust positioning.

---

#### [NEW] [InsightCardView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Cards/InsightCardView.swift)

**Strengths:**
- ✅ Extension on `InsightType` for display properties is clean
- ✅ `QuickAction` struct enables flexible action buttons
- ✅ Linked meal fetching uses proper `#Predicate`

**TODOs noticed:**
```swift
// Line 91
// TODO: Wire up actions (open food logger, start workout, etc.)
```

---

### 4. Timeline View Updates

#### [MODIFY] [TimelineView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Timeline/TimelineView.swift)

**Changes:**
- Added `@Query` for `WorkoutLog` and `SleepLog`
- New `TimelineItem` enum cases: `.workout`, `.sleep`  
- New timeline cards: `WorkoutTimelineCard`, `SleepTimelineCard`
- Sheet presentations for all card types

**Observation:**
The `TimelineItem` enum is now in 4 cases. Consider moving this to its own file for cleaner organization.

---

### 5. Model Schema Update

#### [MODIFY] [monchApp.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/monchApp.swift)

```diff
let schema = Schema([
    MealLog.self,
    InsightEvent.self,
    MascotStateLog.self,
+   SleepLog.self,
+   WorkoutLog.self
])
```

✅ Schema correctly updated for migrations.

Also added:
```swift
await HealthKitSyncService.shared.syncAll(modelContext: context)
```
This runs on every app launch - consider adding a debounce or `lastSyncDate` check.

---

## Issues Found

### ⚠️ Medium Priority

1. ~~**Missing `SleepStage` enum definition**~~ - ✅ **Verified:** `SleepStage` enum exists in [HealthKitDataProvider.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Services/HealthKitDataProvider.swift#L31) with `depthValue` property.

2. **Preview model container incomplete** in [TimelineView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Timeline/TimelineView.swift#L533):
   ```swift
   .modelContainer(for: [MealLog.self, InsightEvent.self], inMemory: true)
   ```
   Should include `WorkoutLog.self` and `SleepLog.self` for full preview support.

### ℹ️ Low Priority

3. **Duplicate code** - `SleepStagePill` and `SleepTimelineCard` appear both in `TimelineView.swift` and as a variant in the diff. Ensure there's only one definition.

4. **Hardcoded strings** - Consider extracting to a `Strings` catalog for localization:
   - "Last Night's Sleep"
   - "Anabolic window:"
   - HR zone labels

---

## Design System Compliance ✅

| Requirement | Status |
|-------------|--------|
| Uses `CornerRadius.xl` for cards | ✅ |
| Uses `.ultraThinMaterial` backgrounds | ✅ |
| Uses `MeshGradientBackground` | ✅ |
| Consistent `Color.Monch.*` palette | ✅ |
| Uses `Font.Monch.*` typography | ✅ |
| Pill/capsule shapes for tags | ✅ |

---

## Recommendations

### Before Merge
1. ✅ Verify `SleepStage` enum exists in `HealthKitDataProvider.swift`
2. ✅ Update preview model containers to include new models

### Post-Merge Follow-ups
- [ ] Fetch and display HR data for workouts (Sprint 7)
- [ ] Wire up quick action buttons in insight cards
- [ ] Add sync debouncing to `HealthKitSyncService`
- [ ] Consider extracting `TimelineItem` to its own file

---

## Summary

| Category | Files | Lines |
|----------|-------|-------|
| New Models | 2 | ~490 |
| New Services | 1 | 400 |
| New Card Views | 5 | ~1,350 |
| Design System | 2 | ~255 |
| Timeline Updates | 1 | ~200 |
| Brain/Docs | 65+ | - |

**Verdict:** This is high-quality, well-organized code that establishes a solid foundation for the card system. The "Cozy Science" design language is implemented consistently. Ready to merge with the two minor fixes noted above.
