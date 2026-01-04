# Sprint 10: Advanced Insights, Quick-Add & Vibe Check

## Summary

Sprint 10 completes the remaining P1 features that enhance the insight engine's intelligence, add convenient quick-logging options, and introduce subjective state tracking.

---

## What's Been Implemented (Sprints 1-9)

| Category | Features |
|----------|----------|
| **Foundation** | HealthKit, SwiftData, Design System |
| **Timeline** | River UI, Day Headers, Empty State |
| **Food Logging** | Search, Cart, Meal Flow, Edit/Delete |
| **Insight Engine** | Sugar Spike, Digestion Debt, Muscle Sponge, Good Spike |
| **Mascot** | State Machine, Animations, Monch Detail View |
| **Notifications** | Permission, Kitchen Closing, Insight Alerts |
| **Manual Logging** | Exercise, Sleep, Historical Navigation |
| **Dashboard** | Today/Week/Month Views, Patterns, Streaks, Calendar |

---

## What's Still Missing (from Docs Review)

### From `Insights_Library.md` (P1 Detectors Not Yet Implemented)
| # | Insight | Status |
|---|---------|--------|
| 4 | Anxiety Mimic | ❌ Not implemented |
| 5 | Caffeine Jitter | ❌ Not implemented |
| 9 | Zone 2 Drain | ❌ Not implemented |
| 11 | Deep Sleep Robber | ❌ Not implemented |

### From `User Scenarios - Core Utility.md`
| Scenario | Status |
|----------|--------|
| 2.4 Caffeine Quick-Add | ❌ Not implemented |
| 2.4 Supplement Stack | ❌ Not implemented |
| 4.2 Hypnogram Visualization | ❌ Not implemented |
| 5.1 Vibe Check Modal | ❌ Not implemented |
| 5.2 Symptom Tagging | ❌ Not implemented |

### From `FEATURE-BREAKDOWN.md` (P1)
| # | Feature | Status |
|---|---------|--------|
| 19 | Caffeine Quick-Add Button | ❌ |
| 20 | Supplement Stack Quick-Add | ❌ |
| 28 | Anxiety Mimic Detector | ❌ |
| 29 | Caffeine Jitter Detector | ❌ |
| 30 | Zone 2 Drain Detector | ❌ |
| 31 | Deep Sleep Robber Detector | ❌ |
| 33 | Hypnogram Visualization | ❌ |
| 37 | Vibe Check Modal | ⭐ P2 but high value |
| 38 | Symptom Tagging | ⭐ P2 but high value |

---

## Sprint 10 Proposal (Revised)

### Estimated Effort: ~16-20 hours (2-3 PRs)

---

## Phase 1: Quick-Add Features (3-4 hours)

### [NEW] `CaffeineQuickAddView.swift`

One-tap caffeine logging with preset amounts:

| Preset | Caffeine (mg) |
|--------|---------------|
| ☕ Espresso | 63 |
| ☕ Coffee | 95 |
| 🍵 Green Tea | 28 |
| 🥤 Energy Drink | 80 |
| 💊 Caffeine Pill | 100-200 |

**Implementation:**
- Add caffeine quick-add button to TimelineView toolbar menu
- Creates a `MealLog` with `caffeine` field populated
- Timestamp for late-caffeine detection

---

### [NEW] `SupplementStackView.swift`

Quick-log common supplement stacks:

| Stack | Contents |
|-------|----------|
| 🛡️ AM Stack | Vitamin D, Omega-3, Magnesium |
| 🌙 PM Stack | ZMA, Glycine |
| 💪 Pre-Workout | Creatine, Beta-Alanine, Caffeine |
| ✏️ Custom | User-defined |

**For MVP:** Preset stacks only (no custom builder)

---

## Phase 2: Advanced Detectors (8-10 hours)

### [NEW] `AnxietyMimicDetector.swift` (P1 #28)

Detects when caffeine + low blood sugar mimics anxiety:

