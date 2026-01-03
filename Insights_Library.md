# Monch Insights Library: The Biological Logic Gates

**Version:** 1.1 (Engineering Spec)
**Status:** Approved for MVP
**Reference:** [Monch Research Repository](./Research/)

This document defines the "Brain" of the Monch application. It translates the "Three-Loop" metabolic research into 15 programmable logic gates for the iOS CoreML engine.

---

## Insight Prioritization Matrix

| Insight Name | Priority | Loop | Feasibility | Key Value Prop |
| :--- | :--- | :--- | :--- | :--- |
| **1. The Sugar Spike** | **[P0]** | Acute | 5/5 | Predicts energy crashes; tangible daily utility. |
| **6. The Muscle Sponge** | **[P0]** | Recovery | 5/5 | Actionable "Free Pass" to eat carbs post-workout. |
| **7. The "Good" Spike** | **[P0]** | Recovery | 5/5 | Prevents false alarms during exercise; builds trust. |
| **10. The Digestion Debt** | **[P0]** | Sleep | 5/5 | Connects late eating to poor sleep quality. |
| **4. The Anxiety Mimic** | **[P1]** | Acute | 3.5/5 | Relieves anxiety by identifying biological cause. |
| **5. The Caffeine Jitter** | **[P1]** | Acute | 3/5 | Distinguishes stimulant arousal from stress. |
| **9. The Zone 2 Drain** | **[P1]** | Recovery | 5/5 | Optimizes fueling for endurance athletes. |
| **11. The Deep Sleep Robber** | **[P1]** | Sleep | 4/5 | Leverages Temp sensing for deeper sleep insights. |
| **2. The Lipid Load** | **[P2]** | Acute | 3/5 | Explains sluggishness after heavy meals. |
| **3. The Metabolic Burn** | **[P2]** | Acute | 3/5 | Tracks thermogenic effect of protein. |
| **8. The Recovery Gap** | **[P2]** | Recovery | 2/5 | Identifies under-fueling vs. over-training. |
| **12. The Tryptophan Trap** | **[P2]** | Sleep | 2/5 | Optimizes carb timing for sleep onset. |
| **13. The Brain Fog Forecast** | **[P2]** | Chronic | 2/5 | Predicts cognitive performance based on habits. |
| **14. The Stress Buffer** | **[P2]** | Chronic | 2/5 | Validates protein intake for stress management. |
| **15. The Mineral Gap** | **[P2]** | Chronic | 3/5 | Flags potential micronutrient deficiencies. |

---

## 1. Core Architecture

The engine analyzes data across three temporal feedback loops:
1.  **Acute Loop (0–4 Hours):** Immediate post-prandial response (Insulin, Digestion, Thermogenesis).
2.  **Recovery Loop (Sleep & Next Day):** Circadian cost, repair, and recovery (HRV, RHR).
3.  **Chronic Loop (7–30 Days):** Long-term trends (Adaptation, Deficiencies).

### Data Dictionary (HealthKit)

| Metric | HealthKit Identifier | Usage |
| :--- | :--- | :--- |
| **Heart Rate** | `HKQuantityTypeIdentifierHeartRate` | Continuous HR for peak/slope analysis. |
| **Resting HR** | `HKQuantityTypeIdentifierRestingHeartRate` | Daily baseline and Nocturnal Dip analysis. |
| **HRV** | `HKQuantityTypeIdentifierHeartRateVariabilitySDNN` | Primary stress/recovery metric. |
| **Wrist Temp** | `HKQuantityTypeIdentifierAppleSleepingWristTemperature` | Thermogenic load (Requires Series 8+). |
| **Carbs** | `HKQuantityTypeIdentifierDietaryCarbohydrates` | From Food Log (Metadata). |
| **Fat** | `HKQuantityTypeIdentifierDietaryFat` | From Food Log (Metadata). |
| **Protein** | `HKQuantityTypeIdentifierDietaryProtein` | From Food Log (Metadata). |
| **Steps** | `HKQuantityTypeIdentifierStepCount` | "Sedentary Gate" filter (< 20 steps/5min). |
| **Sleep** | `HKCategoryTypeSleepAnalysis` | Sleep stages (Deep/REM) and timing. |
| **Workout** | `HKWorkout` | Activity timestamps and intensity context. |

---

## 2. The Insight Modules

### Loop 1: The Acute Loop (Immediate Response)

