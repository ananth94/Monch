# Dashboard & Insights View — UX Spec

## Overview
The Dashboard is the **"Metabolic Status Hub"** that surfaces insights, patterns, and summaries across three time horizons: Today, Week, and Month.

---

## 1. Navigation Structure

```
┌──────────────────────────────────────┐
│  [ Today ]  [ Week ]  [ Month ]      │  ← Segmented control
└──────────────────────────────────────┘
```

User can swipe horizontally or tap segments to switch views.

---

## 2. Today View (The Daily Pulse)

**Purpose:** Real-time metabolic status and today's insights.

### Layout
```
┌──────────────────────────────────────┐
│  🐊 MONCH HEADER                     │  ← Current state (tap to expand)
│  "Monch is buzzing • Sugar spike"    │
├──────────────────────────────────────┤
│                                      │
│  📊 TODAY'S METABOLIC SCORE          │
│  ┌────────────────────────────┐      │
│  │         78 / 100           │      │  ← Overall score
│  │    ████████████░░░░        │      │
│  └────────────────────────────┘      │
│                                      │
│  Quick Stats:                        │
│  🍽️ 1,420 kcal  │  😴 7h 12m        │
│  🏃 Zone 2 35m  │  💧 4 glasses      │
│                                      │
├──────────────────────────────────────┤
│  💡 TODAY'S INSIGHTS                 │
│                                      │
│  ┌────────────────────────────┐      │
│  │ 🔥 Sugar Spike • 2:45pm    │      │  ← Tap to open InsightCard
│  │ "Post-lunch spike detected" │      │
│  └────────────────────────────┘      │
│                                      │
│  ┌────────────────────────────┐      │
│  │ 💪 Muscle Sponge • 8:15am  │      │
│  │ "Anabolic window used!"    │      │
│  └────────────────────────────┘      │
│                                      │
├──────────────────────────────────────┤
│  🥧 MACRO BREAKDOWN                  │
│  ┌────────────────────────────┐      │
│  │    [Ring Chart]            │      │  ← Carbs/Protein/Fat
│  │  C: 52%  P: 28%  F: 20%    │      │
│  └────────────────────────────┘      │
│                                      │
└──────────────────────────────────────┘
```

### Scenarios
| Scenario | Behavior |
|----------|----------|
| No data yet | Empty state with Monch prompting first log |
| Active insight | Insight card pulses gently |
| Tap insight | Opens full InsightCard sheet |
| Tap macro ring | Expands to detailed nutrient breakdown |

---

## 3. Week View (Pattern Recognition)

**Purpose:** Spot behavioral patterns across 7 days.

### Layout
```
┌──────────────────────────────────────┐
│  📈 WEEKLY TRENDS                    │
│                                      │
│  ┌────────────────────────────┐      │
│  │ M  T  W  T  F  S  S        │      │
│  │ █  █  █  █  ▄  ░  █        │      │  ← 7-day bar chart
│  │ ▄  ▄  █  ▄  █  █  ▄        │      │    (macro distribution)
│  └────────────────────────────┘      │
│                                      │
│  Compared to last week:              │
│  ↓ Carbs 12%  │  ↑ Protein 8%       │
│                                      │
├──────────────────────────────────────┤
│  🔁 PATTERN CARDS                    │
│                                      │
│  ┌────────────────────────────┐      │
│  │ 🌙 Late Meals               │      │
│  │ "Detected Fri & Sat"        │      │
│  │ Impact: -15% Deep Sleep     │      │
│  └────────────────────────────┘      │
│                                      │
│  ┌────────────────────────────┐      │
│  │ 💪 Refeed Timing            │      │
│  │ "Improved vs last week!"    │      │
│  │ 4/5 workouts fueled well    │      │
│  └────────────────────────────┘      │
│                                      │
├──────────────────────────────────────┤
│  💡 WEEK'S TOP INSIGHTS              │
│  • 3 Sugar Spikes (↓ from 5)        │
│  • 2 Anabolic Windows Used          │
│  • 1 Digestion Debt                  │
│                                      │
└──────────────────────────────────────┘
```

