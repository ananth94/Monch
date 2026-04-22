# Monch Intelligence Spec And Implementation Audit

## Purpose

This document consolidates the full intelligence surface that has been specced or implemented in Monch so far, then audits what is actually live in the app today.

The goal is to create one canonical reference for:
- all insight features ever promised in product/research docs
- all insight types currently modeled in code
- which detectors actually exist
- which detectors are truly wired into runtime flows
- which features are surfaced in UI and tested
- what should be built next, in what order

## Sources Reviewed

Primary sources used for this audit:
- [Insights_Library.md](../Insights_Library.md)
- [brain/sprint10_implementation_plan.md](../brain/sprint10_implementation_plan.md)
- [Dashboard_Insights_UX.md](../Dashboard_Insights_UX.md)
- [Timeline_Cards_UX.md](../Timeline_Cards_UX.md)
- [User Scenarios - Core Utility.md](../User%20Scenarios%20-%20Core%20Utility.md)
- [monch/Models/InsightEvent.swift](../monch/Models/InsightEvent.swift)
- [monch/Services/InsightEngine.swift](../monch/Services/InsightEngine.swift)
- [monchTests/InsightEngineTests.swift](../monchTests/InsightEngineTests.swift)

## Status Legend

- `Spec only`: described in product/research docs, but not represented in code
- `Modeled`: exists in `InsightType` or related model taxonomy
- `Detector exists`: detector logic exists in `InsightEngine`
- `Live-wired`: detector is called from a real app flow
- `UI surfaced`: current cards/views can render the insight
- `Tested`: has meaningful automated coverage
- `Dormant`: code exists, but no runtime invocation path was found

## Canonical Inventory

