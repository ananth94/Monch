# Monch: UX Concepts & Implementation Spec (Cozy Science Edition)

This document maps the **Priority Insights** to the **"Cozy Science" Design System** and defines the **Approved UX Treatments** based on user selection.

**Design Principle:**
*   **Visuals:** Emotional, Watercolor, Mascot-driven.
*   **Copy:** Direct, Actionable, User-Centric.
*   **Tone:** The mascot provides ambient context; the text provides coaching.

---

## 🍑 Loop 1: The Acute Loop (Immediate Response)
**Theme:** Soft Coral (`#FFA07A`) to Warm Peach (`#FFB7B2`).
**Mascot Vibe:** Hyperactive / Vibrating.

### 1. The Sugar Spike [P0]
*Context: Rapid HR rise >30 mins post-meal.*
*   **Mascot State:** **"Spiking"** (Vibrating, Wide-eyed).

*   **[SELECTED] Treatment A: The "Curve Flattener" (Intervention)**
    *   **Surface:** Push Notification.
    *   **Visual:** Monch is vibrating.
    *   **Copy:** *"Heart rate velocity is high (+15bpm). A 10-minute walk now could flatten the curve."*
    *   **Actions:** "Start Walk" (Mutes future alerts) / "Ignore".

*   **[SELECTED] Treatment B: The "Energy Forecast" (Predictive)**
    *   **Surface:** Lock Screen Live Activity.
    *   **Visual:** A spline chart showing current rise with a dotted line projecting a drop. Monch sits at the peak looking "Dizzy."
    *   **Copy:** *"Energy dip projected at 3:30 PM."*

*   **[SELECTED] Treatment C: The "Metabolic Tag" (Retrospective)**
    *   **Surface:** Timeline UI.
    *   **Visual:** The meal bubble ("Oatmeal") glows Coral. Tapping it shows the HR overlay.
    *   **Copy:** *"This meal triggered a rapid response (+25bpm)."*

### 2. The Anxiety Mimic (Hypoglycemia) [P1]
*Context: Jittery feeling ~2h post-meal due to sugar crash.*
*   **Mascot State:** **"Crashing"** (Melting into a puddle, dizzy eyes).

*   **[SELECTED] Treatment A: The "Reality Check" (Validation)**
    *   **Surface:** Push Notification.
    *   **Visual:** Melting Monch icon.
    *   **Copy:** *"Feeling anxious? It’s likely just a sugar crash from breakfast. It will pass soon."*
    *   **Goal:** Emotional relief.

*   **[SELECTED] Treatment B: The "Check-In" (Data Gathering)**
    *   **Surface:** Interactive Notification (Rich Push).
    *   **Copy:** *"Rapid drop detected. How is your energy?"*
    *   **Actions:** ⚡️ Wired / 📉 Crashed / 🧘 Fine.

### 3. The Caffeine Jitter [P1]
*Context: High Sympathetic Arousal but Stable Respiration.*
*   **Mascot State:** **"Spiking"** (But smiling/focused, not dizzy).

*   **[SELECTED] Treatment A: The "Focus Mode" (Utility)**
    *   **Surface:** Push Notification.
    *   **Copy:** *"High Alert state detected. Perfect time for deep work?"*
    *   **Actions:** "Start Focus Timer" / "Dismiss".

---

## 🌿 Loop 2: The Recovery Loop (Workout)
**Theme:** Sage Green (`#88B04B`) to Mint Cream (`#F5FFFA`).
**Mascot Vibe:** Strong / Glowing.

### 4. The Muscle Sponge (Anabolic Window) [P0]
*Context: Post-Workout window.*
*   **Mascot State:** **"Strong"** (Flexing, Glowing Aura).

*   **[SELECTED] Treatment A: The "Golden Hour" (Gamification)**
    *   **Surface:** Push Notification.
    *   **Visual:** Monch glows gold.
    *   **Copy:** *"Great session! Anabolic Window Open. Carbs will fuel muscle right now."*
    *   **Actions:** "Log Refeed" (Opens Food Logger).

