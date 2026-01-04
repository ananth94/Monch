# UX Gap Analysis: Current Implementation vs. Specs

## Summary
Evaluated against `User Scenarios`, `Design_System.md`, and `Timeline_Cards_UX.md`.

---

## ✅ Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| HealthKit Permissions | ✅ | Prompt on launch, re-enable banner |
| Food Search (OpenFoodFacts) | ✅ | Debounced, with cart + quantity |
| Quick-Add Buttons | ⚠️ | 4 buttons, not personalized |
| Unified Timeline | ✅ | LazyVStack, day headers |
| Meal Cards (timeline row) | ✅ | Basic display |
| Mascot Header | ✅ | 7 moods, animations |
| Mascot Detail Sheet | ✅ | Coaching, quick actions |
| Insight Engine | ✅ | Sugar Spike, Digestion Debt |
| Empty State | ✅ | Animated hungry Monch |

---

## ❌ Functional Gaps (from User Scenarios)

| Priority | Gap | Description |
|----------|-----|-------------|
| **P0** | Mascot Mood Wiring | Hardcoded; needs real InsightEngine data |
| **P1** | Workout Display | Fetched but not shown on timeline |
| **P1** | Sleep Display | Fetched but not shown on timeline |
| **P1** | Swipe-to-Delete | No timeline item correction |
| **P1** | Vibe Check | No subjective logging |
| **P1** | Symptom Tagging | No "Jittery"/"Racing" logging |
| **P2** | Barcode Scan | Camera UI not built |
| **P2** | Summary Views | Day/Week/Month not built |
| **P2** | Notifications | Kitchen Closing, Refeed nudges |

---

## ❌ Timeline Cards Gaps (from Timeline_Cards_UX.md)

### Card Types Required
| Card | Status | Spec Reference |
|------|--------|----------------|
| **FoodCard** | ❌ NOT BUILT | Serving size editor, macros/micros, delete |
| **SleepCard** | ❌ NOT BUILT | Duration, quality, stage viz, context |
| **ExerciseCard** | ❌ NOT BUILT | Type, duration, HR zones, anabolic window |
| **InsightCard** | ⚠️ PARTIAL | Displays but no linked entries, no quick actions |
| **SubjectiveCard** | ❌ NOT BUILT | Energy/Focus/Mood sliders, symptom tags |

### Shared Shell Requirements
| Element | Required | Current |
|---------|----------|---------|
| Sheet presentation | `.sheet` slide up | ✅ |
| 24pt corner radius | `CornerRadius.xl` | ❌ Using 12pt |
| Timestamp + context tag | Required | ❌ Missing |
| Delete action | Destructive sheet | ❌ No delete |
| Edit/Save button | Per card type | ❌ Missing |

---

## 🎨 River UI Visual Gaps (from Design_System.md)

| Aspect | Specified | Current |
|--------|-----------|---------|
| Card corners | 24pt radius | 12pt |
| Icons | Hand-drawn/watercolor | SF Symbols |
| Insight Cards | Speech bubble from mascot | Colored rectangles |
| Background | Watercolor/paper texture | `.ultraThinMaterial` |

---

## Sprint Roadmap (Updated)

| Sprint | Focus | Key Deliverables |
|--------|-------|------------------|
| **5** | **Timeline Cards Shell** | Shared CardShell, FoodCard detail view |
| **6** | **Data Visibility** | SleepCard, ExerciseCard on timeline |
| **7** | **Subjective Logging** | SubjectiveCard, Vibe Check, Symptoms |
| **8** | **Insight Enhancement** | InsightCard with linked entries, quick actions |
| **9** | **River UI Polish** | 24pt cards, watercolor icons, speech bubbles |
| **10** | **Summaries** | Day/Week/Month aggregate views |

---

## Priority Matrix

```
              HIGH IMPACT
                  │
    ┌─────────────┼─────────────┐
    │  FoodCard   │  SleepCard  │
    │  ExerciseCd │  SubjectCd  │
────┼─────────────┼─────────────┼────
LOW │             │ River UI    │ HIGH
EFFORT            │ Summaries   │ EFFORT
    │ Quick-Add   │ Barcode     │
    │ personalize │ Notifs      │
    └─────────────┼─────────────┘
                  │
              LOW IMPACT
```

---

## Verdict
**Next Priority: Sprint 5 — Timeline Cards Shell + FoodCard**  
Build the shared CardDetailShell and FoodCard first (highest usage), then add Sleep/Exercise visibility.
