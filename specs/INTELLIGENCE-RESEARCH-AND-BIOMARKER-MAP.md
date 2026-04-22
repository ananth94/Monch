# Monch Intelligence Research And Biomarker Map

## Purpose

This document translates Monch's deep research archive into a product-planning artifact.

It answers four questions:
- what biomarkers and mechanisms were proposed in the original research
- which insights depend on those biomarkers
- which biomarkers Monch can realistically observe today
- which research-backed ideas are strong candidates for implementation versus later exploration

This is the companion to [INTELLIGENCE-SPEC-AND-AUDIT.md](./INTELLIGENCE-SPEC-AND-AUDIT.md), which focuses on product/code reality. This document focuses on the underlying research basis and biomarker availability.

## Primary Research Sources

- [Food intake x bio markers.md](../Research/Food%20intake%20x%20bio%20markers.md)
- [Food intake x mood.md](../Research/Food%20intake%20x%20mood.md)
- [Food intake x exercise.md](../Research/Food%20intake%20x%20exercise.md)
- [Insights_Library.md](../Insights_Library.md)

## How To Read This Document

### Evidence labels

- `Research-backed`: clearly argued in the research reports with a concrete physiological mechanism and proposed detection logic
- `Inference-backed`: not directly measurable in Monch, but reasonably inferable from a chain of available signals
- `Speculative`: interesting and plausible, but difficult to support well with Monch's current data sources

### Availability labels

- `Available now`: Monch can plausibly observe this today via HealthKit or current app input
- `Available with caveats`: partially available, low-frequency, incomplete, or source-dependent
- `Not realistically available now`: the research depends on a signal Monch does not truly have in a robust way today

## Research Model Summary

Across the three research reports, the intelligence model rests on a few core ideas:

1. Food is interpreted as a physiological event, not just an intake event.
The important signal is not only what was eaten, but the body's response over time.

2. The autonomic nervous system is the main readout.
HR, HRV, RHR, sleep disruption, temperature, and workout context are treated as the observable downstream effects of nutrition.

3. Context changes meaning.
The same glucose or HR pattern means something different at rest, after a workout, during stress, or near sleep.

4. Timing is a first-class variable.
Most insight logic depends on time windows: 30 minutes after eating, 2-3 hours after a carb-heavy meal, the first 4 hours of sleep, 24 hours after training, or 14-day rolling trends.

5. Monch's strongest opportunity is not direct measurement of metabolism, but triangulation.
The product works best when it combines meal timing, workout context, sleep context, and wearable-derived autonomic signals into a defensible interpretation.

## Canonical Biomarker Inventory

### Tier 1: Strongest product-ready biomarkers

These are the biomarkers the research leans on most heavily and Monch can plausibly access or derive today.

| Biomarker / signal | Research role | Availability | Main caveats | Most relevant insights |
| --- | --- | --- | --- | --- |
| Meal/event timestamp | Anchor for all temporal logic | `Available now` | Depends on logging completeness or imported nutrition timestamps | Almost all insights |
| Workout timestamp/type/duration | Provides exercise context and anabolic/clearance windows | `Available now` | Quality varies by HealthKit workout classification | Muscle Sponge, Good Spike, Zone 2 Drain, Recovery Gap |
| Heart rate (HR) | Detects post-prandial peaks, exertion intensity, overnight burden | `Available now` | Noisy without sedentary/activity gating | Sugar Spike, Lipid Load, Metabolic Burn, Digestion Debt |
| Heart rate variability (HRV / SDNN proxy) | Main recovery/stress signal | `Available now with caveats` | Sparse and uneven in HealthKit; timing granularity may be weaker than research assumes | Anxiety Mimic, Recovery Gap, Brain Fog Forecast, Stress Buffer, Mineral Gap |
| Resting heart rate / nocturnal HR profile | Captures overnight load and recovery dip | `Available now with caveats` | Requires careful nightly aggregation; not a direct "nocturnal dip" primitive | Digestion Debt, Deep Sleep Robber, Alcohol Impact |
| Sleep timing and stages | Provides sleep onset timing, deep sleep context, nocturnal window | `Available now with caveats` | Stage reliability varies; depends on device and user behavior | Digestion Debt, Deep Sleep Robber, Tryptophan Trap, Brain Fog Forecast |
| Nutrition quantities from HealthKit | Supplies carbs, fat, protein, calories when available | `Available now with caveats` | Source apps often omit names, some nutrients, or consistent metadata | Sugar Spike, Lipid Load, Metabolic Burn, Recovery Gap |
| Monch event tags | Lightweight context when macros are absent | `Available now` | Lower precision than full nutrition data | Digestion Debt, Caffeine Jitter, Alcohol Impact |
| Selected micronutrients in logs (`magnesium`, `zinc`, `caffeine`) | Supports deficiency/stimulant hypotheses | `Available with caveats` | Mostly absent unless imported or explicitly present in data | Caffeine Jitter, Mineral Gap |
| Baseline trends over 7-30 days | Enables chronic pattern logic | `Available now with caveats` | Needs enough data density to avoid false stories | Mineral Gap, Brain Fog Forecast, Stress Buffer |

