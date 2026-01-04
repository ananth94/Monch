# Timeline Entry Cards — UX Spec

## Overview
Every entry on the Timeline opens a **detail card** when tapped. Cards share a consistent shell but display content specific to the entry type.

---

## 1. Shared Card Shell

All cards use this structure:

```
┌─────────────────────────────────────┐
│  ← Back                   [Primary] │  ← Action button (Save/Edit/Done)
├─────────────────────────────────────┤
│  [Icon] [Title]                     │
│  [Timestamp] • [Context Tag]        │
├─────────────────────────────────────┤
│                                     │
│      [ TYPE-SPECIFIC CONTENT ]      │
│                                     │
├─────────────────────────────────────┤
│  [ Delete ]                         │  ← Destructive action
└─────────────────────────────────────┘
```

### Design Tokens
| Element | Token |
|---------|-------|
| Background | `cream` / `warmCharcoal` |
| Corner Radius | `CornerRadius.xl` (24pt) |
| Padding | `Spacing.md` (16pt) |
| Title Font | `MonchFont.title2` |
| Timestamp Font | `MonchFont.subheadline` |

---

## 2. Card Types

### 🍽️ FoodCard

**Trigger:** Tap any meal bubble on Timeline

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back                       Save  │
├─────────────────────────────────────┤
│  🍽️ Oatmeal with Banana            │
│  8:32am • 🍞 High Carb              │
├─────────────────────────────────────┤
│  Serving Size                       │
│  [ 1.5 ] [ cup (240ml) ▼ ]         │
│  [ ½ ] [ 1 ] [ 1.5 ] [ 2 ]         │
├─────────────────────────────────────┤
│  📊 MACROS                          │
│  Calories         350 kcal          │
│  Total Carbs       52g              │
│   └─ Fiber         6g               │
│   └─ Sugars        18g              │
│  Protein           12g              │
│  Total Fat          8g              │
│                                     │
│  ▼ Micronutrients                   │
│  Caffeine    0mg  │  Sodium  150mg  │
│  Magnesium  48mg  │  Iron    1.5mg  │
│  Zinc      1.2mg  │                 │
├─────────────────────────────────────┤
│  [ Delete Entry ]                   │
└─────────────────────────────────────┘
```

**Scenarios:**
| Scenario | Behavior |
|----------|----------|
| Add new food | Card opens empty, user searches/scans |
| Barcode scan | Card pre-fills from product database |
| Edit existing | Card pre-fills from saved entry |
| Quantity change | All nutrients recalculate live |

---

### 😴 SleepCard

**Trigger:** Tap sleep summary on Timeline

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back                       Edit  │
├─────────────────────────────────────┤
│  😴 Last Night's Sleep              │
│  11:15pm → 6:47am                   │
├─────────────────────────────────────┤
│  Duration          7h 32m           │
│  Quality Score     78%              │
├─────────────────────────────────────┤
│  📊 STAGES                          │
│  ┌─────────────────────────────┐    │
│  │ Deep   ████░░░░░░  18%      │    │
│  │ REM    ██████░░░░  24%      │    │
│  │ Light  ████████░░  42%      │    │
│  │ Awake  ██░░░░░░░░  16%      │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  💡 CONTEXT                         │
│  "Late meal (10pm) may have         │
│   reduced Deep Sleep by 12%"        │
├─────────────────────────────────────┤
│  [ Adjust Times ]                   │
└─────────────────────────────────────┘
```

**Scenarios:**
| Scenario | Behavior |
|----------|----------|
| Morning review | Card shows last night's summary |
| Tap for detail | Hypnogram visualization expands |
| Data correction | User adjusts wake/sleep times |
| Linked insight | Shows connection to late meals |

---

### 🏃 ExerciseCard