```swift
// Trigger: 2-3h after high-carb meal
if (hours_since_last_meal > 3) 
   AND (last_meal.carbs > 40g)
   AND (HR_gradient < -1.0) // Rapid drop
   AND (HRV < baseline * 0.8):
    TRIGGER "Anxiety Mimic"
```

**Insight Copy:** *"Feeling anxious? It's likely just a sugar crash from breakfast. It will pass soon."*

---

### [NEW] `CaffeineJitterDetector.swift` (P1 #29)

Detects caffeine-induced arousal vs anxiety:

```swift
if (caffeine_intake > 100mg within 4h)
   AND (HR > baseline + 10bpm)
   AND (respiratory_rate is STABLE):
    TRIGGER "Caffeine Jitter"
```

**Insight Copy:** *"High alert state detected. Perfect time for deep work?"*

---

### [NEW] `Zone2DrainDetector.swift` (P1 #30)

Detects insulin sensitivity boost from low-intensity exercise:

```swift
if (workout.type == Cardio)
   AND (duration_in_zone2 > 45_mins):
    TRIGGER "Zone 2 Drain"
```

**Insight Copy:** *"Your walk created a glucose sink. You can handle a heavier dinner tonight."*

**Dashboard Integration:** Show "Zone 2 Bonus" indicator on Today View

---

### [NEW] `DeepSleepRobberDetector.swift` (P1 #31)

Detects chronic patterns that erode deep sleep:

```swift
// Check over 7-day rolling window
if avg(deep_sleep) < 45min
   AND (late_meals > 3 OR late_caffeine > 3):
    TRIGGER "Deep Sleep Robber"
```

**Insight Copy:** *"Your deep sleep has been under 45 minutes for a week. Late meals or caffeine may be the culprit."*

---

## Phase 3: Hypnogram Visualization (2-3 hours)

### [NEW] `HypnogramView.swift` (P1 #33)

Visual representation of sleep stages:

```
┌─ HYPNOGRAM ──────────────────────────────────┐
│  Awake  ─┬───────────────────────────────────
│  REM    ─┤      ████       ███████          
│  Light  ─┤   ██    ██████        ████████   
│  Deep   ─┼──█        ██               ███───
│          └─────────────────────────────────→
│           10pm  12am   2am   4am   6am      
└─────────────────────────────────────────────┘
```

**Data Source:** `HKCategoryTypeSleepAnalysis` with stage values:
- `.asleep` (general)
- `.asleepCore` (Light)
- `.asleepDeep` (Deep)
- `.asleepREM` (REM)
- `.awake` (Awake)

**Integration:** Tap `SleepCardView` → expand to show Hypnogram

---

## Phase 4: Vibe Check & Symptom Tagging (3-4 hours)

### [NEW] `VibeCheckModal.swift` (P2 #37 - Pulling forward)

Quick subjective state capture:

```
┌─────────────────────────────────────┐
│         How are you feeling?         │
│                                       │
│  Energy:   ⚡️ High  ⚡ Med  💤 Low   │
│  Focus:    🎯 Sharp  ☁️ Foggy        │
│  Mood:     😊 Good  😐 Neutral  😔   │
│                                       │
│        [ Log Check-In ]               │
└─────────────────────────────────────┘
```

**Data Model Addition:**
```swift
@Model final class VibeCheck {
    var id: UUID
    var timestamp: Date
    var energy: VibeRating // .high, .medium, .low
    var focus: FocusRating // .sharp, .foggy
    var mood: MoodRating // .positive, .neutral, .low
}
```

**Usage:** Correlate with meals to train Brain Fog Forecast (P2 chronic insight)

---

### [NEW] `SymptomTagView.swift` (P2 #38 - Pulling forward)

Quick symptom logging for validation:

| Symptom | Validates Insight |
|---------|-------------------|
| 💓 Heart Racing | Sugar Spike, Caffeine Jitter |
| 🫨 Jittery | Anxiety Mimic, Caffeine Jitter |
| 😴 Drowsy | Digestion Debt |
| 🧠 Brain Fog | Sugar rollercoaster |

**Implementation:** Add symptom tags to existing timeline entries or as standalone events

---

## Implementation Order

