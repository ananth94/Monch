# Monch Mascot User Experience

This document defines how the Monch mascot is integrated into the app experience, including its placement, animations, and interaction model.

## 1. Interaction Model: The "Monch View"
Monch is the primary emotional lens for the user's metabolic data. While the Home Screen provides an ambient glance, the "Monch View" provides deep context.

### 1.1 Home Screen Header (Ambient)
*   **Placement:** Fixed at the top of the Timeline.
*   **Size:** 64x64.
*   **Interaction:** Tapping the header triggers a full-screen sheet expansion (The Monch View).
*   **Visuals:** Reflects the current real-time state (Neutral, Hungry, Spiking, etc.).

### 1.2 The expanded Monch View (Focused)
When expanded, Monch takes center stage to explain the current "vibe" of the user's metabolism.
*   **Hero Mascot:** Large animated version (200x200).
*   **Direct Coaching:** Clear, actionable text (e.g., "A 10-minute walk now could flatten this curve").
*   **Quick Actions:** Contextual buttons based on the mood (e.g., "Log Meal" during Hungry, "Add Walk" during Spiking).
*   **Data Summary:** High-level metrics explaining *why* Monch feels this way (e.g., "Last meal: 3h ago").

---

## 2. Animation System
Animations are derived from **static assets** using SwiftUI modifiers to create a "living" mascot without the overhead of video or complex Lottie files for every minor state.

### 2.1 Global Idle Behaviors
All states (unless noted) share a subtle base animation:
*   **Breathing:** A very slow `scaleEffect` pulse (1.0 to 1.02) over ~2-3 seconds.
*   **Floating:** A tiny vertical `offset` oscillation (2pt) to give a weightless, "bloomy" feel.

### 2.2 State-Specific Animations

| State | Animation Treatment | Logic |
| :--- | :--- | :--- |
| **Neutral** | Base Breath | Smooth, rhythmic. |
| **Hungry** | Eager Bounce | Vertical `offset` hop + slight rotation anticipation. |
| **Full** | Content Sway | Very slow side-to-side `rotationEffect`. |
| **Spiking** | Jitter/Vibration | High-frequency `offset` jitter + Coral "glow" overlay. |
| **Crashing** | The "Melt" | Slumping Y-offset + slight desaturation of the asset. |
| **Sleepy** | The "Nod" | Head-heavy `rotationEffect` + 50% slower breathing. |
| **Strong** | Power Pulse | 1.1x scale expansion on pulse + Sage "aura" overlay. |

---

## 3. Surface Mapping

| Surface | Asset Type | Context |
| :--- | :--- | :--- |
| **Home Screen** | Watercolor (In-App) | Ambient status + Entry to Monch View. |
| **Insight Cards** | Watercolor (In-App) | Retrospective validation on the timeline. |
| **Empty States** | Watercolor (In-App) | Onboarding / Education (e.g., "Wake up Monch"). |
| **Dynamic Island** | 8-Bit (Pixel) | Real-time spike/crash monitoring. |
| **Notifications** | 8-Bit (Pixel) | Urgent intervention alerts. |
| **Watch / Widget** | 8-Bit (Pixel) | Glanceable status without opening the app. |

---

## 4. Copy Guidelines
*   **Mascot provides the EMOTION.** (Visually dizzy = "Something is wrong").
*   **Text provides the LOGIC.** (Copy = "Your blood sugar is dropping").
*   **Tone:** Supportive and non-judgmental. We use "You" (User-focussed) to make the coaching direct, while Monch acts as the sympathetic companion experiencing the data with you.
