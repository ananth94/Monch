# Sprint 9: Dashboard View Implementation Plan

## Summary

Build the **Metabolic Status Hub** — a second top-level screen with Today/Week/Month views showing aggregated insights, patterns, and streaks.

---

## User Review Required

> [!IMPORTANT]
> **Tab Navigation**: This adds a tab bar to the app (Timeline + Dashboard). Confirm this navigation pattern is acceptable.

> [!WARNING]
> **Metabolic Score Algorithm**: Revised to be less punitive and more aligned with "Cozy Science" philosophy. See Section 2.

> [!IMPORTANT]
> **Hydration Tracking**: Removed from Quick Stats until water logging is implemented in data model.

---

## Navigation Layout

### Screen Structure
```
┌────────────────────────────────┐
│  ← Dashboard                   │  ← Nav bar (iOS standard)
├────────────────────────────────┤
│  [ Today ] [ Week ] [ Month ]  │  ← Segmented control (TOP)
├────────────────────────────────┤
│                                │
│  🐊 Monch Header               │  ← Emotional anchor
│                                │
│  [Scrollable Content]          │  ← Cards, charts, insights
│                                │
│                                │
├────────────────────────────────┤
│  🏠 Timeline  │  📊 Dashboard  │  ← Tab bar (BOTTOM)
└────────────────────────────────┘
```

### Rationale
| Control | Position | Why |
|---------|----------|-----|
| **Tab Bar** | Bottom | iOS standard; thumb reachability; always visible |
| **Segmented Control** | Top | Matches Apple Health pattern; preserves scroll space; lets Monch own center screen |

### Implementation Notes
- Tab bar uses SF Symbols: `house.fill`, `chart.bar.fill`
- Segmented control uses `.segmentedPickerStyle()`
- Monch header is first item in scroll content (not sticky)

---


## 1. UX Design Principles for Dashboard

### Core Philosophy
- **Supportive, not punitive**: The dashboard celebrates wins, not failures
- **Cozy Science**: Data is presented through emotion and character
- **Actionable Insights**: Every pattern shown includes a "what to try" nudge
- **Consistent Language**: Same component patterns as Timeline

### Visual Consistency Checklist
- [ ] Monch header appears on Dashboard (same as Timeline)
- [ ] Card styling matches Timeline card components
- [ ] Mood gradients (Coral/Sage/Periwinkle) used consistently
- [ ] Typography uses Monch font scale
- [ ] Spacing uses 8pt grid tokens
- [ ] Dark mode tested for all new components

---

## 2. Metabolic Vibe System (Revised Score)

### Problem with Original Algorithm
Pure penalty-based scoring (-10 per spike, -15 per debt) punishes honest logging and conflicts with our "supportive companion" philosophy.

### Revised: "Metabolic Vibe" Indicator

Instead of a 0-100 number, use a **qualitative 5-tier system**:

| Tier | Name | Color | Condition |
|------|------|-------|-----------|
| 5 | 🌟 **Thriving** | Sage | 0 spikes, 0 debts, used anabolic window |
| 4 | 💚 **Balanced** | Light Sage | ≤1 spike, 0 debts |
| 3 | 😊 **Steady** | Neutral | 1-2 spikes, ≤1 debt |
| 2 | 🌤️ **Learning** | Light Coral | 3+ spikes OR 2+ debts |
| 1 | 🌱 **Resetting** | Periwinkle | Rough day — tomorrow is fresh |

### Algorithm
```swift
func computeMetabolicVibe(spikes: Int, debts: Int, sponges: Int, goodSleep: Bool) -> MetabolicTier {
    let negatives = spikes + (debts * 2)
    let positives = sponges + (goodSleep ? 2 : 0)
    let net = positives - negatives
    
    switch net {
    case 3...: return .thriving
    case 1...2: return .balanced
    case 0: return .steady
    case -2...(-1): return .learning
    default: return .resetting
    }
}
```