### PR #1: Quick-Add & Caffeine Tracking (4-5h)
1. Caffeine Quick-Add Button
2. Supplement Stack Presets
3. Add caffeine field to meal model if not present

### PR #2: Advanced Detectors (8-10h)
1. Anxiety Mimic Detector
2. Caffeine Jitter Detector
3. Zone 2 Drain Detector
4. Deep Sleep Robber Detector
5. Hook all into InsightEngine

### PR #3: Visualization & Vibe (5-6h)
1. Hypnogram Visualization
2. Vibe Check Modal
3. Symptom Tagging

---

## Verification Plan

### Automated
- Unit tests for each detector algorithm
- Mock HealthKit data for edge cases

### Manual
- Test caffeine quick-add with various presets
- Verify detector triggers with synthetic data
- Visual QA on hypnogram with real sleep data
- Test Vibe Check modal flow

---

## Questions for Review

1. **Caffeine Quick-Add location**: 
   - Option A: Add to "+" menu alongside Food/Exercise/Sleep
   - Option B: Floating button on Timeline
   - Option C: Both

2. **Zone 2 Drain UI**: 
   - Should it show a "Dinner Bonus" card in Today View?
   - Or just a notification in the evening?

3. **Vibe Check timing**: 
   - Should we prompt at specific times (2pm post-lunch)?
   - Or only on-demand?

4. **Symptom vs Vibe Check**: 
   - Combine into one modal?
   - Or keep separate (Vibe = general, Symptoms = specific)?

---

## What Comes After Sprint 10

| Sprint | Focus |
|--------|-------|
| **11** | P2 Features: Barcode Scanner, Live Activity Widget |
| **12** | Polish: Custom Haptics, Onboarding Flow |
| **13** | Release Prep: App Icon, TestFlight |

---

# 🎨 COMPREHENSIVE UX AUDIT

## Methodology
This audit covers:
1. **End-to-End User Journeys** — Complete flows from entry to completion
2. **Screen-by-Screen Analysis** — Every view evaluated
3. **Missing Scenarios** — Edge cases and unhappy paths
4. **Micro-Interactions** — Animations, haptics, feedback
5. **Accessibility** — VoiceOver, Dynamic Type, contrast
6. **Design System Compliance** — Consistency with tokens

---

## 1. END-TO-END USER JOURNEYS

### Journey 1: First-Time User (Day 0)

| Step | Current State | Issue | Recommendation |
|------|---------------|-------|----------------|
| 1. Launch app | Goes directly to Timeline | ❌ No onboarding | Add welcome flow explaining value prop |
| 2. HealthKit prompt | System alert | ⚠️ No context | Add pre-permission screen with mascot explaining why |
| 3. Empty Timeline | Shows EmptyTimelineView | ✅ Good | Monch hungry + CTA works |
| 4. First meal log | FoodSearchView | ⚠️ Cold search | Add "Popular First Meals" (Oatmeal, Coffee, etc.) |
| 5. Post-log | Returns to timeline | ❌ No celebration | Add first-meal celebration ("Monch's first bite!") |
| 6. First insight | May not trigger | ⚠️ Could be hours | Add "Learning" card explaining Monch is watching |

**Missing: Complete Onboarding Flow**
```
┌─────────────────────────────────────┐
│  Welcome to Monch! 🐊               │
│                                     │
│  [Animated Monch waving]            │
│                                     │
│  "I'm your metabolic companion.     │
│   I'll help you understand how      │
│   food affects your energy."        │
│                                     │
│  [ Get Started → ]                  │
└─────────────────────────────────────┘
        ↓
┌─────────────────────────────────────┐
│  Let's Connect to Health 💚         │
│                                     │
│  [Monch with stethoscope]           │
│                                     │
│  "I need access to your heart rate  │
│   to detect sugar spikes and help   │
│   you feel your best."              │
│                                     │
│  [ Connect Health → ]               │
└─────────────────────────────────────┘
        ↓
┌─────────────────────────────────────┐
│  Your First Meal 🍽️                 │
│                                     │
│  [Monch looking hungry]             │
│                                     │
│  "What did you have for breakfast   │
│   today? I'll start learning        │
│   your patterns."                   │
│                                     │
│  [ Log Breakfast → ] [ Skip → ]     │
└─────────────────────────────────────┘
```