| Insight / Capability | Loop | Priority | Source of truth | Required signals | Current status | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Sugar Spike | Acute | P0 | `Insights_Library.md`, UX docs, code | Meal timing, carbs, HR baseline/spike, step gate | `Modeled`, `Detector exists`, `Live-wired`, `UI surfaced`, `Tested` | This is one of the clearest end-to-end implemented insights. |
| Muscle Sponge | Recovery | P0 | `Insights_Library.md`, sprint plan, code | Qualifying workout, post-workout meal timing/macros | `Modeled`, `Detector exists`, `Live-wired`, `UI surfaced`, `Partially tested` | Good core insight; tests cover qualifying workout thresholds more than full detector behavior. |
| Good Spike | Recovery | P0 | `Insights_Library.md`, sprint plan | Exercise context around carb-heavy meal | `Modeled` | Currently behaves more like suppression/context (`refeed`, exercise gating) than a standalone emitted insight. |
| Digestion Debt | Sleep / Circadian | P0 | `Insights_Library.md`, UX docs, code | Meal timing vs evening/night | `Modeled`, `Detector exists`, `Live-wired`, `UI surfaced`, `Tested` | Another fully live core insight. |
| Anxiety Mimic | Acute | P1 | `Insights_Library.md`, sprint plan, UX docs, code | Meal composition/timing, HR, symptom context | `Modeled`, `Detector exists`, `UI surfaced` | Detector exists, but no current runtime path calls it. Effectively `Dormant`. |
| Caffeine Jitter | Acute | P1 | `Insights_Library.md`, sprint plan, user scenarios, code | Caffeine events, HR, meal timing, symptoms | `Modeled`, `Detector exists`, `UI surfaced` | Detector exists, but no current runtime path calls it. Event-based caffeine logging now supports it conceptually, but orchestration is missing. |
| Zone 2 Drain | Recovery | P1 | `Insights_Library.md`, sprint plan, UX docs, code | Zone 2 workout + nearby meal/fueling context | `Modeled`, `Detector exists`, `UI surfaced` | Detector exists, but no current runtime path calls it. |
| Deep Sleep Robber | Sleep / Circadian | P1 | `Insights_Library.md`, sprint plan, UX docs, code | Sleep quality/deep sleep + late meal context | `Modeled`, `Detector exists`, `UI surfaced` | Only reachable through `runWeeklyChecks`, and no app invocation path for that was found. Effectively `Dormant`. |
| Lipid Load | Acute | P2 | `Insights_Library.md` | High-fat meal + delayed sluggishness markers | `Spec only` | Not represented in `InsightType` and no detector exists. |
| Metabolic Burn | Acute | P2 | `Insights_Library.md` | High-protein meal + thermogenic/HR response | `Spec only` | Not represented in `InsightType` and no detector exists. |
| Recovery Gap | Recovery | P2 | `Insights_Library.md`, code | Workout + under-fueling + HRV recovery | `Modeled`, `Detector exists`, `UI surfaced` | Detector exists, but no current runtime path calls it. |
| Tryptophan Trap | Sleep / Circadian | P2 | `Insights_Library.md` | Carb timing before bed + sleep onset quality | `Spec only` | Not represented in `InsightType` and no detector exists. |
| Brain Fog Forecast | Chronic | P2 | `Insights_Library.md`, user scenarios, code | Morning HRV / prior-day burden / subjective focus | `Modeled`, `Detector exists`, `UI surfaced` | Only reachable through `runMorningChecks`; no app invocation path found. Effectively `Dormant`. |
| Stress Buffer | Chronic | P2 | `Insights_Library.md`, code | Protein intake + HRV stability under stress | `Modeled`, `Detector exists`, `UI surfaced` | Only reachable through `runMorningChecks`; no app invocation path found. Effectively `Dormant`. |
| Mineral Gap | Chronic | P2 | `Insights_Library.md`, UX docs, user scenarios, code | Micronutrients (magnesium/zinc) + HRV trends | `Modeled`, `Detector exists`, `UI surfaced` | Only reachable through `runWeeklyChecks`; no app invocation path found. Effectively `Dormant`. |
| Morning Readiness | Daily HRV layer | Unranked in original library | code only | Morning HRV vs baseline | `Modeled`, `Detector exists`, `UI surfaced` | Not in the original 15-insight library; part of a newer HRV expansion. Only reachable through `runMorningChecks`, which appears unwired. |
| Meal Impact Score | Meal stress layer | Unranked in original library | code only | Meal timing + post-meal HRV change | `Modeled`, `Detector exists`, `UI surfaced` | Detector exists, but no runtime path calls it. |
| Alcohol Impact | Daily HRV layer | Unranked in original library | code only | Alcohol events + overnight HRV suppression | `Modeled`, `Detector exists`, `UI surfaced` | Only reachable through `runMorningChecks`, which appears unwired. |
| Fasting Benefit | Daily HRV layer | Unranked in original library | code only | Fasting window + HRV improvement | `Modeled`, `Detector exists`, `UI surfaced` | Only reachable through `runMorningChecks`, which appears unwired. |

## Supporting Intelligence Systems

These are not standalone insights, but they are part of the broader intelligence story and affect how the product behaves.

| Capability | Current status | Notes |
| --- | --- | --- |
| Context tagging (`autoTags`, exercise/refeed semantics) | `Implemented`, `Live-wired` | Used before meal detection; this is foundational for suppressing or shaping insights. |
| Mascot mood mapping | `Implemented`, `Live-wired`, `Partially tested` | Mood updates from recent meals and insights are active today. |
| Imported HealthKit meal inference | `Implemented`, `Live-wired` | HealthKit nutrition samples now improve timeline/dashboard context, but most insight detectors still reason mainly over local `MealLog` records. |
| Vibe / subjective symptom support | `Partially implemented` | Product docs expect Vibe/symptom input to help disambiguate states like Anxiety Mimic vs Caffeine Jitter, but the current detector orchestration does not make strong runtime use of this yet. |
| Pattern / chronic insight surfaces in dashboard UX | `Specced`, `Partially surfaced` | The dashboard can render insight cards and summaries, but the full chronic/pattern loop described in UX docs is not consistently backed by live detector output. |

## What Is Actually Live Today

### End-to-end live insights

