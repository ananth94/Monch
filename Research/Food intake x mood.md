# Computational Nutritional Psychiatry: Architecting an On-Device Engine for Gut-Brain-Axis Biosignal Analysis

## 1. Executive Summary

The convergence of nutritional psychiatry, wearable biosensing, and edge computing represents a frontier in personalized health monitoring. This report outlines the theoretical, physiological, and technical architecture for an iOS-based on-device engine designed to analyze the intersection of nutrition, physiological biomarkers, and psychological mood states. The engine’s primary objective is to decode the "Gut-Brain-Axis" through non-invasive wearable data, specifically Heart Rate Variability (HRV), Resting Heart Rate (RHR), and electrodermal activity (EDA), correlating these with nutritional intake and cognitive states.

Drawing on exhaustive research from 2022 to 2026, this analysis details the physiological signatures required to distinguish between nutrient-driven autonomic states (e.g., "Nutritional Anxiety" induced by caffeine or hypoglycemia) and psychogenic states (e.g., clinical anxiety or emotional stress). It establishes frameworks for detecting emotional eating via machine learning (ML) trained on multimodal datasets like WESAD and SWELL, and proposes a "Cognitive Clarity Score" derived from the stability of glycemic regulation and objective vigilance markers.

The analysis indicates that post-prandial amino acid concentrations, particularly the Tryptophan:Large Neutral Amino Acid (LNAA) ratio and Tyrosine availability, have measurable downstream effects on autonomic tone that can be proxied by specific HRV frequency domain features. Furthermore, the report identifies distinct biosignal patterns associated with micronutrient deficiencies (Zinc, Magnesium, B-Vitamins) that mimic anxiety disorders, offering a pathway for the engine to provide differential nutritional feedback. By synthesizing data from clinical trials on glycemic variability and open-source machine learning repositories, we define the variables necessary for a robust, privacy-centric, on-device analytical engine.

## 2. The Neuro-Metabolic Interface: Theoretical Foundation

The human body functions as a complex network of feedback loops where nutritional input dictates physiological output, which in turn frames psychological experience. This concept, known as the Gut-Brain Axis (GBA), has transitioned from theoretical neuroscience to a quantified reality potentially accessible through wearable technology. For the developer of an iOS-based on-device engine, the challenge is not merely data collection but signal semanticization—giving meaning to raw biometric data. A drop in Heart Rate Variability (HRV) is a non-specific marker of stress. However, when time-stamped against nutritional intake, that same drop can be decoded as reactive hypoglycemia, caffeine sensitivity, or acute tryptophan depletion.

This engine must operate on the principle that the Autonomic Nervous System (ANS) acts as the primary transducer between metabolic status and cognitive state. The ANS, monitored via HRV, reflects the body's flexibility in responding to internal and external stressors. Nutrition acts as a primary modulator of this system. Precursors to neurotransmitters, inflammatory cytokines triggered by poor diet, and glucose fluctuations all exert pressure on the ANS, shifting the balance between the sympathetic (fight-or-flight) and parasympathetic (rest-and-digest) branches. The following sections dissect these interactions to provide the logic gates for the proposed engine.

## 3. Post-Prandial Amino Acid Dynamics and Autonomic Tone

The modulation of the autonomic nervous system by dietary precursors to neurotransmitters is a foundational component of nutritional psychology. The engine must track and predict the physiological impact of specific amino acids—Tryptophan (TRP) and Tyrosine (TYR)—based on meal composition, timing, and co-factors like B-vitamins.

### 3.1 Tryptophan, Serotonin Synthesis, and Vagal Tone

Tryptophan is the precursor to serotonin (5-HT), a neurotransmitter essential for mood regulation, sleep, and intestinal motility. Research confirms that peripheral TRP availability influences central 5-HT synthesis, which in turn modulates vagal tone, detectable via HRV.

#### 3.1.1 The Insulin-LNAA Transport Mechanism