---

### Journey 2: Daily Active User

| Step | Current State | Issue | Recommendation |
|------|---------------|-------|----------------|
| 1. Morning open | Shows yesterday's sleep | ✅ Good | Sleep card at top is correct |
| 2. Log breakfast | Via + menu | ⚠️ Extra tap | Add quick-log for recent/frequent meals |
| 3. Sugar spike detected | Insight card appears | ✅ Good | |
| 4. Tap insight | Opens InsightCardView | ✅ Good | |
| 5. Take action (walk) | Action button present | ⚠️ No confirmation | Add success feedback after action |
| 6. Evening review | Manual scroll | ❌ No summary | Add end-of-day summary notification |

**Missing: End-of-Day Summary**
```
┌─────────────────────────────────────┐
│  🌙 Day Complete                    │
│                                     │
│  Today's Highlights:                │
│  • 3 meals logged                   │
│  • 1 sugar spike (mitigated!)       │
│  • 45 min Zone 2 exercise           │
│                                     │
│  Monch says: "Great recovery day!"  │
│                                     │
│  [ View Dashboard → ]               │
└─────────────────────────────────────┘
```

---

### Journey 3: Insight Response Flow

| Step | Current State | Issue | Recommendation |
|------|---------------|-------|----------------|
| 1. Insight triggers | Creates InsightEvent | ✅ | |
| 2. Notification sent | Via NotificationManager | ⚠️ Generic title | Make title Monch-branded ("Monch noticed...") |
| 3. Tap notification | Opens app | ❌ Goes to Timeline, not insight | Deep-link to specific InsightCardView |
| 4. Read insight | Shows full card | ✅ | |
| 5. Take action | Button present | ⚠️ Some incomplete | "Add Walk" opens nothing |
| 6. Insight resolved | No closure | ❌ Missing | Add "resolved" state with celebration |

**Missing: Insight Resolution Celebration**
```
// When user completes suggested action
InsightCardView(insight: insight, isResolved: true)

// Shows:
┌─────────────────────────────────────┐
│  ✅ Nice Work!                      │
│                                     │
│  [Happy Monch with sparkles]        │
│                                     │
│  "That walk helped flatten your     │
│   curve. Energy is stabilizing."    │
│                                     │
│  [ Done ]                           │
└─────────────────────────────────────┘
```

---

### Journey 4: Historical Review

| Step | Current State | Issue | Recommendation |
|------|---------------|-------|----------------|
| 1. Tap calendar icon | Opens DatePickerSheet | ✅ | |
| 2. Select past date | Timeline filters | ✅ | |
| 3. View old entries | Cards display | ⚠️ No "read-only" indicator | Add subtle "Past" badge |
| 4. Edit old meal | Full editing available | ✅ | |
| 5. Return to today | "Go to Today" button | ✅ | |
| 6. Navigate via Dashboard | Calendar tap → Timeline | ⚠️ Tab switches but no scroll | Scroll to selected date |

---

### Journey 5: Pattern Discovery (Week 2+)

| Step | Current State | Issue | Recommendation |
|------|---------------|-------|----------------|
| 1. Pattern detected | Shown in WeekView | ✅ | |
| 2. Tap pattern card | No action | ❌ Missing | Link to specific meals/insights |
| 3. See historical data | WeeklyBarChart | ⚠️ No tap interaction | Tap bar → that day's Timeline |
| 4. Compare weeks | Trend arrows shown | ✅ | |
| 5. Act on pattern | No guidance | ❌ Missing | Add "Try This Week" goal setting |

**Missing: Pattern-to-Action Flow**
```
// PatternCard with drill-down
PatternCard(pattern: pattern)
    .onTapGesture {
        showPatternDetail = true
    }

// PatternDetailSheet shows:
- All linked entries (meals, insights)
- Timeline mini-view of affected days
- "Set Goal" option ("Kitchen closes at 8pm")
```