These currently have the strongest end-to-end path from data -> detector -> persistence -> UI:
- Sugar Spike
- Muscle Sponge
- Digestion Debt

### Implemented but dormant insights

These have real detector logic in `InsightEngine`, but I could not find a runtime invocation path in the app:
- Anxiety Mimic
- Caffeine Jitter
- Zone 2 Drain
- Recovery Gap
- Meal Impact Score
- Morning Readiness
- Brain Fog Forecast
- Alcohol Impact
- Fasting Benefit
- Stress Buffer
- Deep Sleep Robber
- Mineral Gap

The biggest reason this matters: `runMorningChecks` and `runWeeklyChecks` exist in [InsightEngine.swift](../monch/Services/InsightEngine.swift), but no app code currently appears to call them.

### Spec-only insights

These remain research/product ideas rather than current implementation work:
- Lipid Load
- Metabolic Burn
- Tryptophan Trap

### Ambiguous / partially realized insight

`Good Spike` is important conceptually, but today it mostly exists as suppression logic and context tagging rather than a clearly emitted insight card with its own detector lifecycle.

## Gaps Between Spec And Implementation

### 1. Taxonomy drift

The intelligence library, the code model, and the UX docs are no longer perfectly aligned.

Examples:
- original spec includes `Lipid Load`, `Metabolic Burn`, and `Tryptophan Trap`, but code does not model them
- code includes newer HRV-layer insights (`Morning Readiness`, `Meal Impact Score`, `Alcohol Impact`, `Fasting Benefit`) that are not part of the original 15-insight library
- `Good Spike` exists in model language but not as a cleanly emitted detector path

### 2. Detector-orchestration gap

There is a meaningful difference between "detector exists" and "feature is implemented."

Right now, several insights are implemented as methods but are not triggered from any user or scheduled flow. That creates a false sense of completeness if we only look at code presence.

### 3. Validation gap

Automated coverage is still concentrated around the original MVP core:
- Sugar Spike
- Digestion Debt
- parts of Muscle Sponge
- mascot mood mapping

There is little or no meaningful automated validation for the broader HRV and chronic insight layer.

### 4. Data-shape mismatch after the event-based pivot

Monch has shifted away from quantified first-party food logging, but a number of insight concepts still assume richer nutrition precision or more consistent nutrient detail than the app now guarantees locally.

This matters especially for:
- Caffeine Jitter
- Recovery Gap
- Stress Buffer
- Mineral Gap
- Meal Impact Score

Some of these can still work, but they now need clearer fallback logic for:
- HealthKit nutrition present
- event/timing context only
- biometrics + subjective input only

### 5. UX promise exceeds detector reliability

The dashboard and timeline UX docs describe:
- chronic patterns
- trend counts
- linked drivers
- drill-down explanations
- confidence-rich coaching

The current engine is not yet producing that breadth and consistency of output. The UI surfaces are ahead of the runtime intelligence layer.

## Main Options From Here

### Option 1: Keep adding new insight detectors from the library

This is tempting because the research is already done, but it would increase taxonomy drift and technical debt if runtime orchestration and validation stay weak.

Best when:
- the goal is breadth of demos quickly

Main risk:
- more "implemented but not truly live" features

### Option 2: First align and activate the existing detector inventory

This means:
- deciding which insight list is canonical
- wiring dormant detectors into real flows
- adding tests and fallback logic
- only then adding spec-only insights

Best when:
- the goal is a trustworthy intelligence layer that can keep improving without being rewritten

Main tradeoff:
- slower visible breadth at first, but much better long-term maintainability and product honesty

### Option 3: Narrow the product to a smaller intelligence v1

This means explicitly choosing a small set of loops to support really well and deferring the rest.

Best when:
- the goal is near-term product quality and user trust

Main tradeoff:
- strongest user experience and validation quality, but some previously specced ideas stay on the shelf longer

## Recommended Approach

Recommend a hybrid of **Option 2** and **Option 3**:
- first align the runtime around the insights Monch already claims most strongly
- then finish a smaller intelligence v1 before adding new spec-only features