#### 1. The Sugar Spike (Insulin Load) `[P0]`
*   **User Message:** "That meal spiked your heart rate quickly. Expect a potential energy crash in ~90 mins."
*   **Reference:** *Food intake x bio markers.md* (Section 3.1: HC Profile) - citing *Lim et al. (2020)* context.
*   **Scientific Logic:** High-glycemic meals trigger a baroreflex-mediated HR spike (Sympathetic Activation) within 30-45 minutes.
*   **Algorithm:**
    *   **Trigger:** `Meal.Carbs > 30g`.
    *   **Window:** `Meal_Time` to `Meal_Time + 60m`.
    *   **Logic:**
        ```python
        baseline = median(HR[-30m:])
        peak = max(HR[0m:60m])
        time_to_peak = peak.timestamp - meal.timestamp
        
        if (time_to_peak < 40_min) and (peak > baseline + 15_bpm):
            return TRUE
        ```
    *   **Gate:** `StepCount < 10` (User must be sedentary).

#### 2. The Lipid Load (Delayed Digestion) `[P2]`
*   **User Message:** "Your heart is still working hard to digest lunch. You might feel sluggish for another hour."
*   **Reference:** *Food intake x bio markers.md* (Section 3.2: HF Profile).
*   **Scientific Logic:** High-fat meals delay gastric emptying, sustaining cardiac workload for 3-4 hours (vs 1-2h for carbs).
*   **Algorithm:**
    *   **Trigger:** `Meal.Fat > 25g`.
    *   **Window:** `Meal_Time` to `Meal_Time + 180m`.
    *   **Logic:**
        ```python
        # Check for sustained elevation LATE in the window
        late_window_avg = avg(HR[120m:180m])
        if (late_window_avg > baseline + 10_bpm):
            return TRUE
        ```

#### 3. The Metabolic Burn (Thermogenesis) `[P2]`
*   **User Message:** "Your temp is up. That high-protein meal has your metabolism revving high."
*   **Reference:** *Food intake x bio markers.md* (Section 3.3: HP Profile).
*   **Scientific Logic:** Protein TEF (Thermic Effect of Food) dissipates heat, raising peripheral skin temp and HR.
*   **Algorithm:**
    *   **Trigger:** `Meal.Protein > 35g`.
    *   **Logic:**
        ```python
        temp_delta = Current_WristTemp - Baseline_WristTemp
        if (temp_delta > 0.3°C) and (HR > baseline + 5_bpm):
            return TRUE
        ```

#### 4. The Anxiety Mimic (Reactive Hypoglycemia) `[P1]`
*   **User Message:** "You feel jittery, but it’s not stress. It’s a sugar crash from breakfast."
*   **Reference:** *Food intake x mood.md* (Section 4.2.2: Sugar Crash).
*   **Scientific Logic:** Rapid glucose drop triggers adrenergic surge (adrenaline), mimicking panic symptoms (Sawtooth pattern).
*   **Algorithm:**
    *   **Trigger:** `Meal.Carbs > 40g`.
    *   **Window:** `T+120m` to `T+180m`.
    *   **Logic:**
        ```python
        # Pattern: Spike -> Crash -> HRV Drop
        if (HR_Gradient < -1.0) and (HRV_Current < HRV_Baseline * 0.8):
            return TRUE
        ```

#### 5. The Caffeine Jitter (Stimulant Arousal) `[P1]`
*   **User Message:** "High alert, but physically calm. That's the coffee, not panic."
*   **Reference:** *Food intake x mood.md* (Section 4.2.1: Caffeine).
*   **Scientific Logic:** Caffeine increases HR (Sympathetic) but maintains stable respiration/HRV structure, unlike panic.
*   **Algorithm:**
    *   **Trigger:** `Caffeine Log` OR `Pattern Match`.
    *   **Logic:**
        ```python
        if (HR > baseline + 10_bpm) and (RespiratoryRate is STABLE):
            return TRUE
        ```

---

### Loop 2: The Recovery Loop (Sleep & Workout)

#### 6. The Muscle Sponge (Anabolic Window) `[P0]`
*   **User Message:** "Your muscles are hungry. Carbs eaten now will fuel muscle, not fat."
*   **Reference:** *Food intake x exercise.md* (Section 5.1: Biomarker Window).
*   **Scientific Logic:** Post-exercise, GLUT4 translocation allows insulin-independent glucose uptake into muscle.
*   **Algorithm:**
    *   **Trigger:** `Workout_End` event.
    *   **Condition:** `Workout.ActiveEnergy > 300kcal` OR `HR_Max > Zone3`.
    *   **Window:** `Workout_End` to `Workout_End + 120m`.

#### 7. The "Good" Spike (Performance Fueling) `[P0]`
*   **User Message:** "Your blood sugar spiked, but it's fueling your sprint. Don't worry about it."
*   **Reference:** *Food intake x exercise.md* (Section 4.2: HRmax% Gate).
*   **Scientific Logic:** Anaerobic effort releases liver glycogen (catecholamines). This is adaptive fuel, not maladaptive sugar.
*   **Algorithm:**
    *   **Trigger:** `HR > 80% Max`.
    *   **Action:** **SUPPRESS** "Sugar Spike" alerts during this window.