---

### Journey 6: Streak Maintenance

| Step | Current State | Issue | Recommendation |
|------|---------------|-------|----------------|
| 1. Streak active | Shown in MonthView | ✅ | |
| 2. Streak milestone (7) | No celebration | ❌ Missing | Add confetti + haptic |
| 3. Streak at risk | Pulsing border | ✅ | |
| 4. Streak broken | No handling | ❌ Missing | Gentle "Start Fresh" message |
| 5. New streak starts | No feedback | ❌ Missing | "Day 1 of new streak!" |

---

## 2. SCREEN-BY-SCREEN ANALYSIS

### TimelineView

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| MascotHeader | ✅ | | |
| Empty state | ✅ | | |
| Day grouping | ✅ | | |
| Meal cards | ✅ | | |
| Insight cards | ✅ | | |
| Workout cards | ✅ | | |
| Sleep cards | ✅ | | |
| + Menu | ⚠️ | Requires 2 taps | Add floating quick-add for most common |
| Date picker | ✅ | | |
| HealthKit banner | ✅ | | |
| Pull-to-refresh | ❌ | Missing | Add RefreshableScrollView |
| Loading state | ❌ | Missing | Add skeleton cards while fetching |
| Scroll position | ❌ | Lost on tab switch | Persist scroll position |

---

### DashboardView

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| Segmented control | ✅ | | |
| TodayView | ✅ | | |
| WeekView | ✅ | | |
| MonthView | ✅ | | |
| Calendar tap | ⚠️ | Switches tab but no scroll | Pass date to TimelineView |
| Empty weeks | ✅ | Ghosted bars | |
| Trend comparison | ✅ | | |
| Pattern cards | ⚠️ | Not tappable | Add drill-down |
| Streak celebration | ❌ | Missing | Add milestone animations |

---

### FoodSearchView

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| Search bar | ✅ | | |
| Results list | ✅ | | |
| Recent foods | ❌ | Missing | Add "Recent" section at top |
| Frequent foods | ❌ | Missing | Add "Frequent" section |
| Barcode scanner | ❌ | Missing (P2) | Sprint 11 |
| AI photo input | ❌ | Missing (P3) | Future |
| Create custom food | ⚠️ | Basic | Add nutrient estimation helper |
| Serving size | ⚠️ | Fixed at 1.0 | Add quantity adjuster in search results |
| Loading state | ⚠️ | Generic | Add Monch searching animation |

---

### FoodCardView (Detail)

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| Header | ✅ | | |
| Serving size control | ✅ | | |
| Macro breakdown | ✅ | | |
| Micro breakdown | ⚠️ | Always hidden | Show if data exists |
| Context tags | ✅ | | |
| Delete action | ✅ | | |
| Save changes | ⚠️ | Auto-save vs explicit | Add explicit "Save" button |
| Linked insights | ❌ | Missing | Show "Triggered: Sugar Spike" if applicable |

---

### MascotDetailView

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| Hero mascot | ✅ | | |
| Coaching text | ✅ | Good per-mood copy | |
| Data context | ⚠️ | Hardcoded values | Connect to real data |
| Quick actions | ✅ | | |
| "Add Walk" action | ❌ | No implementation | Link to workout flow or Health app |
| "Close Kitchen" action | ❌ | No implementation | Log fasting start event |
| Haptic on open | ❌ | Missing | Add soft impact |

---

### InsightCardView

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| Insight type display | ✅ | | |
| Message | ✅ | | |
| Severity indicator | ⚠️ | Visual only | Add VoiceOver label |
| Linked meal | ⚠️ | Shows ID | Show meal name + tap to open FoodCard |
| Quick actions | ✅ | | |
| Dismiss action | ✅ | | |
| Resolved state | ❌ | Missing | Add visual for "action taken" |

---

### SleepCardView

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| Duration | ✅ | | |
| Quality score | ✅ | | |
| Stage breakdown | ✅ | | |
| Hypnogram | ❌ | Missing | Sprint 10 Phase 3 |
| Context (late meal) | ⚠️ | Sometimes shown | Always correlate with previous night's meal |
| Time adjustments | ✅ | | |

