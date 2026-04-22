# Monch Intelligence Source Of Truth

## Purpose

This is the canonical planning document for Monch's intelligence system.

It consolidates:
- the original research basis
- the biomarker and signal model
- the canonical insight inventory
- current implementation reality
- the recommended implementation phases

When there is a conflict between older documents, this file should be treated as the working source of truth for product and engineering decisions.

## Related Documents

These documents remain useful as supporting references, but not as the primary planning surface:
- [INTELLIGENCE-SPEC-AND-AUDIT.md](./INTELLIGENCE-SPEC-AND-AUDIT.md)
- [INTELLIGENCE-RESEARCH-AND-BIOMARKER-MAP.md](./INTELLIGENCE-RESEARCH-AND-BIOMARKER-MAP.md)
- [Insights_Library.md](../Insights_Library.md)
- [Research](../Research)

## Core Product Thesis

Monch is not trying to be a food database or a clinical diagnostic system.

The intelligence layer should:
- interpret timing, biometrics, workouts, sleep, and subjective signals
- explain what may be happening in plain English
- suggest useful next actions
- avoid overstating certainty when key biomarkers are missing

The product is strongest when it behaves like a trustworthy interpretation layer, not a fake precision engine.

## Research Foundation

The intelligence system is based on three main research threads:

### 1. Post-prandial autonomic profiling

Source:
- [Food intake x bio markers.md](../Research/Food%20intake%20x%20bio%20markers.md)

Core idea:
- food creates a measurable autonomic and hemodynamic response
- different meal profiles produce different timing windows and recovery signatures
- HR, HRV, RHR, sleep disruption, and temperature can be used as downstream proxies

Most relevant insight families:
- Sugar Spike
- Lipid Load
- Metabolic Burn
- Digestion Debt
- Deep Sleep Robber

### 2. Nutritional psychiatry and autonomic mood interpretation

Source:
- [Food intake x mood.md](../Research/Food%20intake%20x%20mood.md)

Core idea:
- some anxious or cognitively impaired states may be nutritional or autonomic in origin
- HRV, RHR, timing, symptoms, and stimulant context can help distinguish likely causes
- the strongest versions of these ideas often assume richer signals than Monch currently has

Most relevant insight families:
- Anxiety Mimic
- Caffeine Jitter
- Brain Fog Forecast
- Stress Buffer
- Mineral Gap

### 3. Exercise-modulated nutrient partitioning and recovery

Source:
- [Food intake x exercise.md](../Research/Food%20intake%20x%20exercise.md)

Core idea:
- workouts change the meaning of glucose, carbs, recovery signals, and post-meal physiology
- exercise context is required to avoid false positives and to detect adaptive fueling windows
- recovery should be interpreted as a context problem, not just a low-score problem

Most relevant insight families:
- Muscle Sponge
- Good Spike
- Zone 2 Drain
- Recovery Gap
- Alcohol Impact

## Signal Model

### Signals Monch can use well today

These are the strongest current product inputs:
- meal or event timestamp
- workout timestamp, type, and duration
- heart rate
- sleep timing
- sleep stages when present
- resting heart rate / overnight heart-rate burden
- HealthKit nutrition quantities when available
- Monch event tags for meal, caffeine, alcohol
- subjective vibe input
- baseline trends across days and weeks

### Signals Monch can use with caution

These are useful, but source quality or coverage is inconsistent:
- HRV from HealthKit
- wrist temperature
- micronutrient quantities like magnesium and zinc
- source-app food metadata
- HR zone and workout intensity inference

### Signals assumed in research but not strong product primitives today

These should not be treated as reliable requirements for near-term product logic:
- electrodermal activity
- robust respiratory signal for panic differentiation
- CGM
- beat-to-beat RR interval streams
- blood pressure or vascular resistance
- reaction-time or vigilance tasks
- tryptophan:LNAA or tyrosine availability
- B-vitamin status

## Confidence Model

Every insight should be assigned a confidence band based on signal quality, not just whether detector code exists.

### High confidence

Use when:
- timing and context are strong
- the required signals are actually available
- the inference chain is short and explainable

Examples:
- Sugar Spike
- Muscle Sponge
- Digestion Debt

### Medium confidence

