# Decision Register

## 2026-04-19: Reposition Monch away from first-party food logging

### Context

Monch currently contains a substantial food-search and meal-construction workflow built around Open Food Facts, cart aggregation, and macro-heavy meal records. The product direction is shifting toward a metabolic intelligence layer focused on timing, context, biometrics, and interpretation.

### Options considered

1. Keep building first-party food logging as a core workflow.
2. Remove all food-related user input and rely entirely on external sources.
3. Keep lightweight metabolic event capture while de-emphasizing first-party food logging.

### Tradeoffs

Option 1 preserves structured nutrition detail but creates ongoing maintenance burden around poor data quality, search UX, and low-differentiation work.

Option 2 creates a cleaner product boundary but makes Monch too dependent on outside logging completeness and risks an empty-feeling app when external nutrition data is sparse.

Option 3 reduces friction and maintenance while preserving enough first-party signal for timing- and context-driven insights.

### Decision

Adopt option 3.

Monch will:

- treat meal timing as the source of "late meal" semantics
- de-scope supplements from the core product
- treat caffeine and alcohol as event-based inputs instead of quantified inputs
- use custom Monch icons wherever those assets already exist, reserving SF Symbols for utility UI

### Rationale

This keeps Monch focused on its moat: interpretation, pattern detection, and emotionally distinctive UX. It also avoids over-investing in food-database quality problems that are not core to the product's value.

## 2026-04-20: Infer HealthKit meal counts from nutrition quantities only

### Context

Monch now uses HealthKit data to improve dashboard meal counts. An initial implementation attempted to read `HKCorrelationTypeIdentifierFood`, but HealthKit disallows third-party read authorization for that type and crashes the app during authorization.

### Options considered

1. Keep using food correlations and try to special-case the authorization path.
2. Remove HealthKit-backed meal counts entirely.
3. Infer meal counts from allowed nutrition quantity samples only.

### Tradeoffs

Option 1 is not viable because the type is disallowed for read authorization. Option 2 avoids complexity but regresses the dashboard back to Monch-only meal counts. Option 3 is less precise than true meal correlations, but it is safe, uses supported HealthKit types, and preserves the product benefit of HealthKit-aware meal counting.

### Decision

Adopt option 3.

HealthKit-backed meal signals will be inferred by clustering timestamps from allowed nutrition quantity samples such as dietary energy, carbs, protein, and fat. In the timeline, these appear as read-only imported meal events rather than being persisted as local `MealLog` records.

### Rationale

This removes a launch-time crash while preserving the intended dashboard behavior. If we need more accurate cross-app meal modeling later, we can design a fuller nutrition-ingestion path on top of supported HealthKit primitives rather than relying on disallowed correlation reads.