### Tier 2: Useful but weaker or source-dependent biomarkers

| Biomarker / signal | Research role | Availability | Main caveats | Most relevant insights |
| --- | --- | --- | --- | --- |
| Wrist temperature | Thermal load, protein thermogenesis, sleep disruption | `Available with caveats` | Device-limited and not always present; current app does not appear to use it heavily | Metabolic Burn, Deep Sleep Robber |
| Step count / sedentary gate | Separates digestion signal from movement noise | `Available now` | Needs careful short-window aggregation | Sugar Spike, Lipid Load |
| Dominant HR zone / HRmax intensity | Distinguishes adaptive exercise spikes from dietary spikes | `Available now with caveats` | Requires robust workout and HR zone modeling | Good Spike, Zone 2 Drain |
| Source-app meal metadata (`foodType`, source app) | Improves labeling and some meal interpretation | `Available with caveats` | Inconsistent across external apps | Imported meal UX, not core insight logic |
| Subjective vibe / symptom reports | Helps disambiguate nutritional vs emotional arousal | `Available now` | Current engine does not yet use it strongly | Anxiety Mimic, Caffeine Jitter, Brain Fog Forecast |

### Tier 3: Research-important but not realistically available as robust product inputs today

| Biomarker / signal | Research role | Availability | Why it is hard now |
| --- | --- | --- | --- |
| Electrodermal activity (EDA) | Distinguishes panic/stress from nutritional arousal | `Not realistically available now` | Not available as a standard Apple Watch / HealthKit signal for Monch |
| Respiratory waveform / reliable respiratory rate for panic differentiation | Separates caffeine jitter from panic by respiratory instability | `Not realistically available now` | Not a dependable app-level primitive in current Monch stack |
| Continuous glucose monitoring (CGM) | Best source for glycemic spikes, variability, rebound hypos | `Not realistically available now` | Not part of current product/data pipeline |
| Beat-to-beat RR intervals / high-resolution HRV waveform analysis | Supports more rigorous short-window HRV detection | `Not realistically available now` | HealthKit exposure is much coarser than research-grade pipelines |
| Blood pressure / systemic vascular resistance | Helps validate lipid-load and caffeine models | `Not realistically available now` | Not available in a sufficiently continuous way |
| Reaction time / vigilance tasks | Needed for cognitive clarity scoring in a strong sense | `Not realistically available now` | Requires bespoke product interaction not currently present |
| Calendar/deep-work context | Helpful for tyrosine / cognitive stress interpretation | `Not realistically available now` | Not in current product scope |
| Tryptophan:LNAA ratio / tyrosine availability | Core research mechanism, but not directly observable | `Not realistically available now` | Requires meal composition depth and physiological inference far beyond current data quality |
| B-vitamin status | Cofactor for neurotransmitter hypotheses | `Not realistically available now` | Monch does not reliably know this |

## Biomarker Families And What They Support

### 1. Post-prandial autonomic response

Research basis:
- [Food intake x bio markers.md](../Research/Food%20intake%20x%20bio%20markers.md)

Core product idea:
- use HR and HRV as the body's response signal after meals
- use timing and movement gating to classify the type of metabolic load

Primary biomarkers:
- meal timestamp
- carbs / fat / protein
- HR peak latency
- HRV suppression shape
- step/sedentary gate
- optional wrist temperature

Strongest supportable insights:
- Sugar Spike
- Digestion Debt
- Lipid Load
- Metabolic Burn

Research-to-product judgment:
- `Sugar Spike` is strong and already closest to production reality
- `Lipid Load` is plausible, but depends on a long observation window and cleaner HR data than Monch currently validates
- `Metabolic Burn` is interesting, but temperature dependence makes it weaker near-term unless temperature support is reliable

### 2. Circadian and sleep disruption

Research basis:
- [Food intake x bio markers.md](../Research/Food%20intake%20x%20bio%20markers.md)
- [Food intake x exercise.md](../Research/Food%20intake%20x%20exercise.md)

Core product idea:
- late meals and late high-intensity activity disrupt the nocturnal recovery pattern