### Scenarios
| Scenario | Behavior |
|----------|----------|
| < 7 days data | Ghosted bars + "Keep logging" prompt |
| Tap pattern card | Drills into linked entries |
| Swipe chart | Navigates to previous weeks |

---

## 4. Month View (The Long Game)

**Purpose:** Long-term trends, streaks, and chronic insights.

### Layout
```
┌──────────────────────────────────────┐
│  📅 METABOLIC CALENDAR               │
│  ┌────────────────────────────┐      │
│  │  1  2  3  4  5  6  7       │      │
│  │  🟢🟢🟡🟢🟢🔴🟢              │      │  ← Heat map
│  │  8  9 10 11 12 13 14       │      │    (green=good, red=poor)
│  │  🟢🟢🟢🟡🟢🟢🟡              │      │
│  │  ...                       │      │
│  └────────────────────────────┘      │
│                                      │
├──────────────────────────────────────┤
│  🔥 STREAKS                          │
│  ┌────────────────────────────┐      │
│  │ 🌙 18 days                  │      │
│  │ No late-night eating        │      │
│  └────────────────────────────┘      │
│  ┌────────────────────────────┐      │
│  │ 💪 12 days                  │      │
│  │ Post-workout refueling      │      │
│  └────────────────────────────┘      │
│                                      │
├──────────────────────────────────────┤
│  🔬 CHRONIC INSIGHTS                 │
│                                      │
│  ┌────────────────────────────┐      │
│  │ ⚠️ Mineral Gap              │      │
│  │ "HRV consistently rigid.    │      │
│  │  Consider Magnesium?"       │      │
│  └────────────────────────────┘      │
│                                      │
│  ┌────────────────────────────┐      │
│  │ 📈 Brain Fog Predictor      │      │
│  │ "High sugar variability     │      │
│  │  correlates with foggy AM"  │      │
│  └────────────────────────────┘      │
│                                      │
└──────────────────────────────────────┘
```

### Scenarios
| Scenario | Behavior |
|----------|----------|
| Tap calendar day | Jumps to that day's Timeline |
| Streak at risk | Warning glow on streak card |
| Chronic insight | Links to educational content |

---

## 5. The Four Metabolic Loops

Each insight is color-coded by its loop:

| Loop | Color | Icon | Example Insights |
|------|-------|------|------------------|
| **Acute** | 🍑 Coral | ⚡ | Sugar Spike, Lipid Load, Caffeine Jitter |
| **Recovery** | 🌿 Sage | 💪 | Muscle Sponge, Good Spike, Zone 2 Drain |
| **Sleep** | 🔮 Periwinkle | 😴 | Digestion Debt, Deep Sleep Robber |
| **Chronic** | ⚪ Neutral | 🔬 | Mineral Gap, Brain Fog, Stress Buffer |

---

## 6. Empty States

| View | Days of Data | Display |
|------|--------------|---------|
| Today | 0 | Hungry Monch + "Log your first meal" |
| Week | < 7 | Partial chart + "Patterns emerge after 7 days" |
| Month | < 14 | Ghosted calendar + "Building your baseline..." |

---

## 7. Interactions

| Action | Result |
|--------|--------|
| Tap Monch header | Opens full MonchView sheet |
| Tap insight card | Opens InsightCard with details |
| Tap macro ring | Expands nutrient breakdown |
| Tap calendar day | Navigates to that day's Timeline |
| Swipe horizontally | Changes time period (week ↔ week) |
| Pull to refresh | Updates with latest HealthKit data |

---

## 8. Design Tokens

| Element | Token |
|---------|-------|
| Background | `cream` / `midnightNavy` |
| Card Background | `warmCharcoal` (dark) / white (light) |
| Score Ring | Gradient based on score |
| Insight Card Border | Loop color at 30% opacity |
| Bar Chart Colors | Macro colors (Coral/Sage/Periwinkle) |