### Visual Treatment
- Large circular indicator with tier emoji
- Soft gradient ring (tier color)
- Encouraging copy below: "You're doing great!" or "Every day is practice."
- NO harsh numbers, NO red "failure" states

---

## 3. User Scenarios & Edge Cases

### Scenario 1: Brand New User (Day 0)
**Context:** User opens Dashboard for first time. No meals, no insights.

**Today View:**
```
┌─────────────────────────────────────┐
│  🐊 Monch is waiting                │
├─────────────────────────────────────┤
│                                     │
│       [Hungry Monch illustration]   │
│                                     │
│   "Your metabolic story starts      │
│    with your first meal."           │
│                                     │
│   [ Log Breakfast → ]               │
│                                     │
└─────────────────────────────────────┘
```

**Week View:**
- Ghosted bar chart (7 empty slots)
- Copy: "Patterns emerge after 7 days of logging."

**Month View:**
- Ghosted calendar grid
- Copy: "Building your baseline... keep logging!"

---

### Scenario 2: Partial Week (Days 1-6)
**Context:** User has 4 days of data, opens Week View.

**Display:**
```
┌─────────────────────────────────────┐
│  M   T   W   T   F   S   S          │
│  █   █   █   █   ░   ░   ░          │
│                                     │
│  "4 days logged — 3 more to see     │
│   your first weekly pattern!"       │
└─────────────────────────────────────┘
```

- Filled bars for logged days
- Ghosted (░) bars for missing days
- Progress indicator: "4/7 days"

---

### Scenario 3: Perfect Day
**Context:** User logged 3 meals, took a walk after lunch, slept 8 hours, no spikes.

**Today View:**
```
┌─────────────────────────────────────┐
│  🐊 Monch is thriving!              │
├─────────────────────────────────────┤
│                                     │
│         🌟 THRIVING                 │
│      ████████████████               │
│                                     │
│  "Nailed it. Your body thanks you." │
│                                     │
├─────────────────────────────────────┤
│  💪 Anabolic Window Used • 12:30pm  │
│  😴 8h 15m Quality Sleep            │
│  🍽️ 1,620 kcal logged               │
└─────────────────────────────────────┘
```

- Celebration copy, not neutral
- Highlight the wins explicitly
- Monch looks happy/strong

---

### Scenario 4: Rough Day (Multiple Spikes)
**Context:** User had 3 sugar spikes and a late-night meal.

**Today View:**
```
┌─────────────────────────────────────┐
│  🐊 Monch is learning with you      │
├─────────────────────────────────────┤
│                                     │
│         🌤️ LEARNING                │
│      ████████░░░░░░░░               │
│                                     │
│  "Rough one. Tomorrow is fresh."    │
│                                     │
├─────────────────────────────────────┤
│  💡 TODAY'S INSIGHTS                │
│                                     │
│  ⚡ Sugar Spike • 9am               │
│  ⚡ Sugar Spike • 1pm               │
│  ⚡ Sugar Spike • 6pm               │
│  🌙 Late Meal • 10:30pm             │
│                                     │
│  ▼ What to try tomorrow             │
│  "Add protein to breakfast to       │
│   flatten the morning curve."       │
└─────────────────────────────────────┘
```

- Supportive, not judgmental tone
- Specific, actionable suggestion
- "What to try" section is collapsible

---

### Scenario 5: Weekend Pattern Detected
**Context:** User has 2 weeks of data. Late meals on Fri/Sat both weeks.