---

### ExerciseCardView

| Element | Status | Issue | Fix |
|---------|--------|-------|-----|
| Activity type | ✅ | | |
| Duration/distance | ✅ | | |
| Heart rate zones | ✅ | | |
| Anabolic window | ✅ | | |
| Zone 2 indicator | ⚠️ | Not prominent | Add "Glucose Sink" badge for 45+ min |
| Edit capability | ⚠️ | Read-only for HealthKit synced | Allow timestamp adjustments |

---

## 3. MISSING SCENARIOS (50+ Edge Cases)

### Onboarding & First Use

| # | Scenario | Current Handling | Required |
|---|----------|------------------|----------|
| 1 | First launch | Direct to empty Timeline | Onboarding carousel |
| 2 | HealthKit denied | Banner shown | Explain impact + retry option |
| 3 | HealthKit partial | N/A | Handle mixed permissions gracefully |
| 4 | No Apple Watch | N/A | Fallback to iPhone HR (if available) |
| 5 | First meal logged | Silent | Celebration + tutorial tip |
| 6 | First insight triggered | Shows on Timeline | Tutorial callout explaining what it means |
| 7 | Day 7 milestone | Nothing | "Patterns unlocking" celebration |

---

### Data Entry Edge Cases

| # | Scenario | Current Handling | Required |
|---|----------|------------------|----------|
| 8 | Duplicate meal entry | Allowed | Warning or merge suggestion |
| 9 | Meal logged for future time | Allowed | Block or warn |
| 10 | Very high calorie meal (5000+) | Allowed | Confirmation prompt |
| 11 | Zero-calorie meal | Allowed | Ask if intentional |
| 12 | Caffeine after 6pm | No warning | Gentle "late caffeine" context tag |
| 13 | No meals logged by 2pm | Nothing | Monch hungry notification |
| 14 | 10+ meals in one day | Allowed | Pattern detection for grazing |
| 15 | Meal name is empty | Allowed | Require name or suggest "Snack" |
| 16 | Search returns no results | "No results" | Suggest "Create Custom" prominently |
| 17 | Network error during search | ❌ Unclear | Show offline mode + cached results |

---

### Insight Edge Cases

| # | Scenario | Current Handling | Required |
|---|----------|------------------|----------|
| 18 | Insight triggered but user inactive | Notification sent | Add follow-up if not viewed |
| 19 | Multiple insights same hour | All shown | Group or prioritize |
| 20 | Conflicting insights | Both shown | Explain relationship |
| 21 | Insight for old meal (historical edit) | May trigger | Block or flag as "late detection" |
| 22 | User dismisses all insights | Allowed | Track engagement, adjust frequency |
| 23 | Same insight type 3x in one day | All shown separately | Consolidate with "Pattern emerging" note |
| 24 | Insight action not possible | Button shown | Disable with explanation |
| 25 | Good Spike during reported exercise | Suppressed | ✅ Working correctly |

---

### Timeline Edge Cases

| # | Scenario | Current Handling | Required |
|---|----------|------------------|----------|
| 26 | 100+ entries in one day | All loaded | Pagination or "Show More" |
| 27 | Very old date selected (1 year ago) | Empty timeline | Show "No data from this date" |
| 28 | Future date selected | Blocked in picker | ✅ Correct |
| 29 | Timezone change (travel) | ❌ Untested | Handle gracefully, ask user |
| 30 | Daylight saving time | ❌ Untested | Verify grouping still works |
| 31 | Midnight meal (11:55pm) | Shows on that day | Correct but verify sleep correlation |
| 32 | 24-hour fast | Empty timeline | Show "Rest day" or fasting indicator |

---

### Dashboard Edge Cases

