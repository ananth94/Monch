# Sprint 11 Task Checklist

## Phase 1: River UI
- [ ] Create `RiverSplineView.swift` with Canvas-based spline
- [ ] Implement Catmull-Rom interpolation for smooth curves
- [ ] Add mood-based gradient stroke
- [ ] Integrate into `TimelineView` as background layer
- [ ] Optional: Add subtle breathing animation

---

## Phase 2: Pattern Drill-Down
- [ ] Create `PatternDetailView.swift` modal
- [ ] Add linked entry IDs to `Pattern` struct
- [ ] Make pattern cards tappable in `WeekView`
- [ ] Display mini-timeline of affected entries
- [ ] Add "Set Goal" button (deferred action for now)

---

## Phase 3: Streak Celebrations
- [ ] Create `StreakTracker.swift` service
- [ ] Implement streak calculation logic
- [ ] Create `StreakCelebrationView.swift` with confetti
- [ ] Add milestone detection (7, 14, 30 days)
- [ ] Handle streak breaks with "Start Fresh" message
- [ ] Integrate into `ContentView` on app launch

---

## Deferred to Sprint 12+
- [ ] End-of-Day Summary notification
- [ ] Notification deep-linking to insights
- [ ] Pull-to-refresh on Timeline
- [ ] Recent/frequent foods in search
- [ ] Full Accessibility Audit
