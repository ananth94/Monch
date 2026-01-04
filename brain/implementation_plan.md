# Sprint 5: Timeline Cards Shell + FoodCard

## Goal
Build reusable card detail shell and implement FoodCard for editing/viewing logged meals.

---

## Proposed Changes

### 1. Shared Card Shell
#### [NEW] `monch/Views/Cards/CardDetailShell.swift`
Reusable container for all card types per `Timeline_Cards_UX.md`:

```swift
struct CardDetailShell<Content: View>: View {
    let title: String
    let icon: String
    let timestamp: Date
    let contextTag: String?
    let primaryAction: (() -> Void)?
    let primaryActionLabel: String
    let onDelete: (() -> Void)?
    @ViewBuilder let content: () -> Content
}
```

**Design Tokens:**
- Corner radius: 24pt (`CornerRadius.xl`)
- Background: `cream` / `warmCharcoal`
- Padding: 16pt

---

### 2. FoodCard Detail View
#### [NEW] `monch/Views/Cards/FoodCardView.swift`

**Features:**
- View/edit meal details
- Serving size multiplier (0.5, 1, 1.5, 2)
- Live macro recalculation
- Expandable micronutrients section
- Delete with confirmation

**Layout (from spec):**
```
┌─────────────────────────────────────┐
│  ← Back                       Save  │
├─────────────────────────────────────┤
│  🍽️ [Meal Name]                     │
│  [Time] • [Context Tag]             │
├─────────────────────────────────────┤
│  Serving Size: [stepper]            │
├─────────────────────────────────────┤
│  📊 MACROS                          │
│  Calories / Carbs / Protein / Fat   │
│  ▼ Micronutrients (expandable)     │
├─────────────────────────────────────┤
│  [ Delete Entry ]                   │
└─────────────────────────────────────┘
```

---

### 3. Timeline Integration
#### [MODIFY] `monch/Views/Timeline/TimelineView.swift`
- Add `@State private var selectedMeal: MealLog?`
- Make MealCard rows tappable → open FoodCardView sheet
- Handle delete callback to remove from SwiftData

---

### 4. Design System Updates
#### [MODIFY] `monch/DesignSystem/Spacing.swift`
- Add `CornerRadius.xl = 24` if not present

---

## Files Changed
| File | Action |
|------|--------|
| `CardDetailShell.swift` | NEW |
| `FoodCardView.swift` | NEW |
| `TimelineView.swift` | MODIFY |
| `Spacing.swift` | MODIFY |

---

## Verification Plan

### Build Test
```bash
xcodebuild -scheme monch build
```

### Manual Test
1. Log a meal via food search
2. Tap meal on timeline → FoodCardView opens
3. Adjust serving size → macros recalculate
4. Tap Delete → confirm → meal removed from timeline
