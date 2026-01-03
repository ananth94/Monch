# Monch: Engineering Backlog

## 🧪 Phase 0: Prototyping (Spikes)
*Goal: De-risk key technical assumptions before building infrastructure.*
- [ ] **Spike: HealthKit Query Latency:** Verify query performance for 7-day granular HR data (direct query vs cached).
- [ ] **Spike: Mascot Animation:** Prototype the "Squish/Bounce" animation physics in SwiftUI to ensure 60fps performance.

---

## 🏗 Phase 1: The Foundation (Skeleton)
*Goal: A running app that can read HealthKit and store data locally.*

### 1.1 Project Scaffolding
- [ ] **Init Project:** Create iOS App (SwiftUI, SwiftData). Set deployment target to iOS 17+.
- [ ] **Data Model:** Define SwiftData schemas:
    - `MealLog` (timestamp, macros, contextTags)
    - `InsightEvent` (type, associatedLogID, severity)
    - `MascotState` (currentMood, activeModifiers)
    - *Note: No local Biometric storage. HealthKit is the Source of Truth.*
- [ ] **Design System:** Implement `Color+Monch.swift` (Pastels), `Font+Monch.swift` (Rounded), and `MeshGradient` views.

### 1.2 HealthKit Manager
- [ ] **Permissions:** Implement `HealthKitManager` class to request read access.
- [ ] **Data Ingest:** Create `HealthKitReader` actor with convenience methods (`fetchSleep`, `fetchWorkout`, `fetchHRStream`).
- [ ] **Privacy:** Add Usage Descriptions to Info.plist with "Privacy-First" copy.

### 1.3 The "River" UI Shell
- [ ] **Timeline View:** Build the vertical scrolling list with "Day Headers."
- [ ] **Empty State:** Implement the "Ghost Timeline" design for Day 0.
- [ ] **Navigation:** Setup basic Tab or Sheet navigation.

### 1.4 Dev Tools (Simulator Support)
- [ ] **Mock Data Seeder:** Build a debug menu to inject fake HealthKit data (Sleep, Workouts, HR Spikes) into the Timeline for Simulator testing.

---

## 🍎 Phase 2: The Input Layer (Feeding Monch)
*Goal: Frictionless data entry and passive tracking.*

### 2.1 Food Logger
- [ ] **API Client:** Build `FoodDataClient` (OpenFoodFacts networking, parsing, error handling).
- [ ] **Search UI:** Build the Search Bar, Results List, and "Add" interaction.
- [ ] **Data Persistence:** Save `MealLog` to SwiftData.

### 2.2 Passive Context Service
- [ ] **Workout Sync:** Background task to auto-import `HKWorkout` objects to the Timeline.
- [ ] **Context Engine:** Implement `ContextManager` logic:
    - *Refeed:* Tag meals <2h post-workout.
    - *Circadian:* Tag meals <2h before `SleepStart` (Dynamic, not fixed time).
- [ ] **Micro-Loggers:** Build "Caffeine" and "Supplement Stack" quick-add buttons.

---

## 🧠 Phase 3: The Intelligence Layer (The Brain)
*Goal: Transforming data into insights.*

### 3.1 Insight Engine
- [ ] **Engine Actor:** Create the central `InsightEngine` that observes `MealLog` inserts.
- [ ] **Logic Gates:** Implement the heuristic algorithms:
    - `SugarSpikeDetector` (HR Velocity)
    - `RecoveryValidator` (Refeed Logic)
    - `DigestionDebt` (Sleep Logic)

### 3.2 Verification
- [ ] **Unit Tests:** Create `SugarSpikeTests.swift` and `RecoveryTests.swift`. Feed mock arrays of HR data to assert `InsightEvent` generation.

---

## 📣 Phase 3.5: The Feedback Layer (Outputs)
*Goal: Delivering the insights to the user.*

### 3.5.1 Notification Manager
- [ ] **Permissions:** Request Notification access.
- [ ] **Scheduler:** Build logic to schedule "Kitchen Closing" nudges (predictive) vs "Immediate Alerts" (reactive).

### 3.5.2 Live Activities
- [ ] **Widget:** Build the `MascotWidget` for Lock Screen / Dynamic Island.
- [ ] **Updates:** Connect `InsightEngine` output to `ActivityAttributes` update.

---

## 🧸 Phase 4: The "Cozy" Layer (Design)
*Goal: Making it feel like a companion.*

### 4.1 Mascot Architecture
- [ ] **State Machine:** Define `MascotStateManager` (Input: Context -> Output: State Enum).
- [ ] **View Component:** Build the `MascotHeader` view that renders the correct asset.

### 4.2 Visual Polish
- [ ] **River Cards:** Style timeline items with "Bubble" backgrounds and watercolor assets.
- [ ] **Insight Cards:** Implement the "Journal Entry" design.
- [ ] **Haptics:** Add custom `UIImpactFeedbackGenerator` patterns (Soft/Heavy).

---

## 🧪 Phase 5: Calibration & Release
*Goal: Ground truth and polish.*

### 5.1 Subjective Logging
- [ ] **Vibe Check:** Build the "Energy/Focus/Mood" logging modal.
- [ ] **Calibration:** Update Engine to accept Subjective inputs as ground truth.

### 5.2 Release Prep
- [ ] **Onboarding:** Build the "Privacy Handshake" flow.
- [ ] **App Icon:** Finalize assets.
- [ ] **Screenshots:** Generate App Store assets using Mock Data.

---

## 🔭 Phase 6: V1.1 (Trends & Chronic Loops)
*Goal: Long-term analysis (Post-MVP).*
- [ ] **Trend Engine:** Aggregation of weekly RHR/HRV.
- [ ] **Mineral Gap:** Logic for detecting chronic recovery issues.
- [ ] **Brain Fog Forecast:** Predictive model based on previous day's Glycemic Variability.
