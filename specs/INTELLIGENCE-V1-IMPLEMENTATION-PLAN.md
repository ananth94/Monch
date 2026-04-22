# Monch Intelligence V1 Implementation Plan

## Purpose

This document converts [INTELLIGENCE-SOURCE-OF-TRUTH.md](./INTELLIGENCE-SOURCE-OF-TRUTH.md) into an execution plan.

It answers:
- what Phase 1 and Phase 2 actually mean
- which scenarios are in scope for intelligence v1
- which scenarios are explicitly out of scope for now
- how detector orchestration should work
- what each detector needs to run
- how each detector should degrade gracefully when signals are missing
- how we will validate the work

This is the planning document to implement from.

## Intelligence V1 Goal

Ship a coherent, trustworthy intelligence layer around:
- food timing and acute response
- workout context and fueling windows
- sleep disruption from late intake
- nutritional-versus-stimulant interpretation

This version should prioritize:
- clear runtime wiring
- believable insights
- explainable copy
- honest confidence handling

It should not try to implement every research idea in the archive.

## In Scope

The intelligence v1 scope is:
- Sugar Spike
- Muscle Sponge
- Digestion Debt
- Anxiety Mimic
- Caffeine Jitter
- Zone 2 Drain
- Deep Sleep Robber
- Recovery Gap

## Out Of Scope For V1

These are known scenarios from the source of truth, but they are not part of intelligence v1:
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

These should remain in docs and roadmap, but not become hidden obligations for this implementation cycle.

## Why This Scope

This v1 set is the best balance of:
- research strength
- user value
- compatibility with current Monch signals
- maintainability

It deliberately avoids the research areas that rely too heavily on:
- dense HRV sampling
- temperature dependence
- unavailable signals like EDA or respiration
- rich nutrient composition Monch no longer captures consistently

## Phase Definitions

## Phase 1: Orchestration

### Goal

Make the intelligence system structurally real.

Today, Monch has a detector inventory, but too much of it is dormant or inconsistently triggered. Phase 1 fixes that.

### Deliverables

Phase 1 should produce:
- one explicit meal-triggered intelligence path
- one explicit workout-triggered intelligence path
- one explicit morning intelligence path
- one explicit weekly intelligence path
- clear rules for persistence, dedupe, and surfacing
- tests for orchestration entry points

### What Phase 1 Does Not Do

Phase 1 is not the phase where we expand scope or add new research ideas.

It should not:
- add phase-2 insights
- rewrite the whole engine architecture unless necessary
- introduce hidden dependencies on new sensors or new data models

## Phase 2: Finish Intelligence V1

### Goal

Activate and harden the v1 insight set defined above.

### Deliverables

Phase 2 should produce:
- all eight v1 insights running from real invocation paths
- fallback behavior for sparse nutrition / sparse biometrics
- confidence-aware copy and evidence explanation
- detector-family tests
- manual verification scenarios

### What Phase 2 Does Not Do

Phase 2 should not:
- broaden to chronic or speculative insights
- pretend unavailable signals exist
- overfit product copy to clinical certainty

## Orchestration Model

This is the recommended runtime architecture for intelligence v1.

## 1. Meal-triggered path

### Trigger

Run when:
- a Monch meal event is created
- a HealthKit-imported meal becomes available for a day view and is promoted into analysis context if supported

### Insights run here

- Sugar Spike
- Digestion Debt
- Anxiety Mimic
- Caffeine Jitter
- Deep Sleep Robber candidate preconditions

### Notes

- `Deep Sleep Robber` should not fully fire at meal time, but meal events can register candidate context for later sleep analysis.
- `Caffeine Jitter` may be triggered from meal-adjacent caffeine events or dedicated caffeine events, depending on final event model.

## 2. Workout-triggered path

### Trigger

Run when:
- a workout is logged locally
- a HealthKit workout sync completes

### Insights run here

- Muscle Sponge
- Zone 2 Drain
- Recovery Gap candidate preconditions
- Good Spike suppression context

### Notes

- `Recovery Gap` should likely need a follow-up evaluation window rather than firing immediately at workout end.
- `Good Spike` should remain mostly gating/suppression logic unless we explicitly decide to make it visible as a first-class insight.