**Trigger:** Tap workout bubble on Timeline

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back                       Edit  │
├─────────────────────────────────────┤
│  🏃 Morning Run                     │
│  6:45am • 💪 Zone 2                 │
├─────────────────────────────────────┤
│  Type             Outdoor Run       │
│  Duration         35 min            │
│  Distance         5.2 km            │
│  Calories         320 kcal          │
├─────────────────────────────────────┤
│  ❤️ HEART RATE                      │
│  Avg    142 bpm                     │
│  Max    168 bpm                     │
│  ┌─────────────────────────────┐    │
│  │ Zone 1 ██░░░░░░  12%        │    │
│  │ Zone 2 ████████  68%        │    │
│  │ Zone 3 ████░░░░  20%        │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  💡 CONTEXT                         │
│  "Anabolic Window open for 2h.      │
│   Carbs will fuel muscle now."      │
├─────────────────────────────────────┤
│  [ Delete ]                         │
└─────────────────────────────────────┘
```

**Scenarios:**
| Scenario | Behavior |
|----------|----------|
| Auto-sync from Watch | Card pre-filled, read-only |
| Manual entry | User selects type, estimates duration/RPE |
| Post-workout context | Shows "Anabolic Window" status |
| Refeed tagging | Next meal auto-tagged if within window |

---

### 💡 InsightCard

**Trigger:** Tap insight badge on Timeline

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back                             │
├─────────────────────────────────────┤
│  💡 Sugar Spike Detected            │
│  2:45pm • 🔶 Moderate               │
├─────────────────────────────────────┤
│  Your heart rate spiked +18bpm      │
│  30 minutes after lunch.            │
│                                     │
│  A 10-minute walk now could         │
│  flatten the curve.                 │
├─────────────────────────────────────┤
│  🔗 LINKED ENTRIES                  │
│  ┌───────────────────────────┐      │
│  │ 🍽️ Pasta Lunch • 2:15pm  │──────│
│  └───────────────────────────┘      │
├─────────────────────────────────────┤
│  ⚡ QUICK ACTIONS                    │
│  [ Start Walk ]  [ Log Snack ]      │
├─────────────────────────────────────┤
│  [ Dismiss ]                        │
└─────────────────────────────────────┘
```

**Scenarios:**
| Scenario | Behavior |
|----------|----------|
| Sugar Spike | Links to recent carb-heavy meal |
| Anxiety Mimic | Offers reassurance + snack action |
| Kitchen Closing | Links to upcoming bedtime |
| Refeed Validation | Links to workout + meal |

---

### 🎭 SubjectiveCard

**Trigger:** Tap "Check-In" entry or add new

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Back                       Save  │
├─────────────────────────────────────┤
│  🎭 Afternoon Check-In              │
│  2:30pm                             │
├─────────────────────────────────────┤
│  How are you feeling?               │
│                                     │
│  Energy    [ ⚡ Low ] [ ⚡⚡ ] [ ⚡⚡⚡ ]│
│  Focus     [ ☁️ Fog ] [ 🎯 ] [ 🔥 ] │
│  Mood      [ 😔 ] [ 😐 ] [ 😊 ]      │
├─────────────────────────────────────┤
│  Symptoms (optional)                │
│  [ Jittery ] [ Heart Racing ]       │
│  [ Headache ] [ Bloated ]           │
├─────────────────────────────────────┤
│  [ Delete ]                         │
└─────────────────────────────────────┘
```

**Scenarios:**
| Scenario | Behavior |
|----------|----------|
| Post-meal check | Links to previous meal for correlation |
| Symptom logging | Triggers specific insight validation |
| Trend building | Used for "Vibe Forecast" over time |

---

## 3. Edge Cases

| Scenario | Handling |
|----------|----------|
| **Missing data** | Show "--" with "Add" button |
| **HealthKit unavailable** | Graceful fallback to manual entry |
| **Multi-item meal** | Aggregate into single FoodCard |
| **Overlapping entries** | Stack on timeline, each opens own card |
| **Historical edit** | Allow timestamp adjustment |
| **Delete confirmation** | Destructive action sheet |

---

## 4. Transitions

| Action | Animation |
|--------|-----------|
| Open card | `.sheet` slide up from bottom |
| Close card | Swipe down or tap Back |
| Save changes | Card dismisses + timeline updates |
| Delete | Card dismisses + entry removed with fade |