**Week View:**
```
┌─────────────────────────────────────┐
│  🔁 PATTERNS DETECTED               │
│                                     │
│  ┌────────────────────────────┐     │
│  │ 🌙 Weekend Wind-Down        │     │
│  │                             │     │
│  │ Late meals on Fri & Sat     │     │
│  │ (2 weeks in a row)          │     │
│  │                             │     │
│  │ 📉 Impact: ~12% less Deep   │     │
│  │    Sleep on those nights    │     │
│  │                             │     │
│  │ 💡 Try: Kitchen closes at   │     │
│  │    8pm on weekends?         │     │
│  │                             │     │
│  │ [ See Linked Meals → ]      │     │
│  └────────────────────────────┘     │
└─────────────────────────────────────┘
```

**Pattern Card Structure:**
1. **Pattern Name** (friendly, not clinical)
2. **What happened** (factual)
3. **Why it matters** (biological cost)
4. **What to try** (actionable nudge)
5. **Drill-down** (link to specific entries)

---

### Scenario 6: Active Streak
**Context:** User hasn't eaten after 9pm for 12 days straight.

**Month View:**
```
┌─────────────────────────────────────┐
│  🔥 STREAKS                         │
│                                     │
│  ┌────────────────────────────┐     │
│  │ 🌙 12 DAYS                  │     │
│  │ Kitchen Closed by 9pm       │     │
│  │                             │     │
│  │ [████████████░░░░░░]        │     │
│  │ Personal best: 14 days      │     │
│  └────────────────────────────┘     │
│                                     │
│  ┌────────────────────────────┐     │
│  │ 💪 5 DAYS                   │     │
│  │ Post-Workout Refueling      │     │
│  └────────────────────────────┘     │
└─────────────────────────────────────┘
```

- Progress bar toward personal best
- Subtle celebration at milestones (7, 14, 21, 30 days)
- Light haptic feedback when streak increments

---

### Scenario 7: Streak at Risk
**Context:** User's "Kitchen Closed" streak is at 12 days. It's 8:45pm.

**Push Notification:**
```
🌙 Streak Check
Your 12-day kitchen-closed streak is almost locked in!
[ I'm Done Eating ] [ Snooze 30min ]
```

**Dashboard Streak Card:**
- Card has subtle pulsing border
- Copy: "Close the kitchen to keep your streak!"

---

### Scenario 8: Month Calendar Tap
**Context:** User taps a specific day on the Month calendar.

**Flow:**
1. User taps "Jan 2" on calendar
2. Tab bar switches to Timeline
3. Timeline scrolls to January 2nd entries
4. Toast appears: "Viewing Jan 2"

**Implementation:**
```swift
// In MetabolicCalendar
onTapDay: { date in
    selectedTab = .timeline
    timelineDate = date
}
```

---

### Scenario 9: Insight Card Drill-Down
**Context:** User taps an insight in Today View.

**Expected Behavior:**
- Opens `InsightCard` as a sheet (same component from Timeline)
- Shows full insight details
- "Linked Entries" section shows triggering meal
- Quick actions available (Start Walk, Log Snack, etc.)

**This ensures consistency between Timeline and Dashboard insight displays.**

---

### Scenario 10: Week-over-Week Comparison
**Context:** User views Week View with previous week data available.

**Display:**
```
┌─────────────────────────────────────┐
│  📈 WEEKLY TRENDS                   │
│                                     │
│  Compared to last week:             │
│                                     │
│  Carbs     ↓ 12%  │  Better control │
│  Protein   ↑ 8%   │  Nice!          │
│  Spikes    ↓ 2    │  Fewer crashes  │
│  Sleep     ↑ 23m  │  More rest      │
│                                     │
└─────────────────────────────────────┘
```

- Green arrows for improvements
- Neutral for similar
- Gentle language for declines ("Room to improve")

---

## 4. Proposed Changes (Updated)

### Phase 1: Tab Navigation Structure

#### [NEW] MainTabView.swift
- TabView with Timeline and Dashboard tabs
- Tab icons: `house.fill`, `chart.bar.fill`
- Selected tab state management

#### [MODIFY] ContentView.swift  
- Replace TimelineView with MainTabView

---

### Phase 2: Dashboard Shell & Today View

