# Open PR Review (#10-15)

**Date:** 2026-01-04  
**Total PRs:** 6

---

## Summary Table

| PR | Title | Files | +/- | Merge Status |
|----|-------|-------|-----|--------------|
| #10 | fix: delete insights when meal deleted | 2 | +99/-0 | ✅ Clean |
| #11 | fix: wire up mascot quick actions | 2 | +25/-2 | ✅ Clean |
| #12 | fix: delete confirmation dialog placement | 1 | +11/-11 | ✅ Clean |
| #13 | feat: meal type categorization | 4 | +71/-1 | ✅ Clean |
| #14 | feat: manual serving size adjustment | 1 | +18/-0 | ✅ Clean |
| #15 | feat: sleep efficiency and score context | 1 | +43/-4 | ✅ Clean |

---

## Individual Reviews

### #10: Delete Associated Insights
**Problem:** Insights persisted after deleting their source meal.  
**Fix:** Cascades delete to associated `InsightEvent` records; refreshes mascot mood.

✅ **Merge**

---

### #11: Mascot Quick Actions
**Problem:** Buttons on mascot detail view were stubs.  
**Fix:** Wired "Log Meal", "Quick Snack", "Log Protein" to food logger.

✅ **Merge**

---

### #12: Delete Dialog Placement
**Problem:** Confirmation dialog appeared at top of screen.  
**Fix:** Anchored to delete button for standard iOS bottom-sheet behavior.

✅ **Merge**

---

### #13: Meal Type Categorization
**Problem:** No way to categorize meals (Breakfast/Lunch/Dinner/Snack).  
**Fix:** Added `MealType` enum with time-based guesser and horizontal selector.

✅ **Merge**

---

### #14: Manual Serving Size
**Problem:** Limited to preset serving multipliers (0.5x, 1x, etc.).  
**Fix:** Added stepper for manual adjustment (e.g., 10+ items).

✅ **Merge**

---

### #15: Sleep Efficiency Context
**Problem:** Sleep quality score lacked explanation.  
**Fix:** Added info section explaining weighting (Efficiency, Deep Sleep, Duration).

✅ **Merge**

---

## Verdict

All 6 PRs are **ready to merge**. No conflicts detected.

**Recommended merge order:**  
#10 → #11 → #12 → #13 → #14 → #15  
(Fixes first, then features)