### Recommended intelligence v1 scope

Focus first on the loops that are both high-value and realistically supportable with Monch's current data model:
- Sugar Spike
- Muscle Sponge
- Digestion Debt
- Anxiety Mimic
- Caffeine Jitter
- Zone 2 Drain
- Deep Sleep Robber
- Recovery Gap

Why this is the best default:
- these are the clearest user-facing loops in the research docs
- most are already modeled or partially implemented
- they map well to Monch's current event + HealthKit posture
- they create a coherent story around energy, exercise, sleep, and timing
- they are easier to explain and validate than the broader chronic HRV layer

### What to defer until after v1 stabilization

Defer until orchestration and validation are stronger:
- Lipid Load
- Metabolic Burn
- Tryptophan Trap
- Brain Fog Forecast
- Stress Buffer
- Mineral Gap
- Morning Readiness
- Meal Impact Score
- Alcohol Impact
- Fasting Benefit

This does not mean abandoning them. It means treating them as phase 2, after the engine has a reliable runtime backbone.

## Proposed Implementation Plan

### Phase 0: Canonical alignment

Goal:
- decide which intelligence inventory is canonical

Recommended action:
- treat this document as the working canonical inventory
- keep the original `Insights_Library.md` as research source material
- classify each insight in code/docs as `live`, `dormant`, `planned`, or `deferred`

Validation:
- one canonical checklist exists and matches current code reality

### Phase 1: Runtime orchestration pass

Goal:
- make detector wiring honest and explicit

Work:
- decide where morning checks run
- decide where weekly checks run
- wire or remove dormant detector paths intentionally
- define one orchestration layer for meal-triggered, workout-triggered, morning, and weekly insights

Files likely involved:
- `monch/Services/InsightEngine.swift`
- `monchApp.swift`
- timeline/dashboard entry points that currently trigger analysis

Validation:
- manual verification that each invoked path actually persists insights
- automated tests for orchestration entry points

### Phase 2: Finish the P1 loop set

Goal:
- complete the strongest user-facing insights already specced

Priority order:
1. Anxiety Mimic
2. Caffeine Jitter
3. Zone 2 Drain
4. Deep Sleep Robber
5. Recovery Gap

Important tradeoff:
- prioritize signals Monch can support with event/timing + HealthKit, not detectors that require unrealistic nutrition precision

Validation:
- one test file per detector or grouped detector family
- manual scenarios that mirror the UX docs and user-scenario docs

### Phase 3: Strengthen explanation and confidence

Goal:
- make insight cards explainable and trustworthy

Work:
- add explicit contributing signals and confidence language
- expose why an insight fired
- distinguish inferred vs strongly supported insights

Why this matters:
- the product promise is not just detection; it is understandable interpretation

### Phase 4: Reassess the chronic / HRV layer

Goal:
- decide which HRV-layer insights deserve phase-2 investment

Recommended rule:
- keep only the ones that are explainable, stable, and data-supported enough to feel trustworthy

Potential keepers:
- Morning Readiness
- Brain Fog Forecast
- Alcohol Impact

Potential later / riskier set:
- Stress Buffer
- Mineral Gap
- Meal Impact Score
- Fasting Benefit

### Phase 5: Add spec-only insights only after the above is stable

Candidates:
- Lipid Load
- Metabolic Burn
- Tryptophan Trap

These should be treated as new feature work, not as cleanup.

## Recommended Immediate Next Step

The best next deliverable is **not** to start coding a new detector.

The best next step is to create a smaller implementation spec for **Phase 1 + Phase 2**:
- define the runtime orchestration model
- define the exact trigger conditions and fallback logic for the five dormant P1/P2 detectors we should activate next
- define how each one behaves with:
  - HealthKit nutrition available
  - event-only meal context
  - biometrics missing or sparse
  - subjective inputs present

That will let Monch move from "many ideas in code" to a cleaner, believable intelligence system.