### 5. The "Good" Spike [P0]
*Context: HR High due to Exercise.*
*   **Mascot State:** **"Strong"** (Headband, Running).

*   **[SELECTED] Treatment A: The "Ghost Mode" (Invisible)**
    *   **Mechanism:** Logic Suppression.
    *   **Result:** **SUPPRESS** all "Sugar Spike" alerts while `WorkoutMode == True` or `HR > Zone 3`.

*   **[SELECTED] Treatment B: The "Performance Tag" (Validation)**
    *   **Surface:** Timeline UI.
    *   **Visual:** The HR spike on the graph is colored **Sage Green** (instead of Coral).
    *   **Label:** *"Performance Fueling"* (Validation that this stress was good).

### 6. The Zone 2 Drain [P1]
*Context: Long low-intensity duration.*
*   **Mascot State:** **"Neutral"** (But slimmer/lighter).

*   **[SELECTED] Treatment A: The "Dinner Permission" (Psychological)**
    *   **Surface:** Evening Notification (6 PM).
    *   **Visual:** Monch holding a fork and knife happily.
    *   **Copy:** *"Your walk created a glucose sink. You can handle a heavier dinner tonight."*

*   **[SELECTED] Treatment B: The "Allowance Bump" (Budgeting)**
    *   **Surface:** Home Screen Dashboard.
    *   **Visual:** If a Calorie/Carb Goal bar exists, it visually expands with a "Zone 2 Bonus" segment.

---

## 🔮 Loop 3: The Sub-Acute Loop (Sleep)
**Theme:** Periwinkle (`#CCCCFF`) to Soft Lavender (`#E6E6FA`).
**Mascot Vibe:** Sleepy / Dreamy.

### 7. The Digestion Debt [P0]
*Context: Late meal ruining sleep.*
*   **Mascot State:** **"Sleepy"** (Nightcap, eyes closing).

*   **[SELECTED] Treatment A: The "Causal Link" (Retrospective)**
    *   **Surface:** Morning Summary Card.
    *   **Visual:** A line connects the "Late Meal" bubble to the "High HR" section of the sleep graph. Monch looks groggy.
    *   **Copy:** *"Your 9 PM dinner kept your heart racing until 1 AM."*

*   **[SELECTED] Treatment B: The "Kitchen Closing" (Preventative)**
    *   **Surface:** Push Notification (3h before avg bedtime).
    *   **Visual:** Monch putting on pajamas.
    *   **Copy:** *"Kitchen closing soon. Eating after 8 PM usually drops your Deep Sleep."*
    *   **Actions:** "OK" / "Don't show again".

### 8. The Deep Sleep Robber (Temp) [P1]
*Context: High Body Temp destroying Deep Sleep.*
*   **Mascot State:** **"Sweaty"** (Fan blowing on him, wiping brow).

*   **[SELECTED] Treatment A: The "Cool Down" Tip (Coach)**
    *   **Surface:** Evening Notification.
    *   **Copy:** *"Last night was hot. Try a cold shower or lower room temp to counter the thermal load."*

*   **[SELECTED] Treatment B: The "Heat Map" (Data)**
    *   **Surface:** Sleep Detail View.
    *   **Visual:** Overlay Body Temp gradient on top of Sleep Stages.
    *   **Highlight:** Red zones over Light Sleep.

---

## 📦 Backlog Concepts

### The Caffeine Jitter
*   **[BACKLOG] Concept B: The "Vibe Shift" (Ambient)**
    *   *Mechanism:* Home Screen Background shifts to "Vibrating" texture.
    *   *Reason:* Requires complex shader implementation (MeshGradient animation). Pushed to V2.

### The Muscle Sponge
*   **[BACKLOG] Concept B: The "Smart Menu" (Contextual UI)**
    *   *Mechanism:* Context-aware food suggestions in Logger.
    *   *Reason:* Requires tagging food database with GI Index and creating dynamic sorting logic. Pushed to V2.