| # | Scenario | Current Handling | Required |
|---|----------|------------------|----------|
| 33 | Only 1 day of data | Shows partial | Explain "Need 7 days for patterns" |
| 34 | Exactly 7 days | Shows full week | Celebrate "First pattern detected!" |
| 35 | 30+ days | All shown | Pagination for month calendar |
| 36 | Perfect week (no issues) | High score | Celebration + Monch happy |
| 37 | Terrible week (daily spikes) | Low vibe | Supportive message, not judgment |
| 38 | No workouts in week | No Zone 2 bonus | Gentle nudge "Movement helps metabolism" |
| 39 | Week with travel | Mixed data | Flag as "Unusual week" |
| 40 | Streak at 29 days | Show progress | "1 day to 30-day milestone!" |

---

### Mascot Edge Cases

| # | Scenario | Current Handling | Required |
|---|----------|------------------|----------|
| 41 | No data for mood calculation | Defaults to neutral | ✅ Correct |
| 42 | Conflicting signals (sleepy + spiking) | Priority logic | Verify priority is correct |
| 43 | Mood changes mid-viewing | Static | Consider live update |
| 44 | User taps mascot 10x rapidly | All register | Debounce taps |
| 45 | Mascot asset fails to load | ❌ Blank | Fallback to emoji |

---

### System Edge Cases

| # | Scenario | Current Handling | Required |
|---|----------|------------------|----------|
| 46 | App backgrounded during meal log | Sheet dismissed? | Preserve draft state |
| 47 | Low storage warning | ❌ No handling | Graceful degradation |
| 48 | iOS update changes HealthKit | ❌ No handling | Version-aware API calls |
| 49 | User deletes all data | Allowed | Confirmation + "Start Fresh" flow |
| 50 | iCloud sync conflict | ❌ No handling | SwiftData conflict resolution |
| 51 | Notification permission denied | ❌ Silent fail | Explain value + re-prompt option |
| 52 | User in Do Not Disturb | Notifications queued | ✅ System handles |

---

## 4. MICRO-INTERACTIONS AUDIT

### Haptics (Missing or Incomplete)

| Trigger | Current | Recommended |
|---------|---------|-------------|
| Meal logged | None | Success (light) |
| Insight appeared | None | Warning (medium) |
| Mascot tapped | None | Soft impact |
| Segment switched | None | Selection |
| Streak milestone | None | Success (heavy) + confetti |
| Streak broken | None | Failure (soft) |
| Pull-to-refresh | N/A | Impact when released |
| Delete confirmation | None | Warning (rigid) |
| Action completed | None | Success (light) |

---

### Animations (Missing or Incomplete)

| Element | Current | Recommended |
|---------|---------|-------------|
| Mascot idle | Static image | Subtle breathing animation |
| Mascot mood change | Instant swap | Crossfade with scale |
| Insight card appear | Slide in | Slide + slight bounce |
| Timeline item appear | Fade | Staggered slide |
| Score ring | Static | Animate on appear |
| Pattern card | Static | Slide in staggered |
| Streak counter | Number only | Count-up animation |
| Tab switch | Instant | Crossfade |
| Sheet presentation | iOS default | Custom spring |
| Celebration confetti | Missing | Add for milestones |

---

### Feedback Loops (Missing)

| Action | Current Feedback | Recommended |
|--------|------------------|-------------|
| Meal saved | Card appears | Toast "Saved!" + haptic |
| Insight dismissed | Card removed | "Got it" toast |
| Action taken | Sheet closes | Success state in card |
| Streak extended | Silent | "Day X!" badge flash |
| Goal achieved | N/A | Celebration modal |
| Pattern resolved | N/A | "Improvement!" badge |

---

## 5. ACCESSIBILITY AUDIT

### VoiceOver

| Element | Current | Required |
|---------|---------|----------|
| Mascot header | Image only | "Monch is [mood]. [status text]" |
| Insight severity | Color only | "Moderate severity" label |
| Macro ring | Visual only | "52% carbs, 28% protein, 20% fat" |
| Bar chart | Visual only | Per-bar labels |
| Calendar colors | Visual only | "January 2nd, balanced day" |
| Streak card | Partial | Full streak context |
| Timeline cards | Link names only | Full content description |

---

### Dynamic Type