Primary biomarkers:
- meal timestamp vs sleep onset
- nocturnal HR / RHR dip
- sleep onset latency proxy
- deep sleep duration
- optional wrist temperature

Strongest supportable insights:
- Digestion Debt
- Deep Sleep Robber
- Alcohol Impact
- parts of Tryptophan Trap

Research-to-product judgment:
- `Digestion Debt` is very strong because timing alone carries signal even when biometrics are sparse
- `Deep Sleep Robber` is plausible, but the research wants temperature and early-night deep sleep detail; Monch may need to fall back to sleep-stage and nocturnal-HR proxies
- `Tryptophan Trap` is much weaker as a first implementation because the mechanistic story is richer than the available product signals

### 3. Exercise-modulated nutrient partitioning

Research basis:
- [Food intake x exercise.md](../Research/Food%20intake%20x%20exercise.md)

Core product idea:
- workouts change the meaning of food signals and carb tolerance
- the engine should distinguish adaptive fuel mobilization from maladaptive dietary load

Primary biomarkers:
- workout type, intensity, duration
- HR zone / HRmax%
- post-workout timing window
- HRV / RHR recovery slope
- meal timing and refeed presence

Strongest supportable insights:
- Muscle Sponge
- Good Spike
- Zone 2 Drain
- Recovery Gap

Research-to-product judgment:
- this is one of Monch's best long-term moats because the contextual logic is distinctive and fits available signals reasonably well
- `Muscle Sponge` is already the clearest production candidate
- `Zone 2 Drain` is supportable if workout classification is trustworthy
- `Recovery Gap` is promising, but the research assumes more reliable recovery-curve analysis than current app wiring supports

### 4. Nutritional psychiatry and autonomic mood interpretation

Research basis:
- [Food intake x mood.md](../Research/Food%20intake%20x%20mood.md)

Core product idea:
- use autonomic patterns plus context to distinguish nutritional arousal from emotional/psychogenic arousal

Primary biomarkers:
- HRV trend
- RHR change
- symptom reports / vibe check
- caffeine event timing
- meal timing and carb load
- ideally EDA and respiration, though Monch lacks them today

Strongest supportable insights:
- Anxiety Mimic
- Caffeine Jitter
- Brain Fog Forecast
- Stress Buffer
- parts of Emotional Eating / Cognitive Clarity concepts

Research-to-product judgment:
- `Anxiety Mimic` and `Caffeine Jitter` are compelling product ideas, but the research differentiates them best with EDA and respiration, which Monch does not have
- these are still worth building, but the product should frame them as lower-confidence inferences unless supported by subjective inputs
- `Brain Fog Forecast` and `Stress Buffer` are phase-2 material because the evidence chain is more indirect and more sensitive to missing data

### 5. Micronutrient deficiency inference

Research basis:
- [Food intake x mood.md](../Research/Food%20intake%20x%20mood.md)

Core product idea:
- chronic autonomic rigidity plus nutrient context may hint at deficiency-like patterns

Primary biomarkers:
- baseline HRV trend
- recovery rigidity / poor rebound
- sleep adequacy
- magnesium / zinc / B-vitamin intake context

Most relevant insights:
- Mineral Gap

Research-to-product judgment:
- the biological idea is interesting, but product confidence should be low unless Monch has sustained trend data plus reliable micronutrient information
- this is not a good early-v1 insight despite being memorable

## Insight-By-Insight Research Map