#### 8. The Recovery Gap (Under-fueling) `[P2]`
*   **User Message:** "You aren't recovering fast enough. You don't need a nap; you need a meal."
*   **Reference:** *Food intake x exercise.md* (Section 3.3: RMSSD Recovery Tau).
*   **Scientific Logic:** Slow HRV recovery slope often indicates metabolic fatigue (glycogen depletion) vs. CNS fatigue.
*   **Algorithm:**
    *   **Trigger:** Post-Workout `HRV`.
    *   **Logic:**
        ```python
        recovery_tau = calculate_slope(HRV[0m:60m])
        if (recovery_tau < Threshold) and (Caloric_Intake < Active_Burn):
            return TRUE
        ```

#### 9. The Zone 2 Drain (Clearance Potential) `[P1]`
*   **User Message:** "Your long walk created a 'glucose drain.' You can handle a bigger dinner tonight."
*   **Reference:** *Food intake x exercise.md* (Section 2.1.1: Zone 2).
*   **Scientific Logic:** Sustained low-intensity activity increases insulin sensitivity via flow-dependent clearance.
*   **Algorithm:**
    *   **Trigger:** `Workout.Type == Cardio`.
    *   **Logic:** `Duration_in_Zone2 > 45_mins`.

---

### Loop 3: The Sub-Acute Loop (Sleep)

#### 10. The Digestion Debt (Circadian Cost) `[P0]`
*   **User Message:** "Your late dinner kept your heart racing while you slept. It cost you 15% of your recovery."
*   **Reference:** *Food intake x bio markers.md* (Section 5.3: Circadian Cost).
*   **Scientific Logic:** Late eating blunts the nocturnal "Dip" in HR/Temp, disrupting Deep Sleep.
*   **Algorithm:**
    *   **Trigger:** `Meal_Time` > (`Sleep_Start` - 3h).
    *   **Logic:**
        ```python
        nocturnal_dip = (Day_RHR - Sleep_RHR) / Day_RHR
        if (nocturnal_dip < 0.10): # Less than 10% dip
            return TRUE
        ```

#### 11. The Deep Sleep Robber (Thermal Load) `[P1]`
*   **User Message:** "Your body temp stayed high all night to process that meal, blocking Deep Sleep."
*   **Reference:** *Food intake x bio markers.md* (Section 5.2: Sleep Stages).
*   **Scientific Logic:** Core temp must drop ~2°F to initiate Deep Sleep. Digestion opposes this.
*   **Algorithm:**
    *   **Trigger:** `WristTemp > Baseline` during first 4h of sleep.
    *   **Correlation:** `DeepSleep_Duration` < User_Avg.

#### 12. The Tryptophan Trap (Serotonin Timing) `[P2]`
*   **User Message:** "That carb-heavy dinner might actually help you sleep better tonight by boosting serotonin."
*   **Reference:** *Food intake x mood.md* (Section 3.1: Tryptophan).
*   **Scientific Logic:** High Carb/Low Protein meals increase TRP:LNAA ratio, boosting brain serotonin.
*   **Algorithm:**
    *   **Trigger:** `Meal.Carbs == High` AND `Meal.Protein == Low`.
    *   **Logic:** `SleepOnsetLatency < 15_mins` (Next Morning Check).

---

### Loop 4: The Chronic Loop (Trends & Mind)

#### 13. The Brain Fog Forecast (Cognitive Clarity) `[P2]`
*   **User Message:** "Yesterday's sugar rollercoaster predicts low focus today. Tackle hard work early."
*   **Reference:** *Food intake x mood.md* (Section 6: Cognitive Clarity).
*   **Scientific Logic:** High Glycemic Variability (MAGE) predicts reduced cognitive function/focus the next day.
*   **Algorithm:**
    *   **Trigger:** Count of "Sugar Spikes" (Insight #1) > 2 previous day.

#### 14. The Stress Buffer (Tyrosine Effect) `[P2]`
*   **User Message:** "Despite a stressful day, your protein intake helped keep you level-headed."
*   **Reference:** *Food intake x mood.md* (Section 3.2: Tyrosine).
*   **Scientific Logic:** Tyrosine (protein) replenishes catecholamines during acute stress.
*   **Algorithm:**
    *   **Trigger:** `Stress_Log == High` AND `Protein_Intake > Target`.
    *   **Logic:** `HRV_SDNN` remains stable (vs. dropping).

#### 15. The Mineral Gap (Deficiency Flag) `[P2]`
*   **User Message:** "Your recovery is consistently 'rigid.' You might be low on Magnesium."
*   **Reference:** *Food intake x mood.md* (Section 4.1: Micronutrients).
*   **Scientific Logic:** Chronic Mg/Zn deficiency manifests as "Autonomic Rigidity" (low baseline HRV).
*   **Algorithm:**
    *   **Trigger:** 14-day Rolling Avg.
    *   **Logic:** `HRV_Baseline` is Low/Flat AND `Sleep_Duration` is Adequate.