| Screen | Status | Notes |
|--------|--------|-------|
| Timeline | ⚠️ | Some fixed-size elements |
| Dashboard | ⚠️ | Charts don't scale |
| FoodCard | ✅ | Mostly scales |
| InsightCard | ✅ | |
| Mascot views | ⚠️ | Mascot size fixed |

---

### Color Contrast

| Element | Issue |
|---------|-------|
| Light sage on cream | May fail WCAG AA |
| Periwinkle text | Too light |
| Secondary labels | Check in light mode |

---

## 6. DESIGN SYSTEM COMPLIANCE

### Inconsistencies Found

| Location | Issue | Fix |
|----------|-------|-----|
| TimelineView padding | Mixed `.padding()` and `.padding(.horizontal)` | Use `Spacing.md` consistently |
| MealCard corner radius | Hardcoded `12` | Use `CornerRadius.md` |
| Font usage | Some `Font.headline` vs `.Monch.headline` | All should use `.Monch.*` |
| Colors | Some `Color.gray` vs `.secondary` | Audit all color usage |
| Capsule styling | Inconsistent padding | Create standard capsule modifier |

---

### 🌊 THE MISSING RIVER (P0)
The "River UI" is the visual soul of Monch. Currently, the implementation uses a standard `LazyVStack` list, which contradicts the "Cozy Science" aesthetic defined in the Design System.

**Phase 1: The Organic Path**
- Implement a `RiverPathView` that draws a soft, vertical spline behind the items.
- Items should slightly offset (±8pt) from the center to feel like floating stones.

**Phase 2: Proper Bubble Styling**
- Update all timeline cards to use `CornerRadius.xl` (24pt) as specified in `Design_System.md`.
- Replace hardcoded `12pt` corner radius in `MealCard`.

**Phase 3: Fluid Transitions**
- Scrolling should feel like the "river" is moving, with cards bobbing slightly on appear using basic SwiftUI spring animations.

---


## 7. PRIORITY IMPROVEMENTS (Sprint 10 Additions)

### Must Have (P0)

| # | Improvement | Effort |
|---|-------------|--------|
| 1 | **River UI Implementation (Spline + Offsets)** | 4h |
| 2 | Onboarding flow (3 screens) | 3h |
| 3 | First-meal celebration | 1h |
| 4 | Notification deep-linking | 2h |
| 5 | Real data in MascotDetailView | 1h |
| 6 | Pull-to-refresh on Timeline | 30m |
| 7 | Recent/frequent foods in search | 2h |

### Should Have (P1)

| # | Improvement | Effort |
|---|-------------|--------|
| 7 | Insight resolution state | 2h |
| 8 | Pattern card drill-down | 2h |
| 9 | Streak milestone celebrations | 1h |
| 10 | Loading skeletons | 1h |
| 11 | Haptic feedback system | 2h |
| 12 | End-of-day summary notification | 2h |

### Nice to Have (P2)

| # | Improvement | Effort |
|---|-------------|--------|
| 13 | Timezone handling | 3h |
| 14 | Offline mode indicator | 1h |
| 15 | Mascot fallback (emoji) | 30m |
| 16 | Confetti animations | 1h |
| 17 | VoiceOver complete audit | 3h |
| 18 | Dynamic Type full support | 2h |

---

## 8. REVISED SPRINT 10 SCOPE

Based on this audit, recommend adding to Sprint 10:

### Add to Sprint 10 (High Impact, Low Effort)

1. **River UI** — Move from standard list to organic curved path
2. **Onboarding Flow** — Critical for first-time users
3. **Recent/Frequent Foods** — Major friction reducer
4. **Notification Deep-Linking** — Currently broken flow
5. **Real Data in MascotDetailView** — Currently hardcoded
6. **Haptic Feedback System** — Creates premium feel

### Defer to Sprint 11

1. Full Accessibility Audit
2. Timezone Handling
3. Offline Mode
4. Confetti Animations

### Defer to Sprint 12 (Polish)

1. Dynamic Type Complete
2. Design System Consistency Audit
3. Custom Sheet Animations