## 3. Morning path

### Trigger

Run:
- once per day after sleep data is available
- ideally at app-open if the user has not yet had that day's morning checks evaluated

### Insights run here

- Deep Sleep Robber

### Notes

- For intelligence v1, this path should be intentionally narrow.
- Do not automatically widen this to all dormant HRV-layer insights yet.

## 4. Weekly path

### Trigger

Run:
- only if we need weekly summary compaction for already-supported v1 patterns

### Insights run here

- none required as first-class new v1 detectors

### Notes

- Weekly summaries can aggregate v1 insight counts without introducing new detector logic.
- Keep weekly-only detector activation out of v1 unless needed for surfacing already-supported logic.

## Recommended Code Shape

The simplest maintainable pattern is:
- one orchestration layer in `InsightEngine`
- detector families grouped by trigger type
- narrow entry points called from app surfaces

Recommended entry points:
- `analyzeMeal(...)`
- `analyzeWorkout(...)`
- `runMorningChecks(...)`
- `runWeeklyAggregation(...)`

The main improvement is not naming; it is making these paths explicit, used, and tested.

## Insight-by-Insight Implementation Plan

## 1. Sugar Spike

### Status

Already live.

### Required signals

- meal timestamp
- carbs or high-carb proxy
- HR peak window
- sedentary gate

### Fallback behavior

- if macro detail is missing but meal is explicitly tagged `high-carb`, allow a lower-confidence path
- if HR data is too sparse, do not fire

### Confidence

High when:
- carb signal exists
- post-meal HR window exists
- sedentary gate holds

### Work needed

- verify current logic still behaves well with imported meals and event-based logging
- add tests for imported or proxy meal contexts if needed

## 2. Muscle Sponge

### Status

Already live.

### Required signals

- qualifying workout
- meal timing in post-workout window

### Fallback behavior

- if detailed macros are missing, allow timing/context-only positive guidance
- if workout classification is weak, restrict to more obvious qualifying workouts

### Confidence

High when:
- workout quality is clear
- meal falls within anabolic window

### Work needed

- verify workout-triggered orchestration and suppression logic remain explicit

## 3. Digestion Debt

### Status

Already live.

### Required signals

- meal timestamp
- sleep timing or evening-time proxy

### Fallback behavior

- if exact sleep onset is unavailable, use evening/night timing heuristic

### Confidence

High because timing alone carries strong signal.

### Work needed

- align copy and severity logic with the newer imported-meal and arbitrary-date flows

## 4. Anxiety Mimic

### Status

Live in app via the meal / caffeine-event path.

### Required signals

- carb-heavy meal or high-carb proxy
- 2-3 hour post-meal window
- HRV drop or related autonomic burden
- ideally symptom context

### Fallback behavior

- if HRV is sparse, require stronger timing plus subjective symptom support
- if symptoms are absent and HRV is sparse, do not fire or fire only at low confidence

### Confidence

Medium.

### Main product rule

Never present this as certain panic differentiation.
Frame it as:
- “This may be a sugar dip”
- not “This is definitely not anxiety”

## 5. Caffeine Jitter

### Status

Live in app via the workout path.

### Required signals

- caffeine event
- HR elevation
- ideally HRV or stability cues
- ideally symptom context

### Fallback behavior

- if no HRV support exists, use timing plus caffeine event plus stable context
- if caffeine event timing is weak, do not infer aggressively from meals alone

### Confidence

Medium.

### Main product rule

Do not claim strong differentiation from panic without stronger corroboration.

## 6. Zone 2 Drain

### Status

Live in app via the morning path.

### Required signals

- cardio workout
- zone 2 duration or strong zone-2 proxy

### Fallback behavior

- if HR zones are unreliable, use workout duration + moderate steady-state cardio type as a weaker proxy

### Confidence

Medium.

### Main product rule

Prefer clear threshold-based logic over fancy modeling.

## 7. Deep Sleep Robber

### Status

Live in app via the morning recovery path.

### Required signals

- late meal context
- sleep-stage degradation or nocturnal HR burden
- optional temperature if available

### Fallback behavior

- if temperature is absent, use deep sleep + overnight HR/RHR proxy
- if sleep staging is weak, require stronger late-meal timing plus overnight burden