#### [NEW] DashboardView.swift
- Segmented control: Today / Week / Month
- Container for time-period views
- Pull-to-refresh support
- Empty state handling

#### [NEW] TodayView.swift
- Mascot header (reuse existing MascotHeader)
- MetabolicVibeIndicator component (revised from ScoreRing)
- Quick stats row (kcal, sleep, zone2) — NO hydration
- Today's insights list (tap to open InsightCard)
- MacroBreakdownRing component
- "What to try" collapsible section

#### [NEW] Components/MetabolicVibeIndicator.swift
- 5-tier qualitative display (Thriving → Resetting)
- Tier emoji + name + gradient ring
- Encouraging copy
- Animated on appear

#### [NEW] Components/MacroBreakdownRing.swift
- Donut chart for C/P/F percentages
- Tap to expand details
- Uses Design System colors

---

### Phase 3: Week View

#### [NEW] WeekView.swift
- 7-day bar chart
- Week-over-week comparison section
- Pattern cards list
- Weekly insight summary
- Empty/partial state handling

#### [NEW] Components/WeeklyBarChart.swift
- M-T-W-T-F-S-S layout
- Stacked bars for C/P/F
- Ghosted bars for missing data
- Tap bar to view that day

#### [NEW] Components/PatternCard.swift
- Pattern name + icon
- What happened + why it matters + what to try
- Drill-down link to entries
- Loop color coding (border accent)

#### [NEW] Components/TrendRow.swift
- Metric name + arrow + delta + copy
- Green/neutral styling (no red)

---

### Phase 4: Month View

#### [NEW] MonthView.swift
- Metabolic calendar heat map
- Streaks section
- Chronic insights section
- Tap day → navigate to Timeline

#### [NEW] Components/MetabolicCalendar.swift
- Grid of days with vibe-tier colors
- Tap day triggers tab switch + scroll
- Current day highlighted

#### [NEW] Components/StreakCard.swift
- Streak icon + count + description
- Progress toward personal best
- Pulsing border when at risk
- Celebration animation at milestones

#### [NEW] Components/ChronicInsightCard.swift
- Chronic loop insight (Mineral Gap, Brain Fog)
- Educational tone
- Link to learn more

---

### Phase 5: Data Aggregation Services

#### [NEW] DashboardDataService.swift
```swift
func computeTodayMetrics(meals:insights:workouts:sleep:) -> TodaySummary
func computeMetabolicVibe(spikes:debts:sponges:goodSleep:) -> MetabolicTier
func computeWeeklyTrends(thisWeek:lastWeek:) -> WeeklySummary
func computeMonthlyData(meals:insights:) -> MonthlySummary
func detectPatterns(meals:insights:workouts:days:) -> [Pattern]
func calculateStreaks(meals:insights:) -> [Streak]
func checkStreakAtRisk(streak:currentTime:) -> Bool
```

#### [NEW] Models/DashboardModels.swift
```swift
enum MetabolicTier: String, CaseIterable {
    case thriving, balanced, steady, learning, resetting
}

struct TodaySummary {
    let vibe: MetabolicTier
    let calories: Double
    let sleepDuration: TimeInterval?
    let zone2Minutes: Int
    let insights: [InsightEvent]
    let macros: MacroBreakdown
}

struct WeeklySummary {
    let dailyData: [DailySummary]
    let trends: [Trend]
    let patterns: [Pattern]
}

struct MonthlySummary {
    let calendar: [Date: MetabolicTier]
    let streaks: [Streak]
    let chronicInsights: [InsightEvent]
}

struct Pattern {
    let name: String
    let icon: String
    let description: String
    let impact: String
    let suggestion: String
    let linkedEntryIDs: [UUID]
}

struct Streak {
    let type: StreakType
    let count: Int
    let personalBest: Int
    let isAtRisk: Bool
}
```

---

### Phase 6: Navigation Integration