Use when:
- the research basis is decent
- some supporting signals exist
- key differentiating signals are missing or sparse

Examples:
- Anxiety Mimic
- Caffeine Jitter
- Deep Sleep Robber
- Recovery Gap
- Zone 2 Drain

### Low confidence or weekly-only

Use when:
- the mechanism is indirect
- the product lacks one or more critical signals
- presenting a precise claim would harm trust

Examples:
- Brain Fog Forecast
- Stress Buffer
- Mineral Gap
- Tryptophan Trap

## Canonical Insight Inventory

This table is the core source of truth for what Monch knows about each insight today.

| Insight | Loop | Research basis | Signals needed | Current status | Confidence target | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| Sugar Spike | Acute | Strong | Meal timing, carbs, HR peak, sedentary gate, optionally HRV | Live in app | High | Keep as core v1 |
| Muscle Sponge | Recovery | Strong | Workout context, post-workout meal timing, meal context | Live in app | High | Keep as core v1 |
| Good Spike | Recovery | Strong conceptually | HR intensity or exercise context around spike | Partially realized as suppression/context | High for suppression logic | Keep as contextual gate, not necessarily hero insight |
| Digestion Debt | Sleep / Circadian | Strong | Meal timing relative to evening or sleep, overnight burden | Live in app | High | Keep as core v1 |
| Anxiety Mimic | Acute | Moderate | Carb-heavy meal, 2-3h window, HRV drop, symptom context | Live in app | Medium | Keep in v1 with careful confidence framing |
| Caffeine Jitter | Acute | Moderate | Caffeine event, HR / HRV pattern, symptom context | Live in app | Medium | Keep in v1 with careful confidence framing |
| Zone 2 Drain | Recovery | Strong | Zone 2 workout context and duration | Live in app | Medium | Keep in v1 |
| Deep Sleep Robber | Sleep / Circadian | Moderate to strong | Sleep timing, deep sleep, nocturnal HR burden, optional temperature | Live in app | Medium | Keep in v1 using proxy logic |
| Recovery Gap | Recovery | Moderate | Workout load, refeed context, HRV recovery slope | Live in app | Medium | Keep in v1 after orchestration cleanup |
| Lipid Load | Acute | Moderate | High-fat meal, delayed HR peak, sustained HRV suppression | Spec only | Medium | Defer to phase 2 |
| Metabolic Burn | Acute | Moderate | Protein-rich meal, temperature rise, moderate HR elevation | Spec only | Low to medium | Defer to phase 2 unless temperature support improves |
| Tryptophan Trap | Sleep / Circadian | Weak to moderate for product | Meal composition, sleep-onset effect, serotonergic inference | Spec only | Low | Defer |
| Brain Fog Forecast | Chronic | Moderate | Prior-day burden, morning HRV, sleep quality, ideally focus proxy | Modeled and detector exists, but dormant | Low to medium | Defer to phase 2 |
| Stress Buffer | Chronic | Moderate | Stress context, protein or tyrosine context, HRV preservation | Modeled and detector exists, but dormant | Low to medium | Defer to phase 2 |
| Mineral Gap | Chronic | Weak to moderate for product | 14-day low-HRV rigidity plus micronutrient context | Modeled and detector exists, but dormant | Low | Defer to phase 2 |
| Morning Readiness | Daily HRV layer | Strong as general recovery concept | Morning HRV vs baseline | Modeled and detector exists, but dormant | Medium | Keep as phase-2 HRV layer |
| Meal Impact Score | Meal stress layer | Moderate | Meal timing plus post-meal HRV shift | Modeled and detector exists, but dormant | Low to medium | Defer until meal-triggered HRV orchestration is solid |
| Alcohol Impact | Daily HRV layer | Moderate to strong | Alcohol event plus overnight HRV / RHR suppression | Modeled and detector exists, but dormant | Medium | Good phase-2 candidate |
| Fasting Benefit | Daily HRV layer | Moderate | Fasting window plus HRV improvement | Modeled and detector exists, but dormant | Low to medium | Defer until fasting becomes product-level concept |

## Implementation Status Model

Use these labels when describing intelligence work:

- `Live`: detector is wired to a real app flow and surfaces in the product
- `Dormant`: detector logic exists but no runtime invocation path is active
- `Modeled only`: represented in taxonomy/UI but not really executed
- `Spec only`: described in research/spec docs but absent from product code

### Current live set

- Sugar Spike
- Muscle Sponge
- Digestion Debt
- Anxiety Mimic
- Caffeine Jitter
- Zone 2 Drain
- Deep Sleep Robber
- Recovery Gap

### Current dormant set

 - Brain Fog Forecast
- Stress Buffer
- Mineral Gap
- Morning Readiness
- Meal Impact Score
- Alcohol Impact
- Fasting Benefit

### Current spec-only set

- Lipid Load
- Metabolic Burn
- Tryptophan Trap

## Biggest Gaps To Fix

### 1. Orchestration gap

The biggest issue is not lack of ideas or even lack of detector methods. It is that a large part of the detector inventory is not actually wired into app runtime flows.

Most importantly:
- `runWeeklyChecks` exists
- the weekly path is still much less real than the meal, workout, and morning paths

This is the first thing to fix.

### 2. Taxonomy drift

The research archive, `Insights_Library.md`, `InsightType`, and the UI no longer describe exactly the same system.

This document resolves that by making the canonical inventory explicit, but the code and docs should gradually be brought into alignment with it.

### 3. Signal mismatch after the product pivot

The research often assumes:
- richer nutrient precision
- better HRV density
- extra signals like EDA or respiration

The product has intentionally moved toward event-based logging plus HealthKit enrichment. That is the right product decision, but it means many detectors need more explicit fallback paths.

### 4. Validation gap

Most automated coverage is still concentrated in the old MVP core.

Before broadening the system, Monch needs:
- orchestration tests
- detector-family tests
- manual verification scenarios tied to the research logic

## Recommended Intelligence V1 Scope

This is the recommended near-term scope to build and trust well:

- Sugar Spike
- Muscle Sponge
- Digestion Debt
- Anxiety Mimic
- Caffeine Jitter
- Zone 2 Drain
- Deep Sleep Robber
- Recovery Gap

Why this set:
- it is strongly rooted in the original research priorities
- most of it can be supported with signals Monch plausibly has now
- it creates one coherent story about food, energy, exercise, and sleep
- it avoids overcommitting to the most speculative research areas

## Recommended Phase Plan

### Phase 0: Alignment

Goal:
- use this document as the source of truth

Work:
- reference this file in future planning
- update older docs only when needed for consistency
- classify existing detectors in code according to this file

### Phase 1: Orchestration

Goal:
- make detector wiring explicit and real

Work:
- define the meal-triggered path
- define the workout-triggered path
- define the morning path
- define the weekly path
- ensure insights are inserted, surfaced, and deduped intentionally

Primary files likely involved:
- `monch/Services/InsightEngine.swift`
- `monchApp.swift`
- timeline/dashboard entry points

### Phase 2: Finish intelligence v1

Goal:
- activate the dormant v1 insights

Priority order:
1. Anxiety Mimic
2. Caffeine Jitter
3. Zone 2 Drain
4. Deep Sleep Robber
5. Recovery Gap

Rule:
- each detector must define required signals, fallback path, and UI confidence band

### Phase 3: Strengthen explanations

Goal:
- make insights legible and trustworthy

Work:
- define why an insight fired
- define what evidence supported it
- define what uncertainty remains
- make card copy reflect confidence rather than false certainty

### Phase 4: Reassess phase-2 research ideas

Candidates:
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

Rule:
- do not promote a phase-2 insight until its required signals and confidence story are honest

## Planning Rules Going Forward

When adding or activating any intelligence feature, document:
- research basis
- required signals
- which signals are truly available now
- fallback behavior when signals are missing
- confidence band
- invocation path
- tests and manual validation scenario

If a detector exists in code but lacks these, it should not be described as fully implemented.

## Recommended Immediate Next Step

The next planning artifact should be a concrete implementation spec for Phase 1 and Phase 2.

That spec should define:
- exact orchestration entry points
- which detector families run in each path
- how HealthKit nutrition versus event-only data affects logic
- confidence and copy rules per insight
- test scenarios for each detector family

This document should stay stable while that implementation spec becomes the execution plan.