Tryptophan competes with other Large Neutral Amino Acids (LNAAs)—such as valine, leucine, isoleucine, tyrosine, and phenylalanine—for transport across the blood-brain barrier (BBB) via the L-type amino acid transporter 1 (LAT1). This competition is the rate-limiting step for central serotonin synthesis.

The engine must incorporate an algorithm that accounts for the "Carbohydrate-Insulin Connection." Carbohydrate ingestion triggers insulin release, which promotes the uptake of branched-chain amino acids (BCAAs) into skeletal muscle. Crucially, Tryptophan binds to albumin in the blood and is less affected by insulin-mediated clearance than other LNAAs. Consequently, a high-carbohydrate meal lowers the plasma concentration of competing LNAAs while preserving Tryptophan, thereby increasing the plasma TRP:LNAA ratio and facilitating TRP entry into the brain.1

Conversely, a high-protein meal increases the total concentration of all amino acids. Since LNAAs are more abundant in dietary proteins than Tryptophan, a protein-heavy meal (without sufficient carbohydrates) lowers the TRP:LNAA ratio, potentially blunting the serotonergic response.2 Studies using alpha-lactalbumin (a whey protein fraction rich in TRP) have shown that it is possible to boost this ratio via protein, provided the specific amino acid profile is favorable.2

#### 3.1.2 Tryptophan Depletion and Autonomic Instability

Acute Tryptophan Depletion (ATD) studies provide a critical negative control model for the engine. ATD has been shown to reduce HRV, specifically in the High-Frequency (HF) band (0.15–0.4 Hz), which reflects parasympathetic (vagal) tone. This effect is not uniform across the population; research indicates that the drop in HRV following TRP depletion is most pronounced in individuals with a history of depression, suicidal ideation, or high trait aggression.4 In female populations, ATD has been linked to significant mood lowering and autonomic dysregulation, highlighting a gender-specific sensitivity that the engine should account for.6

The "Depletion Signature" the engine should scan for involves a progressive decline in RMSSD (Root Mean Square of Successive Differences) and HF-HRV in the 3–5 hours post-prandial window following low-quality, low-protein intake, or during extended fasting where catabolism increases circulating LNAAs relative to TRP.3

#### 3.1.3 Supplementation, Timing, and Co-factors