#### [MODIFY] TimelineView.swift
- Accept `selectedDate: Binding<Date?>` 
- Scroll to date when set externally
- Show toast when navigated from calendar

---

## 5. Accessibility Requirements

| Component | Requirement |
|-----------|-------------|
| MetabolicVibeIndicator | VoiceOver: "Your metabolic vibe is [tier]. [copy]" |
| WeeklyBarChart | Per-day labels: "Monday, 1420 calories, 52% carbs" |
| PatternCard | Full content readable |
| StreakCard | "12 day streak for kitchen closed by 9pm" |
| Calendar | "January 2nd, balanced day" + double-tap to view |

---

## 6. Animation & Haptics

| Trigger | Animation | Haptic |
|---------|-----------|--------|
| Segment switch | Crossfade | Light tap |
| Vibe indicator appear | Scale up + gradient spin | None |
| Pattern card appear | Slide in staggered | None |
| Streak milestone | Confetti burst | Success |
| Streak at risk | Pulsing border | Warning |
| Pull to refresh | Standard iOS | None |

---

## 7. Files Summary

| File | Action | Description |
|------|--------|-------------|
| MainTabView.swift | NEW | Tab navigation container |
| DashboardView.swift | NEW | Dashboard shell with segmented control |
| TodayView.swift | NEW | Today's metabolic status |
| WeekView.swift | NEW | Weekly trends + patterns |
| MonthView.swift | NEW | Calendar + streaks |
| MetabolicVibeIndicator.swift | NEW | Qualitative tier display |
| MacroBreakdownRing.swift | NEW | Macro donut chart |
| WeeklyBarChart.swift | NEW | 7-day bar chart |
| PatternCard.swift | NEW | Behavioral pattern display |
| TrendRow.swift | NEW | Week-over-week comparison |
| MetabolicCalendar.swift | NEW | Monthly heat map |
| StreakCard.swift | NEW | Streak tracking |
| ChronicInsightCard.swift | NEW | Long-term insights |
| DashboardDataService.swift | NEW | Aggregation logic |
| DashboardModels.swift | NEW | Summary data structures |
| ContentView.swift | MODIFY | Use MainTabView |
| TimelineView.swift | MODIFY | Accept external date |

---

## 8. Verification Plan

### Build Verification
- [ ] Build succeeds with no errors
- [ ] No SwiftUI preview crashes

### Functional Testing
- [ ] Tab navigation works (Timeline ↔ Dashboard)
- [ ] Today view shows correct calories/macros
- [ ] Metabolic vibe updates based on insights
- [ ] Week chart displays 7 days of data
- [ ] Pattern cards show detected patterns with suggestions
- [ ] Trend rows show week-over-week comparison
- [ ] Month calendar tapping switches tab + scrolls Timeline
- [ ] Streaks count correctly
- [ ] Streak at-risk state triggers visual pulse

### Empty States  
- [ ] Day 0: Hungry Monch + CTA to log
- [ ] Week with < 7 days: Ghosted bars + progress message
- [ ] Month with < 14 days: Ghosted calendar + baseline message

### Accessibility
- [ ] VoiceOver reads all components correctly
- [ ] Dynamic Type scales appropriately
- [ ] High contrast mode works

### Dark Mode
- [ ] All components tested in dark mode
- [ ] Gradients adapt correctly
- [ ] Calendar colors visible

---

## 9. Estimated Effort (Revised)

| Phase | Effort | Notes |
|-------|--------|-------|
| Phase 1: Tab Navigation | S (1h) | |
| Phase 2: Today View | M (4h) | +1h for vibe system |
| Phase 3: Week View | M (4h) | +1h for trend rows |
| Phase 4: Month View | M (4h) | +1h for streak risk |
| Phase 5: Data Services | M (3h) | +1h for pattern detection |
| Phase 6: Integration | S (1h) | |
| **Total** | **~17h** | |
