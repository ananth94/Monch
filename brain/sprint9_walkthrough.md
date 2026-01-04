# Sprint 9 Walkthrough: Dashboard View & Advanced Data Intelligence

## Summary

Sprint 9 introduces the comprehensive Dashboard system to Monch, providing users with Today, Week, and Month-level summaries of their metabolic health. This includes qualitative "vibe" indicators, behavioral pattern detection, and streak motivation.

---

## Changes

### New Files

| File | Purpose |
|------|---------|
| `DashboardModels.swift` | Data structures for summaries, tiers, patterns, and streaks |
| `DashboardView.swift` | Main shell for the Dashboard tab |
| `TodayView.swift` | Daily summary with vibe and quick stats |
| `WeekView.swift` | 7-day trends and pattern cards |
| `MonthView.swift` | Metabolic calendar and streaks |
| `MetabolicVibeIndicator.swift` | Animated qualitative vibe ring |
| `WeeklyBarChart.swift` | Stacked macro distribution chart |
| `MetabolicCalendar.swift` | Monthly heat map of metabolic tiers |
| `StreakCard.swift` | Motivational streak progress tracker |
| `PatternCard.swift` | Behavioral insight card with drill-down |

### Modified Files

| File | Changes |
|------|---------|
| `DashboardDataService.swift` | Added aggregation logic, pattern detection, and streak calculation |
| `MainTabView.swift` | Integrated Dashboard as the second primary tab |
| `ContentView.swift` | Updated root view to MainTabView |

---

## Features Implemented

### 🐹 Metabolic Vibe System
- Qualitative 5-tier system: **God Tier, Stable, Buzzed, Sluggish, Dysregulated**
- Animated gradient ring with emojis and encouraging copy
- Real-time updates based on current meal and insulin response data

### 📊 Multi-Scale Dashboards
- **Today View**: Real-time stats, current vibe, macro breakdown donut, and active insights list.
- **Week View**: 7-day stacked bar chart, week-over-week trends, and pattern cards.
- **Month View**: "Metabolic Calendar" heat map showing daily vibe quality and active streaks.

### 🧠 Pattern Detection
- **Weekend Wind-Down**: Detects late weekend meals disrupting recovery.
- **Post-Workout Refuel**: Validates positive glycemic responses after exercise.
- **Morning Rollercoaster**: Flags recurring morning sugar spikes.

### 🔥 Streak Tracking
- **Kitchen Closed**: Days without eating after 9 PM.
- **Spike-Free**: Days without metabolic dysregulation.
- **Personal Bests**: Real-time query of historical maximums.
- **At-Risk Alerts**: Visual pulsing when a streak is currently in jeopardy (e.g., nearing 9 PM).

---

## Verification
- ✅ Build succeeds
- ✅ Real-time data aggregation verified with SwiftData
- ✅ Navigation wired between Dashboard and Timeline

---

## Pull Request
**[PR #17: Sprint 9 PR #1: Dashboard Foundation](https://github.com/ananth94/Monch/pull/17)**
**[PR #18: Sprint 9 PR #2: Week & Month Views with Patterns & Streaks](https://github.com/ananth94/Monch/pull/18)**