| Insight | Research basis | Biomarkers needed | Availability judgment | Product recommendation |
| --- | --- | --- | --- | --- |
| Sugar Spike | Strong | Meal timing, carbs, HR peak, HRV drop, sedentary gate | Good | Keep as core v1 |
| Muscle Sponge | Strong | Workout window, workout load, meal timing/macros | Good | Keep as core v1 |
| Good Spike | Strong conceptually | HR intensity / workout context around spike | Good | Keep, but likely as suppression/context rather than standalone hero card |
| Digestion Debt | Strong | Late meal timing, sleep timing, nocturnal HR burden | Very good | Keep as core v1 |
| Anxiety Mimic | Moderate | Carb-heavy meal, 2-3h window, HRV drop, symptom context, ideally EDA | Fair | Build in v1, but use confidence language and subjective corroboration |
| Caffeine Jitter | Moderate | Caffeine event, HR/HRV pattern, ideally respiration/EDA | Fair | Build in v1, but frame carefully |
| Zone 2 Drain | Strong | Zone 2 workout context and duration | Good | Build in v1 |
| Deep Sleep Robber | Moderate to strong | Sleep architecture, nocturnal temp or HR load, late meal timing | Fair | Build in v1 with proxy logic |
| Recovery Gap | Moderate | Workout load, HRV recovery slope, refeed presence | Fair | Build in v1 if orchestration/testing improves |
| Lipid Load | Moderate | Fat-rich meal, delayed HR peak, prolonged HRV suppression | Fair | Defer until event windows and longer-tail analysis are stronger |
| Metabolic Burn | Moderate | Protein-rich meal, temperature rise, moderate HR elevation | Weak to fair | Defer unless wrist temperature becomes reliable in practice |
| Tryptophan Trap | Weak to fair | Meal composition, sleep onset, serotonergic inference | Weak | Defer |
| Brain Fog Forecast | Moderate | Prior-day glycemic burden, morning HRV, focus proxy | Fair | Defer to phase 2 |
| Stress Buffer | Moderate | Stress context, protein or tyrosine context, HRV preservation | Weak to fair | Defer to phase 2 |
| Mineral Gap | Weak to fair | 14-day low HRV rigidity + micronutrient context | Weak | Defer to phase 2 |
| Morning Readiness | Strong as generic recovery concept | Morning HRV vs baseline | Good | Keep as phase-2 HRV layer, not first intelligence-v1 priority |
| Meal Impact Score | Moderate | Meal timing + post-meal HRV effect | Fair | Defer until meal-triggered HRV orchestration is solid |
| Alcohol Impact | Moderate to strong | Alcohol event + overnight HRV suppression / RHR burden | Good | Good phase-2 candidate |
| Fasting Benefit | Moderate | Fasting window + HRV improvement | Fair | Defer until fasting is a deliberate product concept |

## What The Research Overestimates Relative To Current Product Reality

### 1. Signal richness

The research often assumes:
- dense HRV availability
- cleaner short-window HRV analysis than HealthKit typically guarantees
- optional signals like EDA, respiration, and temperature
- more complete nutrient composition than Monch now captures directly

That does not invalidate the ideas, but it does mean many of them need confidence downgrades or fallback logic.

### 2. Nutrient detail

The research frequently reasons from:
- macro thresholds
- amino-acid composition
- micronutrient status
- Tryptophan/LNAA and Tyrosine context

Monch's product has intentionally moved away from rich first-party nutrition entry, so many of these insights now depend on HealthKit nutrition quality or weaker event-level proxies.

### 3. Direct causality

The research is strongest when it frames plausible physiological mechanisms. The product must be more conservative and present these as grounded interpretations rather than definitive causal claims.

## Product-Safe Confidence Rules

To turn the research into a trustworthy app layer, Monch should use a simple confidence model:

### High confidence

Use when:
- timing + context are strong
- biomarker pattern is clear
- required signals are actually available

Examples:
- Sugar Spike
- Muscle Sponge
- Digestion Debt

### Medium confidence

Use when:
- insight is supported by timing and one or two biomarker proxies
- key discriminating signals are missing
- explanation is still plausible and helpful

Examples:
- Anxiety Mimic
- Caffeine Jitter
- Deep Sleep Robber
- Recovery Gap

### Low confidence / weekly-only

Use when:
- the mechanism is indirect
- required signals are sparse or noisy
- false precision would hurt trust

Examples:
- Mineral Gap
- Brain Fog Forecast
- Stress Buffer
- Tryptophan Trap

## Recommended Changes To The Plan

This research review strengthens the earlier recommendation, but sharpens it in one important way:

### What should move into intelligence v1

The best research-supported and product-supportable set is:
- Sugar Spike
- Muscle Sponge
- Digestion Debt
- Anxiety Mimic
- Caffeine Jitter
- Zone 2 Drain
- Deep Sleep Robber
- Recovery Gap

### Why this set still wins

- it aligns with the original research priorities
- it mostly depends on signals Monch can plausibly observe now
- it creates a coherent story around food, energy, exercise, and sleep
- it avoids the parts of the research that depend too heavily on unavailable sensors or unrealistic nutrient precision

### What should explicitly become phase 2

These should stay in the research-backed roadmap, but not be treated as near-term commitments:
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

### Implementation rule this suggests

When we implement or activate a detector, we should document:
- the exact required signals
- the fallback path when those signals are missing
- the confidence band used in UI copy
- whether the logic is evidence-backed, inference-backed, or speculative

That will keep Monch aligned with the research without overselling what the product truly knows.

## Recommended Immediate Next Step

Before coding more detectors, Monch should get one more planning artifact:
- a runtime orchestration spec for intelligence v1

That spec should define:
- which entry points run meal-triggered, workout-triggered, morning, and weekly logic
- which detector families run in each path
- what data each detector needs
- how to degrade gracefully when only timing/event data is available
- what confidence band each insight should use in the product

This is the bridge from research to production.