Recent trials suggest that the timing of TRP ingestion is critical. TRP supplements taken _between_ meals (when insulin is low but LNAA competition is minimized relative to a protein-heavy meal) have been shown to improve mood in subclinical depression without significantly altering baseline ANS activity in the short term, although severe depression subgroups showed distinct responsiveness.1 Furthermore, the conversion of TRP to serotonin requires Vitamin B6 (pyridoxal 5'-phosphate) as a cofactor. Research indicates that combined supplementation of TRP, Vitamin B6, and Nicotinamide can improve depressive mood states, likely by facilitating the enzymatic pathway from TRP to 5-HT.1The engine should therefore distinguish between "Meal-Derived TRP" (subject to LNAA competition) and "Isolated TRP" (rapid absorption), and factor in B-vitamin status if available.

### 3.2 Tyrosine, Catecholamines, and the Stress Buffer

Tyrosine is the precursor to dopamine (DA) and norepinephrine (NE). Unlike TRP, which is often associated with relaxation (via serotonin and melatonin), TYR is critical for cognitive flexibility and maintaining performance under stress.

#### 3.2.1 The "Tyrosine Paradox" in Biosignal Data

While catecholamines are typically associated with sympathetic arousal (increasing Heart Rate, lowering HRV), TYR supplementation has been observed to reduce physiological arousal signatures under specific conditions. This "Tyrosine Paradox" is vital for the engine's interpretation logic.

In tasks requiring high cognitive control (e.g., task switching, stopping, reinforcement learning), TYR supplementation (2g) was found to reduce Heart Rate (HR) and increase pupil dilation variability (a marker of locus coeruleus-norepinephrine activity efficiency).7 The mechanism posits that under stress, catecholamine turnover increases, leading to depletion. TYR provides the substrate to sustain optimal firing rates, preventing the "panic" sympathetic overshoot that occurs when the brain struggles to maintain cognitive control with depleted resources.10

Therefore, the engine should interpret TYR intake not as a stimulant, but as a stabilizer. If the user is in a high-stress state (detected via low HRV and high skin conductance), TYR intake should be correlated with a blunting of further HRV decline, rather than an increase in RHR. This is a critical differentiation from caffeine, which typically potentiates stress responses.8

#### 3.2.2 Detecting the "Cognitive Buffer"

The physiological signature of effective TYR utilization is the maintenance of "Vagal Brake" efficiency during cognitive load. In a high-demand context (e.g., a calendar event marked "Meeting" or "Deep Work"), the engine compares pre-TYR vs. post-TYR biometrics. Effective TYR fueling presents as stable Reaction Times (if measured) and preserved HF-HRV despite the stressor, whereas a placebo/non-fueled state would show a steeper drop in HRV and slower reaction times.7 This buffering effect is particularly relevant for older adults, as tyrosine's effect on proactive inhibition appears to be age-dependent, interacting with the decline in dopamine availability.12

### 3.3 Summary of Amino Acid Biometric Profiles

The following table summarizes the anticipated biometric profiles the engine uses to correlate amino acid intake with autonomic states:

|**Amino Acid**|**Precursor To**|**Transport Logic**|**Wearable Signature (Acute)**|**Contextual Trigger**|
|---|---|---|---|---|
|**Tryptophan**|Serotonin, Melatonin|Insulin-dependent; Inhibited by BCAA|Increase in RMSSD/HF-HRV (delayed 2-4h); Reduced sleep onset latency.|High Carb/Low Protein Dinner; Isolated Supplement.|
|**Tyrosine**|Dopamine, Norepinephrine|Transporter dependent; Depleted by Stress|_Prevention_ of HR spike during stress; Stability of HRV during cognitive load.|High Stress Work Block; Sleep Deprivation.|
|**BCAAs**|Muscle Protein|Competes with TRP/TYR|Potential _decrease_ in mood/HRV if consumed in isolation by prone individuals (due to DA/5-HT precursor blockade).|Pre-workout supplements without Carb co-factor.|

## 4. Physiological Signatures of 'Nutritional Anxiety'

A core value proposition of the engine is differentiating "Nutritional Anxiety"—symptoms arising from metabolic or chemical imbalances—from psychogenic anxiety. This requires analyzing the nuances of HRV, RHR, and waveform morphology to identify specific micronutrient deficiencies and stimulant effects.

### 4.1 The Micronutrient Deficiency Signature: Zinc, Magnesium, and B-Vitamins

Chronic deficiencies in specific micronutrients manifest as a rigid autonomic system with limited variability, mimicking the physiological profile of Generalized Anxiety Disorder (GAD).

#### 4.1.1 Magnesium (Mg): The Physiological Relaxant

Magnesium acts as a natural calcium channel blocker and cofactor for GABA synthesis. Deficiency leads to intracellular calcium overload and sympathetic hyperactivity, often resulting in a state of chronic low-level anxiety or "tired-but-wired" physiology.

Magnesium supplementation (e.g., 300-400 mg/day) has been extensively shown to increase HRV indices, specifically pNN50 (percentage of successive RR intervals varying by >50ms) and RMSSD.13 Deficiency is linked to lower vagal tone and higher susceptibility to arrhythmias, which may appear as noise or irregularities in PPG data.17

The "Mg-Signature" for the engine involves identifying users with a chronically low "Baseline HRV" relative to their age and fitness norms, combined with a high "Stress Index" (an algorithmic derivation of HRV histogram width). If this profile persists despite adequate sleep and low reported psychological stress, the engine flags potential Mg deficiency.13 Validation occurs when supplementation leads to a measurable increase in nocturnal RMSSD and a decrease in RHR within 4-8 weeks.15

#### 4.1.2 Zinc (Zn): The Neuroprotective Modulator

Zinc modulates NMDA glutamate receptors and supports Brain-Derived Neurotrophic Factor (BDNF). Deficiency is correlated with reduced HRV and increased sympathetic dominance, particularly in vulnerable populations such as those with hypothyroidism or during pregnancy.20

The signature of Zinc deficiency manifests as "Autonomic Rigidity"—a failure of HRV to rebound quickly after minor stressors. It presents similarly to Mg deficiency but is often accompanied by specific mood disturbances like irritability and depressive symptoms.21 In studies of Parkinson's disease, serum zinc levels were positively correlated with RMSSD, SDNN, and pNN50, reinforcing the link between zinc status and parasympathetic integrity.23

#### 4.1.3 B-Vitamins: The Synthesis Cofactors

Vitamins B6 and B12 are essential cofactors for the synthesis of serotonin, dopamine, and GABA. Deficiency in these vitamins can lead to reduced neurotransmitter availability, manifesting as anxiety and reduced HRV.25

Research suggests that B-vitamin supplementation can help relieve stress and support normal HPA axis function.26 Vitamin B12 deficiency, in particular, has been associated with reduced HRV, and its correction can improve autonomic balance.27 The engine should consider B-vitamin status, potentially inferred from dietary logs (e.g., vegan/vegetarian diets lacking B12), as a variable in the "Nutritional Anxiety" model.

### 4.2 Stimulant-Induced Arousal: Caffeine and Sugar

The engine must distinguish the "Jitter" of stimulants from the "Dread" of anxiety. While both states show high arousal, the _quality_ and _trajectory_ of the biosignals differ.

#### 4.2.1 Caffeine: The Adenosine Antagonist and Stress Potentiator

Caffeine blocks adenosine receptors ($A_1$, $A_{2A}$), preventing relaxation and increasing catecholamine release. This leads to increased blood pressure (BP) via vascular resistance, though its effect on Heart Rate is variable—it can cause bradycardia in some due to the baroreflex or tachycardia in others.28

Crucially, caffeine potentiates the cardiovascular response to mental stress. The "Additive Model" suggests that the BP and HR spike from stress is superimposed onto the caffeine baseline, creating a higher total load.28

In Panic Disorder (PD) patients, caffeine is a known panicogen. Doses as low as 150-480 mg can induce panic attacks in a significant proportion of PD patients, characterized by extreme suppression of HRV indices like RMSSD and pNN50, differentiating this population from healthy controls.32

The "Caffeine Jitter" signature is characterized by rapid onset (30-60 mins), moderate suppression of HF-HRV (vagal withdrawal), but often preservation of Low-Frequency (LF) power (sympathetic/baroreflex). Unlike clinical panic, caffeine jitter typically lacks the respiratory dysregulation (hyperventilation) seen in panic attacks. The engine can use respiratory rate derived from PPG or accelerometer data to differentiate: Stable respiration + High Arousal = Caffeine; Erratic respiration + High Arousal = Panic/Anxiety.35

#### 4.2.2 The "Sugar Crash" (Reactive Hypoglycemia)

High glycemic impact meals lead to an insulin surge followed by a rapid drop in blood glucose. This triggers a counter-regulatory response involving the release of adrenaline and cortisol to mobilize stored glucose, causing palpitations, sweating, and anxiety—a phenomenon known as reactive hypoglycemia.36

The physiological signature is a "Sawtooth" HRV pattern. Phase 1 (Post-Prandial) shows slight HRV suppression due to digestion. Phase 2 (The Crash, ~2-3 hours later) is marked by a sharp drop in RMSSD, a sudden spike in EDA (sweat response), and an increase in RHR. This triad occurring late in the post-prandial window is the hallmark of "Nutritional Anxiety" driven by hypoglycemia.38

### 4.3 Algorithm: Distinguishing Anxiety Types

The following heuristic framework allows the engine to classify the source of high-arousal states:

|**Feature**|**Clinical Anxiety / Panic**|**Nutritional Anxiety (Hypoglycemia)**|**Stimulant Arousal (Caffeine)**|**Nutrient Deficiency (Mg/Zn/B)**|
|---|---|---|---|---|
|**Onset**|Trigger-based or spontaneous; typically rapid.|Delayed post-prandial (2-4 hrs).|Rapid post-ingestion (30-60 mins).|Chronic / Tonic state.|
|**HRV (RMSSD)**|Acute, deep suppression.|Acute suppression during crash.|Moderate suppression.|Chronically low baseline.|
|**EDA (Sweat)**|High (Palmar/Plant response).|High (Adrenergic surge).|Moderate.|Low/Normal.|
|**Respiration**|Irregular, hyperventilation, apnea.|Generally stable.|Stable.|Normal.|
|**Context**|Psychological trigger present.|Post-high-carb meal.|Post-beverage.|No specific trigger; poor recovery.|
|**Recovery**|Slow, requires regulation.|Rapid after glucose intake.|Slow (half-life dependent).|No immediate recovery.|

## 5. Machine Learning Frameworks for 'Emotional Eating Detection'

Emotional eating is characterized by the consumption of food in response to negative affect rather than hunger. The engine utilizes "Pre-Meal HRV Baselines" and other biosignals to classify eating events.

### 5.1 Physiological Basis of Hunger vs. Stress

To detect emotional eating, the engine must distinguish between the physiology of true hunger and that of stress.

Hunger (The "Fueling" Meal): Physiological hunger in the fasted state is often associated with increased parasympathetic tone (high HRV) and lower RHR as the body conserves energy. The cephalic phase of digestion, triggered by the anticipation of food, involves vagal activation.39 Ghrelin, the hunger hormone, has been linked to increased vagal tone.43

Stress (The "Stress-Induced" Meal): Stress eating is preceded by sympathetic dominance (Low HRV, High Skin Conductance) and negative affect. The vagal "brake" is released before the meal, creating a distinct pre-prandial signature.45

### 5.2 Machine Learning Models and Datasets

The development of the "Emotional Eating" classifier relies on multimodal datasets. The **WESAD** (Wearable Stress and Affect Detection) dataset is the gold standard, providing ECG, EDA, EMG, and temperature data labeled with baseline, stress, and amusement states.47 The **SWELL** dataset is another valuable resource, focusing on stress in knowledge work contexts.50

#### 5.2.1 Feature Selection and Engineering

Feature selection is critical for efficient on-device processing. Research indicates that combining HRV with EDA significantly increases classification accuracy.

- **Time-Domain Features:** RMSSD and Mean RR interval are robust features for short-window analysis.51
    
- **Frequency-Domain Features:** Normalized HF (HFnu) and LF/HF ratio describe the sympathovagal balance.
    
- **Non-Linear Features:** Sample Entropy (SampEn) or Detrended Fluctuation Analysis (DFA) can capture the complexity loss associated with stress.52
    
- **EDA Features:** Frequency of peaks (SDRR_RMSSD_REL_RR) and amplitude of skin conductance responses are powerful differentiators of sympathetic arousal.48
    
- **Fusion:** Integrating HRV and EDA data has been shown to achieve accuracies greater than 90% in distinguishing stress from non-stress states, superior to using either modality alone.20
    

#### 5.2.2 Classifier Architectures

Various machine learning algorithms have been validated for stress detection on these datasets:

- **Random Forest (RF):** Consistently performs well, with reported accuracies of up to 95.2% on person-specific models using the SWELL dataset.50 It is robust to overfitting and handles non-linear data well.
    
- **Support Vector Machines (SVM):** A common choice for binary classification (Stress vs. No Stress), achieving ~83% accuracy in driver stress studies.50
    
- **Deep Learning:** Convolutional Neural Networks (CNNs) and Recurrent Neural Networks (RNNs) offer high accuracy but may be computationally expensive for on-device deployment without optimization.55
    
- **Feature Selection Methods:** Techniques like Minimum Redundancy Maximum Relevance (mRMR) and Recursive Feature Elimination (RFE) are essential to identify the most relevant HRV features (e.g., Median Absolute Deviation of RR intervals) and reduce model complexity.50
    

#### 5.2.3 Differentiating Physical vs. Mental Stress ("Stationary Arousal")

A common confounder is post-exercise eating, which also presents with low HRV. The engine must distinguish "Physical Stress" from "Mental Stress" by integrating accelerometer data.

- **Physical Stress:** Low HRV + High Accelerometer Activity (Movement).
    
- **Mental Stress (Stationary Arousal):** Low HRV + Low Accelerometer Activity (Stationary) + High EDA. This "Stationary Arousal" is the key signature of emotional stress.48
    

### 5.3 Open Source Repositories and Implementation

Several open-source projects provide code and frameworks relevant to this engine.

- **`yasirroni/HRV-Stress`:** Provides notebooks for correlation analysis and machine learning (RF, SVM, etc.) on HRV data.56
    
- **`luke-plewa/istress`:** An IoT solution using Microsoft Band data and classifiers (Decision Trees, SVM, Naive Bayes) hosted on Google Cloud to indicate stress.57
    
- **`pmadruga/ml_project`:** Applies supervised and unsupervised learning to HRV data from Apple Watch for stress prediction.58
    
- ronibandini/hr-hrv: Focuses on ECG stress detection using machine learning on embedded systems.59
    
    These repositories offer valuable starting points for feature extraction code and model training pipelines.
    

### 5.4 Proposed Heuristic Framework for the Engine

Based on the research, the engine should implement a "Context-Aware Classifier."

Algorithm Flow:

1. **Trigger:** User logs a meal or gesture detection suggests eating.
    
2. **Lookback Window:** Analyze the preceding 30 minutes of biometric data.
    
3. **Classification Logic:**
    
    - _If_ `Baseline_HRV` > `User_Norm` AND `EDA` is Stable $\rightarrow$ **Fueling Meal**.
        
    - _If_ `Baseline_HRV` < (`User_Norm` - 1.5 SD) AND `EDA` shows Peaks AND `Activity` is Low $\rightarrow$**Stress-Induced Meal**.
        
    - _If_ `Baseline_HRV` < (`User_Norm` - 1.5 SD) AND `Activity` is High $\rightarrow$ **Post-Exercise Meal**.
        
4. **Feedback Loop:** The engine prompts the user ("You seem elevated. Is this a fuel-up or a destress meal?") to gather ground truth labels for model personalization.
    

## 6. The 'Cognitive Clarity Score'

The Cognitive Clarity Score (CCS) is a composite metric representing the brain's functional capacity, heavily influenced by glycemic stability and objective vigilance markers.

### 6.1 Glycemic Variability and Neurocognitive Performance

Research establishes a strong link between glucose fluctuations—both hypo- and hyperglycemia—and impaired cognitive function.

- **Glycemic Variability (GV):** High GV, often measured by the Mean Amplitude of Glycemic Excursions (MAGE), is an independent predictor of cognitive decline, even more so than mean glucose levels (HbA1c). High GV correlates with worse performance on tests of processing speed (Digit Symbol Substitution Test) and executive function (Stroop Test).60
    
- **Hypoglycemia:** Even mild hypoglycemia (<70 mg/dL) significantly slows choice reaction time and increases error rates in tasks requiring working memory and grammatical decoding.63
    
- **Hyperglycemia:** Acute hyperglycemia (>250 mg/dL) is associated with slower perceptual speed, with a notable "lag" effect where the cognitive penalty is observed ~3 hours later.38
    

### 6.2 Objective Focus Markers from Wearables

To calculate the CCS without Continuous Glucose Monitors (CGM), the engine must use proxy markers for "Brain Fog" or "Clarity."

- **Psychomotor Vigilance:** Reaction time is a sensitive measure of alertness. The engine can infer this from interaction latency (e.g., typing speed, scroll speed, time to unlock phone).
    
- **Sleep Quality Trends:** High glycemic variability, particularly nocturnal hypoglycemia, fragments sleep. A "Restless Sleep" signature (high movement, frequent awakenings) often precedes a day of low cognitive clarity.37
    
- **Vigilance and Autonomic Balance:** Cognitive performance follows an inverted-U shape relative to arousal. An optimal LF/HF ratio correlates with peak vigilance; deviations towards drowsiness (low LF/HF) or anxiety (high LF/HF) reduce clarity.
    

### 6.3 Extracting Variables for the CCS

The **Cognitive Clarity Score (0-100)** is calculated as a weighted composite:

$$CCS = (w_1 \cdot GlycemicStability) + (w_2 \cdot Vigilance) + (w_3 \cdot SleepEfficiency)$$

Where:

1. **Glycemic Stability (Proxy):** Inferred from meal composition logs.
    
    - _High Stability:_ Balanced macronutrients, high fiber, regular timing.
        
    - _Low Stability:_ High glycemic index meals, irregular timing.
        
    - _Correction Factor:_ If the HRV "Sugar Crash" signature (Section 4.2.2) is detected, the Stability score is heavily penalized.
        
2. **Vigilance:** Measured via periodic micro-interactions (e.g., typing error rate, response time to notifications).
    
3. **Sleep Efficiency:** Derived from the previous night's Deep Sleep % and REM %.
    

### 6.4 The "Clarity Loop" Architecture

1. **Input:** User logs a high-sugar breakfast.
    
2. **Prediction:** Engine predicts a CCS drop at T+120 minutes (Reactive Hypoglycemia).
    
3. **Verification:** At T+120, the engine checks for "Stationary Arousal" (HRV drop) and "Sluggish Interaction" (Vigilance drop).
    
4. **Intervention:** The engine suggests a stabilizing intervention (e.g., "Consider a fiber-rich snack to stabilize the crash").
    

## 7. On-Device Architecture and Privacy

To ensure user privacy and low latency, the engine is designed for local processing.

### 7.1 On-Device Processing (CoreML)

All sensitive biometric data is processed locally on the iOS device using CoreML.

- **Data Ingestion:** HealthKit provides the pipeline for HRV (SDNN, RMSSD), RHR, Sleep, and Workout data.
    
- **Preprocessing:** Artifact removal is crucial, especially for PPG-derived HRV. The engine must discard intervals with excessive noise (>20%).48
    
- **Model Deployment:** The "Emotional Eating" classifier and "Nutritional Anxiety" discriminator are trained offline (or via federated learning) and deployed as compiled CoreML models.
    

### 7.2 Sensor Fusion Logic

The engine utilizes a hierarchical sensor fusion approach:

1. **Tier 1 (Always On):** Accelerometer + HR (sampled periodically). Determines context (Active vs. Sedentary).
    
2. **Tier 2 (Event Driven):** HRV + EDA (if hardware supports). Triggered by "Stationary Arousal" or "Meal Log."
    
3. **Tier 3 (User Input):** Mood logs, Meal logs. Used to label ground truth for model personalization.
    

## 8. Conclusion

This research report establishes the scientific viability of an on-device engine capable of decoding the nutritional Gut-Brain-Axis. By isolating the specific HRV frequencies associated with amino acid availability (HF-HRV for Tryptophan/Vagal tone) and distinguishing the physiological signatures of nutrient deficiency (chronic low HRV) from acute stimulant use (sympathetic spikes), the engine offers a granular view of mental health.

The key innovation lies in the **contextualization of biosignals**. HRV is not just a stress marker; it is a metabolic readout. A drop in HRV is not just "stress"—it could be magnesium deficiency, a sugar crash, or a panic attack. By triangulating these signals with meal timing and composition, the proposed engine moves beyond simple tracking to predictive, actionable "Nutritional Psychiatry." Future iterations should focus on integrating continuous glucose monitoring (CGM) data as it becomes more ubiquitous, allowing the "Cognitive Clarity Score" to transition from a proxy model to a direct physiological measurement.