### Confidence

Medium.

### Main product rule

This should be a morning insight, not a real-time meal insight.

## 8. Recovery Gap

### Status

Live in app via the vibe-check path.

### Required signals

- meaningful workout
- under-fueling or missed refeed context
- delayed HRV recovery or overnight recovery burden

### Fallback behavior

- if HRV recovery is too sparse, combine workout load with lack of nearby refueling and next-day fatigue signals conservatively

### Confidence

Medium.

### Main product rule

This insight should explain “need food vs need rest” carefully, not overstate causality.

## Fallback Rules By Data Scenario

To keep the engine honest after the product pivot, each detector should follow the same hierarchy.

### Scenario A: Richest context

Available:
- HealthKit nutrition
- workout/sleep context
- usable HR/HRV signals

Behavior:
- full detector logic
- normal confidence language

### Scenario B: Event + biometrics

Available:
- meal/caffeine/alcohol events
- workout/sleep context
- HR or HRV support

Behavior:
- allow medium-confidence insight paths
- avoid macro-specific explanations if macros are unknown

### Scenario C: Event-only or sparse biometrics

Available:
- timing and context only

Behavior:
- only allow insights where timing alone is legitimately meaningful
- examples: Digestion Debt, parts of Muscle Sponge
- do not fire fragile biomarker-dependent insights

### Scenario D: Biometrics-only with missing event anchor

Available:
- HRV/sleep/workout data but no clear meal/event anchor

Behavior:
- do not force meal-causal interpretation
- reserve for future phase-2 summaries, not core v1 causal cards

## UI And Copy Rules

### Each v1 insight should expose

- title
- short explanation
- what evidence was used
- suggested action
- confidence band

### Confidence copy guidance

#### High confidence

Language can be direct:
- “This late meal likely affected recovery”

#### Medium confidence

Language should be interpretive:
- “This may have been a sugar dip”
- “Coffee could be contributing here”

#### Low confidence

Do not use for v1 hero insights.

## Validation Plan

## Automated tests

### Phase 1

Add orchestration tests for:
- meal-triggered path
- workout-triggered path
- morning path
- duplicate prevention where needed

### Phase 2

Add detector-family tests for:
- Anxiety Mimic
- Zone 2 Drain
- Deep Sleep Robber
- Recovery Gap

Also keep regression coverage for:
- Sugar Spike
- Muscle Sponge
- Digestion Debt

## Manual verification scenarios

Each v1 insight should have at least one manual scenario tied back to the source-of-truth logic.

Minimum scenario list:
- carb-heavy meal at rest -> Sugar Spike
- qualifying workout + meal in window -> Muscle Sponge
- late meal before sleep -> Digestion Debt
- carb-heavy meal + later crash-like state -> Anxiety Mimic
- caffeine event + alertness state -> Caffeine Jitter
- long zone-2 workout -> Zone 2 Drain
- late heavy meal + poor overnight recovery -> Deep Sleep Robber
- meaningful workout + weak refuel + poor recovery -> Recovery Gap

## Recommended Build Order

This is the recommended coding sequence.

### Step 1

Implement Phase 1 orchestration:
- define and wire the four trigger paths
- keep scope narrow

### Step 2

Activate the safest dormant insight first:
- Zone 2 Drain

Reason:
- strongest signal fit
- least dependent on fragile HRV interpretation

### Step 3

Activate:
- Deep Sleep Robber
- Recovery Gap

Reason:
- they complete the exercise/sleep loop and use context Monch already emphasizes

### Step 4

Activate:
- Anxiety Mimic
- Caffeine Jitter

Reason:
- highest product intrigue, but they need the most careful confidence handling

## Recommended First Coding Slice

Start with:
- Phase 1 orchestration pass
- Zone 2 Drain activation

Why:
- it resolves the foundational architecture issue first
- it activates one dormant insight with relatively strong signal support
- it creates the pattern we can reuse for the rest of v1

## Definition Of Done

Intelligence v1 is done when:
- all eight v1 insights are either live or intentionally deferred with documented reason
- every live insight has a real invocation path
- every live insight has confidence-aware copy
- test coverage exists for orchestration and detector families
- manual scenarios have been run
- no detector is described as implemented if it is still dormant
