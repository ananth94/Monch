//
//  InsightEngine.swift
//  monch
//
//  The "Brain" of Monch. Analyzes meals against HealthKit data to detect
//  metabolic insights (Sugar Spike, Digestion Debt, etc.) and updates mascot mood.
//

import Foundation
import HealthKit
import SwiftData
import Combine

@MainActor
class InsightEngine: ObservableObject {
    static let shared = InsightEngine()
    private static let lastMorningCheckAnchorKey = "InsightEngine.lastMorningCheckAnchor"
    
    // MARK: - Published State
    
    @Published var currentMood: MascotMoodState = .neutral
    @Published var pendingInsights: [InsightEvent] = []
    
    // MARK: - Dependencies
    
    private let healthKitProvider: any HealthKitDataProvider
    
    private init() {
        self.healthKitProvider = HealthKitManager.shared
    }
    
    /// Testing initializer with injectable provider
    init(healthKitProvider: any HealthKitDataProvider) {
        self.healthKitProvider = healthKitProvider
    }
    
    // MARK: - Public API
    
    /// Analyze a meal and generate insights. Call after logging a meal.
    /// - Parameters:
    ///   - meal: The meal that was just logged
    ///   - modelContext: SwiftData context to persist insights
    /// - Returns: Array of generated insights
    @discardableResult
    func analyzeMeal(_ meal: MealLog, in modelContext: ModelContext) async -> [InsightEvent] {
        var insights: [InsightEvent] = []
        
        // Phase 1: Apply context tags FIRST
        await applyContextTags(to: meal, modelContext: modelContext)

        // Acute stimulant interpretation belongs on the meal/event path so feedback
        // stays timely for explicit caffeine logs.
        if meal.consumableEventKind == .caffeine || (meal.caffeine ?? 0) > 0 {
            let recentMeals = recentMeals(since: Date().addingTimeInterval(-4 * 3600), in: modelContext)
            if let caffeineJitter = await detectCaffeineJitter(for: recentMeals),
               persistInsightIfNeeded(caffeineJitter, in: modelContext) {
                insights.append(caffeineJitter)
            }
        }
        
        // Phase 2: Check for Muscle Sponge (post-workout anabolic window)
        if let muscleSponge = await detectMuscleSponge(for: meal, modelContext: modelContext) {
            if persistInsightIfNeeded(muscleSponge, in: modelContext) {
                insights.append(muscleSponge)
                // Send notification for positive reinforcement
                NotificationManager.shared.notifyMuscleSponge()
            }
        }
        
        // Phase 3: Check for Sugar Spike (with Good Spike suppression)
        // Skip if in exercise context OR if meal is tagged as "refeed"
        if !meal.autoTags.contains("refeed") {
            if let sugarSpike = await detectSugarSpike(for: meal, modelContext: modelContext) {
                if persistInsightIfNeeded(sugarSpike, in: modelContext) {
                    insights.append(sugarSpike)
                    // Send notification alert
                    NotificationManager.shared.notifySugarSpike(mealName: meal.name)
                }
            }
        }
        
        // Phase 4: Check for Digestion Debt (late eating)
        if let digestionDebt = await detectDigestionDebt(for: meal) {
            if persistInsightIfNeeded(digestionDebt, in: modelContext) {
                insights.append(digestionDebt)
                // Send notification (will appear next morning)
                NotificationManager.shared.notifyDigestionDebt()
            }
        }
        
        // Update mascot mood based on insights
        updateMood(from: insights, meal: meal)
        
        return insights
    }

    /// Analyze a workout and generate workout-context insights.
    /// Call after logging or syncing a workout.
    @discardableResult
    func analyzeWorkout(_ workout: WorkoutLog, in modelContext: ModelContext) async -> [InsightEvent] {
        var insights: [InsightEvent] = []

        if let zone2Drain = detectZone2Drain(for: workout),
           persistInsightIfNeeded(zone2Drain, in: modelContext) {
            insights.append(zone2Drain)
        }

        if let latestInsight = insights.max(by: { $0.timestamp < $1.timestamp }) {
            currentMood = moodFromInsight(latestInsight.type)
        }

        return insights
    }

    /// Analyze a subjective vibe check against recent meal and biomarker context.
    /// This is the safest runtime path for Anxiety Mimic because it anchors the
    /// inference to an explicit "I feel off" moment instead of guessing from meals alone.
    @discardableResult
    func analyzeVibeCheck(_ vibe: VibeCheck, in modelContext: ModelContext) async -> [InsightEvent] {
        var insights: [InsightEvent] = []

        // Keep the trigger conservative: only inspect meal-driven anxiety mimic when
        // the user reports a noticeably low energy/focus state.
        guard vibe.energy <= 2 || vibe.focus <= 2 || vibe.average <= 2.5 else {
            return insights
        }

        let referenceDate = vibe.timestamp
        let mealWindowStart = referenceDate.addingTimeInterval(-3.5 * 3600)
        let mealWindowEnd = referenceDate.addingTimeInterval(-2 * 3600)
        let candidateMeals = recentMeals(since: mealWindowStart, until: mealWindowEnd, in: modelContext)
            .filter { !$0.isConsumableEvent }
            .filter { ($0.carbs ?? 0) > 40 || $0.autoTags.contains("high-carb") }

        // If a recent caffeine event exists, prefer the stimulant interpretation path
        // and avoid surfacing an overly confident blood-sugar explanation.
        let recentConsumables = recentMeals(since: referenceDate.addingTimeInterval(-4 * 3600), until: referenceDate, in: modelContext)
        let hasRecentCaffeine = recentConsumables.contains { meal in
            meal.consumableEventKind == .caffeine || (meal.caffeine ?? 0) > 0
        }
        guard !hasRecentCaffeine else { return insights }

        for meal in candidateMeals.sorted(by: { $0.timestamp > $1.timestamp }) {
            if let anxietyMimic = await detectAnxietyMimic(for: meal, in: modelContext, at: referenceDate),
               persistInsightIfNeeded(anxietyMimic, in: modelContext) {
                insights.append(anxietyMimic)
                break
            }
        }

        if let latestInsight = insights.max(by: { $0.timestamp < $1.timestamp }) {
            currentMood = moodFromInsight(latestInsight.type)
        }

        return insights
    }

    /// Run daily morning checks once per day after sleep data is available.
    @discardableResult
    func runMorningChecksIfNeeded(in modelContext: ModelContext, now: Date = Date()) async -> [InsightEvent] {
        let latestSleepEnd = latestCompletedSleepEnd(in: modelContext, now: now)
        let anchor = latestSleepEnd ?? now

        if let lastAnchor = UserDefaults.standard.object(forKey: Self.lastMorningCheckAnchorKey) as? Date,
           lastAnchor >= anchor,
           Calendar.current.isDate(lastAnchor, inSameDayAs: now) {
            return []
        }

        let insights = await runMorningChecks(in: modelContext, now: now)
        UserDefaults.standard.set(anchor, forKey: Self.lastMorningCheckAnchorKey)
        return insights
    }
    
    /// Update the mascot mood based on current state
    /// This can be called independently to refresh mood from existing data
    func refreshMood(meals: [MealLog], insights: [InsightEvent]) {
        // Get most recent relevant insight
        let recentInsights = insights.filter { 
            $0.timestamp.timeIntervalSinceNow > -3600 * 4 // Last 4 hours
        }
        
        if let latestInsight = recentInsights.sorted(by: { $0.timestamp > $1.timestamp }).first {
            currentMood = moodFromInsight(latestInsight.type)
        } else if let latestMeal = meals.first {
            // No recent insights, check meal timing
            let timeSinceMeal = Date().timeIntervalSince(latestMeal.timestamp)
            
            if timeSinceMeal < 1800 { // Within 30 min of eating
                currentMood = .digesting
            } else if timeSinceMeal > 3600 * 4 { // More than 4 hours since eating
                currentMood = .hungry
            } else {
                currentMood = .neutral
            }
        } else {
            currentMood = .hungry // No meals logged
        }
    }
    
    // MARK: - Sugar Spike Detection (P0)
    
    /// Detect if a meal caused a sugar spike based on HR data
    /// Algorithm from Insights_Library.md:
    /// - Trigger: meal.carbs > 30g
    /// - Window: 0-60 min post-meal
    /// - Logic: peak HR > baseline + 15bpm AND time_to_peak < 40min
    /// - Gate: steps < 10 (sedentary), NOT in exercise context (Good Spike suppression)
    private func detectSugarSpike(for meal: MealLog, modelContext: ModelContext) async -> InsightEvent? {
        // Good Spike Suppression: Skip if user is exercising or just finished
        if await isInExerciseContext(at: meal.timestamp, modelContext: modelContext) {
            return nil
        }
        
        // Check carb threshold
        guard let carbs = meal.carbs, carbs > 30 else { return nil }
        
        // Define time windows
        let mealTime = meal.timestamp
        let baselineStart = mealTime.addingTimeInterval(-1800) // 30 min before
        let windowEnd = mealTime.addingTimeInterval(3600) // 60 min after
        
        // For real-time detection, we can only analyze if enough time has passed
        // or we can create a "predicted" insight immediately after high-carb meal
        let now = Date()
        
        if now < windowEnd {
            // Not enough time has passed - create a predicted insight
            return createPredictedSugarSpike(for: meal)
        }
        
        // Fetch HR data using provider
        do {
            let baselineRange = baselineStart...mealTime
            let postMealRange = mealTime...windowEnd
            
            let baselineHR = try await healthKitProvider.fetchHeartRateSamples(for: baselineRange)
            let postMealHR = try await healthKitProvider.fetchHeartRateSamples(for: postMealRange)
            
            // Calculate baseline median
            let baselineValues = baselineHR.map(\.bpm)
            guard !baselineValues.isEmpty else { return nil }
            let baseline = baselineValues.sorted()[baselineValues.count / 2]
            
            // Find peak in post-meal window
            var peak: Double = 0
            var peakTime: Date?
            for sample in postMealHR {
                if sample.bpm > peak {
                    peak = sample.bpm
                    peakTime = sample.timestamp
                }
            }
            
            guard let peakTime = peakTime else { return nil }
            
            // Check thresholds
            let timeToPeak = peakTime.timeIntervalSince(mealTime) / 60 // minutes
            let hrIncrease = peak - baseline
            
            if timeToPeak < 40 && hrIncrease > 15 {
                // Sugar spike detected!
                let severity = min(hrIncrease / 30, 1.0) // Normalize to 0-1
                
                return InsightEvent(
                    timestamp: peakTime,
                    type: .sugarSpike,
                    severity: severity,
                    message: "Your heart rate spiked +\(Int(hrIncrease)) bpm after that meal. Consider a short walk to flatten the curve.",
                    associatedMealID: meal.id
                )
            }
        } catch {
            print("InsightEngine: Failed to fetch HR data: \(error)")
        }
        
        return nil
    }
    
    /// Create a predicted sugar spike for high-carb meals (immediate feedback)
    private func createPredictedSugarSpike(for meal: MealLog) -> InsightEvent? {
        guard let carbs = meal.carbs, carbs > 50 else { return nil }
        
        let severity = min(carbs / 100, 1.0)
        
        return InsightEvent(
            timestamp: meal.timestamp.addingTimeInterval(2400), // ~40 min later
            type: .sugarSpike,
            severity: severity,
            message: "That was \(Int(carbs))g of carbs. Expect a potential energy dip in ~90 minutes.",
            associatedMealID: meal.id
        )
    }
    
    // MARK: - Digestion Debt Detection (P0)
    
    /// Detect if a meal will cause digestion debt (late eating)
    /// Algorithm from Insights_Library.md:
    /// - Trigger: meal_time > (sleep_start - 3h)
    /// - Logic: nocturnal_dip < 10%
    /// 
    /// Sprint 12 Enhancement: Uses HRV confirmation when analyzing post-sleep
    private func detectDigestionDebt(for meal: MealLog) async -> InsightEvent? {
        let mealHour = Calendar.current.component(.hour, from: meal.timestamp)
        
        // Simple heuristic: meals after 8 PM are "late"
        guard mealHour >= 20 else { return nil }
        
        // Calculate base severity based on how late
        var severity: Double
        if mealHour >= 22 {
            severity = 0.9
        } else if mealHour >= 21 {
            severity = 0.6
        } else {
            severity = 0.3
        }
        
        var message: String
        let hourString = mealHour >= 22 ? "very late" : "late"
        
        // Sprint 12: Try to get HRV confirmation if we're analyzing past meals
        // (i.e., a night has passed since the meal)
        let hoursSinceMeal = Date().timeIntervalSince(meal.timestamp) / 3600
        if hoursSinceMeal > 8 {
            // We can check overnight HRV to confirm the debt
            if let hrvConfirmation = await checkOvernightHRVDip(after: meal.timestamp) {
                if hrvConfirmation.dipPercentage < 0.10 {
                    // HRV confirms poor recovery
                    severity = min(severity + 0.2, 1.0)
                    message = "That \(hourString) dinner suppressed overnight HRV by only \(Int(hrvConfirmation.dipPercentage * 100))%. Recovery was impacted."
                } else {
                    // HRV shows normal recovery - reduce severity
                    severity = max(severity - 0.2, 0.1)
                    message = "Late dinner, but your HRV recovered well. Consider this a gentle reminder."
                }
            } else {
                message = "Eating this \(hourString) may keep your heart working while you sleep, reducing recovery."
            }
        } else {
            // Real-time prediction (before sleep)
            message = "Eating this \(hourString) may keep your heart working while you sleep, reducing recovery."
        }
        
        return InsightEvent(
            timestamp: meal.timestamp,
            type: .digestionDebt,
            severity: severity,
            message: message,
            associatedMealID: meal.id
        )
    }
    
    /// Check overnight HRV dip (should be >10% for good recovery)
    private func checkOvernightHRVDip(after mealTime: Date) async -> (dipPercentage: Double, overnightHRV: Double)? {
        // Find the sleep window after this meal
        let assumedSleepStart = Calendar.current.date(byAdding: .hour, value: 3, to: mealTime)!
        let assumedSleepEnd = Calendar.current.date(byAdding: .hour, value: 10, to: mealTime)!
        
        do {
            // Get overnight HRV
            let overnightHRV = try await healthKitProvider.fetchOvernightHRV(
                sleepStart: assumedSleepStart,
                sleepEnd: assumedSleepEnd
            )
            
            // Get 7-day baseline
            let baselineRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()
            let baseline = try await healthKitProvider.fetchBaselineHRV(for: baselineRange)
            
            guard let overnight = overnightHRV, let base = baseline, base > 0 else { return nil }
            
            // Calculate dip (overnight should be similar or higher than baseline during rest)
            // A "dip" here means overnight is LOWER than baseline (bad sign)
            let dip = (base - overnight) / base
            
            return (dipPercentage: max(0, dip), overnightHRV: overnight)
        } catch {
            print("InsightEngine: Failed to check overnight HRV dip: \(error)")
            return nil
        }
    }
    
    // MARK: - Mood Mapping
    
    private func updateMood(from insights: [InsightEvent], meal: MealLog) {
        if let sugarSpike = insights.first(where: { $0.type == .sugarSpike }) {
            currentMood = sugarSpike.severity > 0.6 ? .spiking : .digesting
        } else if insights.contains(where: { $0.type == .digestionDebt }) {
            currentMood = .sleepy
        } else {
            currentMood = .digesting
        }
    }
    
    private func moodFromInsight(_ type: InsightType) -> MascotMoodState {
        switch type {
        case .sugarSpike, .anxietyMimic:
            return .spiking
        case .caffeineJitter:
            return .strong // Caffeine = alert/focused state
        case .digestionDebt, .deepSleepRobber:
            return .sleepy
        case .muscleSponge, .goodSpike, .zone2Drain:
            return .strong
        // HRV-Powered insights (Sprint 12)
        case .recoveryGap, .mealImpactScore, .alcoholImpact:
            return .crashing
        case .stressBuffer, .fastingBenefit, .morningReadiness:
            return .strong
        case .mineralGap, .brainFogForecast:
            return .sleepy
        }
    }
    
    // MARK: - Muscle Sponge Detection (P0)
    
    /// Detect if user is in anabolic window (post-workout)
    /// Algorithm from Insights_Library.md §6:
    /// - Trigger: Workout ends
    /// - Condition: ActiveEnergy > 300kcal OR HR_Max > Zone 3
    /// - Window: workout_end to workout_end + 120 min
    private func detectMuscleSponge(for meal: MealLog, modelContext: ModelContext) async -> InsightEvent? {
        // Query recent workouts where meal timestamp falls within anabolic window
        let mealTime = meal.timestamp
        
        let predicate = #Predicate<WorkoutLog> { workout in
            workout.anabolicWindowEnd > mealTime && workout.endTime < mealTime
        }
        
        do {
            let workouts = try modelContext.fetch(FetchDescriptor<WorkoutLog>(predicate: predicate))
            
            // Find a qualifying workout
            guard let workout = workouts.first(where: { qualifyingWorkout($0) }) else {
                return nil
            }
            
            // Muscle Sponge detected!
            let remainingWindow = workout.anabolicWindowEnd.timeIntervalSince(mealTime)
            let remainingMins = Int(remainingWindow / 60)
            
            return InsightEvent(
                type: .muscleSponge,
                severity: 0.3, // Positive insight
                message: "Your muscles are hungry! Carbs now fuel recovery, not fat. Window closes in \(remainingMins) min.",
                associatedMealID: meal.id
            )
        } catch {
            print("InsightEngine: Failed to query workouts: \(error)")
            return nil
        }
    }
    
    /// Check if workout qualifies for anabolic window (300kcal+ OR Zone 3+)
    func qualifyingWorkout(_ workout: WorkoutLog) -> Bool {
        let calorieThreshold = (workout.activeCalories ?? 0) >= 300
        let zoneThreshold = (workout.dominantHRZone ?? 0) >= 3
        return calorieThreshold || zoneThreshold
    }
    
    // MARK: - Good Spike Suppression (P0)
    
    /// Check if user is exercising or in cool-down period
    /// Used to suppress Sugar Spike alerts during/after exercise
    private func isInExerciseContext(at time: Date, modelContext: ModelContext) async -> Bool {
        // 30-minute cool-down window after workout
        let thirtyMinsBefore = time.addingTimeInterval(-1800)
        
        // SwiftData predicates can't use addingTimeInterval inside - must precalculate
        let predicate = #Predicate<WorkoutLog> { workout in
            workout.startTime < time && workout.endTime > thirtyMinsBefore
        }
        
        do {
            let workouts = try modelContext.fetch(FetchDescriptor<WorkoutLog>(predicate: predicate))
            return !workouts.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - Context Tagging
    
    /// Apply automatic context tags to a meal
    private func applyContextTags(to meal: MealLog, modelContext: ModelContext) async {
        var tags: [String] = []
        
        // Check for refeed (anabolic window)
        if await isInAnabolicWindow(at: meal.timestamp, modelContext: modelContext) {
            tags.append("refeed")
        }
        
        // Circadian tags
        let hour = Calendar.current.component(.hour, from: meal.timestamp)
        if hour >= 21 || hour < 5 {
            tags.append("late-night")
        } else if hour >= 5 && hour < 10 {
            tags.append("breakfast")
        } else if hour >= 11 && hour < 14 {
            tags.append("lunch")
        } else if hour >= 17 && hour < 21 {
            tags.append("dinner")
        }
        
        // High-carb tag
        if let carbs = meal.carbs, carbs > 50 {
            tags.append("high-carb")
        }
        
        meal.autoTags = tags
    }
    
    /// Check if timestamp falls within any workout's anabolic window
    func isInAnabolicWindow(at time: Date, modelContext: ModelContext) async -> Bool {
        let predicate = #Predicate<WorkoutLog> { workout in
            workout.endTime < time && workout.anabolicWindowEnd > time
        }
        
        do {
            let workouts = try modelContext.fetch(FetchDescriptor<WorkoutLog>(predicate: predicate))
            // Also check intensity threshold
            return workouts.contains(where: { qualifyingWorkout($0) })
        } catch {
            return false
        }
    }
    
    // MARK: - Anxiety Mimic Detection (P1)
    
    /// Detects when low blood sugar mimics anxiety symptoms
    /// Algorithm: 2-3h after high-carb meal + HR dropping + HRV low
    /// Sprint 12: Now includes HRV confirmation for higher confidence
    func detectAnxietyMimic(for meal: MealLog, in modelContext: ModelContext, at referenceDate: Date = Date()) async -> InsightEvent? {
        // Trigger: high carb meal 2-3 hours ago
        guard let carbs = meal.carbs, carbs > 40 else { return nil }
        
        let hoursSinceMeal = referenceDate.timeIntervalSince(meal.timestamp) / 3600
        guard hoursSinceMeal >= 2 && hoursSinceMeal <= 3.5 else { return nil }
        
        // Check for HR gradient (dropping) - simplified heuristic
        let recentRange = referenceDate.addingTimeInterval(-1800)...referenceDate
        
        do {
            let recentHR = try await healthKitProvider.fetchHeartRateSamples(for: recentRange)
            guard recentHR.count >= 3 else { return nil }
            
            // Calculate gradient (bpm per hour)
            let sortedSamples = recentHR.sorted { $0.timestamp < $1.timestamp }
            let first = sortedSamples.first!
            let last = sortedSamples.last!
            let timeDelta = last.timestamp.timeIntervalSince(first.timestamp) / 3600
            guard timeDelta > 0 else { return nil }
            
            let gradient = (last.bpm - first.bpm) / timeDelta
            
            // Sprint 12: Add HRV confirmation
            let recentHRV = try await healthKitProvider.fetchHRVSamples(for: recentRange)
            let baselineRange = referenceDate.addingTimeInterval(-7 * 24 * 3600)...referenceDate
            let baselineHRV = try await healthKitProvider.fetchBaselineHRV(for: baselineRange) ?? 50.0
            
            let currentHRV: Double
            if !recentHRV.isEmpty {
                currentHRV = recentHRV.map(\.sdnn).reduce(0, +) / Double(recentHRV.count)
            } else {
                currentHRV = baselineHRV // Default to baseline if no recent data
            }
            
            // HRV suppressed = below 80% of baseline
            let hrvSuppressed = currentHRV < baselineHRV * 0.8
            let hrvDeficit = Int((1 - currentHRV / baselineHRV) * 100)
            
            // Detect rapid HR drop (anxiety mimic signal)
            // Requires BOTH HR dropping AND HRV suppressed for high confidence
            if gradient < -1.0 && hrvSuppressed {
                return InsightEvent(
                    timestamp: referenceDate,
                    type: .anxietyMimic,
                    severity: min(abs(gradient) / 5, 1.0),
                    message: "Feeling anxious? Your HRV is \(hrvDeficit)% below normal—likely a blood sugar dip from \(meal.name), not stress.",
                    associatedMealID: meal.id
                )
            } else if gradient < -2.0 {
                // Very rapid drop even without HRV confirmation
                return InsightEvent(
                    timestamp: referenceDate,
                    type: .anxietyMimic,
                    severity: min(abs(gradient) / 5, 0.7), // Lower severity without HRV
                    message: "Feeling jittery? It might be a blood sugar dip from \(meal.name). Try a small snack.",
                    associatedMealID: meal.id
                )
            }
        } catch {
            print("InsightEngine: Anxiety Mimic detection failed: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Caffeine Jitter Detection (P1)
    
    /// Detects caffeine-induced elevated heart rate (not anxiety)
    /// Algorithm: recent caffeine event + HR elevated + stable HRV
    /// Sprint 12: Uses HRV stability to distinguish caffeine from stress
    func detectCaffeineJitter(for meals: [MealLog]) async -> InsightEvent? {
        let fourHoursAgo = Date().addingTimeInterval(-4 * 3600)
        
        let recentCaffeineEvents = meals
            .filter { $0.timestamp > fourHoursAgo }
            .filter { ($0.caffeine ?? 0) > 0 || $0.contextTags.contains("caffeine-event") }
        
        guard !recentCaffeineEvents.isEmpty else { return nil }
        
        // Check for elevated HR
        let recentRange = Date().addingTimeInterval(-1800)...Date()
        let baselineRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()
        
        do {
            let recentHR = try await healthKitProvider.fetchHeartRateSamples(for: recentRange)
            let restingHR = try await healthKitProvider.fetchBaselineRestingHeartRate(for: baselineRange) ?? 65.0
            
            guard !recentHR.isEmpty else { return nil }
            
            let avgHR = recentHR.map(\.bpm).reduce(0, +) / Double(recentHR.count)
            
            // Dynamic threshold: restingHR + 15 bpm
            let threshold = restingHR + 15
            
            // Sprint 12: Check HRV stability
            let recentHRV = try await healthKitProvider.fetchHRVSamples(for: recentRange)
            let baselineHRV = try await healthKitProvider.fetchBaselineHRV(for: baselineRange) ?? 50.0
            
            let avgHRV: Double
            if !recentHRV.isEmpty {
                avgHRV = recentHRV.map(\.sdnn).reduce(0, +) / Double(recentHRV.count)
            } else {
                avgHRV = baselineHRV
            }
            
            // HRV is "stable" if within 15% of baseline
            let hrvStable = abs(avgHRV - baselineHRV) / baselineHRV < 0.15
            
            if avgHR > threshold && hrvStable {
                // Classic caffeine pattern: HR up, HRV stable
                return InsightEvent(
                    timestamp: Date(),
                    type: .caffeineJitter,
                    severity: min((avgHR - threshold) / 30.0, 1.0),
                    message: "Alert mode activated. A recent caffeine event lines up with elevated heart rate, while HRV stays steady.",
                    associatedMealID: recentCaffeineEvents.first?.id
                )
            } else if avgHR > threshold + 10 {
                // Very elevated HR even without HRV data
                return InsightEvent(
                    timestamp: Date(),
                    type: .caffeineJitter,
                    severity: min((avgHR - threshold) / 30.0, 0.6),
                    message: "A recent caffeine event may be driving this elevated heart rate. You're running about +\(Int(avgHR - restingHR)) bpm above baseline.",
                    associatedMealID: recentCaffeineEvents.first?.id
                )
            }
        } catch {
            print("InsightEngine: Caffeine Jitter detection failed: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Zone 2 Drain Detection (P1)
    
    /// Detects insulin sensitivity boost from Zone 2 exercise
    /// Algorithm: Cardio workout with >45 min in Zone 2
    func detectZone2Drain(for workout: WorkoutLog) -> InsightEvent? {
        // Check for cardio type
        guard workout.category == .cardio else { return nil }

        let zone2Minutes: Int
        if let breakdown = workout.hrZoneBreakdown, breakdown.zone2Minutes > 0 {
            zone2Minutes = breakdown.zone2Minutes
        } else if workout.dominantHRZone == 2 {
            zone2Minutes = Int(workout.duration / 60)
        } else {
            // Fallback for steady cardio sessions when granular zone data is missing.
            zone2Minutes = Int(workout.duration / 60)
        }

        guard zone2Minutes >= 45 else { return nil }
        
        return InsightEvent(
            timestamp: workout.endTime,
            type: .zone2Drain,
            severity: min(Double(zone2Minutes) / 90.0, 1.0), // 90 min = max
            message: "Your \(zone2Minutes) minute session created a glucose sink. You can handle a bigger dinner tonight!",
            associatedMealID: nil
        )
    }
    
    // MARK: - Deep Sleep Robber Detection (P1)
    
    /// Detects overnight deep-sleep disruption likely related to late intake.
    /// Intelligence v1 uses a practical proxy model:
    /// - latest completed sleep session has poor deep sleep
    /// - a plausible late culprit exists before sleep (late meal or afternoon/evening caffeine)
    func detectDeepSleepRobber(in modelContext: ModelContext) async -> InsightEvent? {
        let now = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now

        let sleepPredicate = #Predicate<SleepLog> { sleep in
            sleep.endTime <= now && sleep.endTime >= twoDaysAgo
        }

        do {
            let sleepLogs = try modelContext.fetch(FetchDescriptor<SleepLog>(predicate: sleepPredicate))
            guard let latestSleep = sleepLogs.max(by: { $0.endTime < $1.endTime }) else { return nil }
            guard latestSleep.deepSleepMinutes > 0 else { return nil }
            guard latestSleep.deepSleepMinutes < 45 else { return nil }

            let sleepStart = latestSleep.startTime
            let mealWindowStart = sleepStart.addingTimeInterval(-6 * 60 * 60)
            let mealPredicate = #Predicate<MealLog> { meal in
                meal.timestamp >= mealWindowStart && meal.timestamp <= sleepStart
            }
            let meals = try modelContext.fetch(FetchDescriptor<MealLog>(predicate: mealPredicate))

            let latestLateMeal = meals
                .filter { meal in
                    guard !meal.isConsumableEvent else { return false }
                    let hour = Calendar.current.component(.hour, from: meal.timestamp)
                    let closeToSleep = latestSleep.startTime.timeIntervalSince(meal.timestamp) <= (3 * 60 * 60)
                    return closeToSleep || hour >= 21 || hour < 5
                }
                .sorted { $0.timestamp > $1.timestamp }
                .first

            let latestLateCaffeine = meals
                .filter { meal in
                    let hour = Calendar.current.component(.hour, from: meal.timestamp)
                    return (meal.caffeine ?? 0) > 0 && hour >= 14
                }
                .sorted { $0.timestamp > $1.timestamp }
                .first

            let culprit: MealLog?
            let message: String

            if let lateMeal = latestLateMeal {
                let hoursBeforeSleep = max(0, Int(round(latestSleep.startTime.timeIntervalSince(lateMeal.timestamp) / 3600)))
                culprit = lateMeal
                message = "Your deep sleep was only \(latestSleep.deepSleepMinutes) minutes last night. That \(lateMeal.name.lowercased()) \(hoursBeforeSleep == 0 ? "right before bed" : "\(hoursBeforeSleep)h before sleep") may have kept recovery light."
            } else if let lateCaffeine = latestLateCaffeine {
                culprit = lateCaffeine
                message = "Your deep sleep was only \(latestSleep.deepSleepMinutes) minutes last night. That late \(lateCaffeine.name.lowercased()) may have kept your system too alert for deeper recovery."
            } else {
                return nil
            }

            let baseSeverity = min(Double(45 - latestSleep.deepSleepMinutes) / 30.0, 1.0)
            let proximityBonus: Double
            if let culprit {
                let hoursFromCulprit = latestSleep.startTime.timeIntervalSince(culprit.timestamp) / 3600
                proximityBonus = hoursFromCulprit <= 3 ? 0.15 : 0
            } else {
                proximityBonus = 0
            }

            return InsightEvent(
                timestamp: latestSleep.endTime,
                type: .deepSleepRobber,
                severity: min(baseSeverity + proximityBonus, 1.0),
                message: message,
                associatedMealID: culprit?.id
            )
        } catch {
            print("InsightEngine: Deep Sleep Robber detection failed: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Sprint 12: New HRV-Powered Detectors
    
    /// Detects under-fueling after workout via slow HRV recovery
    /// Algorithm: Workout burned >300kcal + calories consumed <50% + slow HRV slope
    func detectRecoveryGap(for workout: WorkoutLog, in modelContext: ModelContext) async -> InsightEvent? {
        let workoutEnd = workout.endTime
        let now = Date()
        
        // Evaluate only after the acute workout period but before the signal goes stale.
        let hoursSinceWorkout = now.timeIntervalSince(workoutEnd) / 3600
        guard hoursSinceWorkout >= 6 && hoursSinceWorkout <= 36 else { return nil }
        guard (workout.activeCalories ?? 0) > 300 || workout.triggersAnabolicWindow else { return nil }
        
        let refeedWindowEnd = workoutEnd.addingTimeInterval(2 * 60 * 60)
        let mealPredicate = #Predicate<MealLog> { meal in
            meal.timestamp > workoutEnd
        }
        
        do {
            let meals = try modelContext.fetch(FetchDescriptor<MealLog>(predicate: mealPredicate))
            let caloriesConsumed = meals
                .filter { $0.timestamp <= refeedWindowEnd }
                .compactMap { $0.calories }
                .reduce(0, +)
            let caloriesBurned = workout.activeCalories ?? 0

            let recentMeals = meals.filter { $0.timestamp <= refeedWindowEnd && !$0.isConsumableEvent }
            let hasRefeedContext = recentMeals.contains { meal in
                meal.autoTags.contains("refeed") || meal.protein != nil || meal.carbs != nil
            }
            let underFueledByCalories = caloriesBurned > 300 && caloriesConsumed > 0 && caloriesConsumed < caloriesBurned * 0.5
            let missedRefeedWindow = recentMeals.isEmpty || !hasRefeedContext

            guard underFueledByCalories || missedRefeedWindow else { return nil }

            let recoveryRange = workoutEnd...min(workoutEnd.addingTimeInterval(6 * 3600), now)
            let recoveryHRV = try await healthKitProvider.fetchHRVSamples(for: recoveryRange)

            let hasSlowHRVRecovery: Bool
            var severity = 0.45
            if recoveryHRV.count >= 2 {
                let sortedHRV = recoveryHRV.sorted { $0.timestamp < $1.timestamp }
                let first = sortedHRV.first!.sdnn
                let last = sortedHRV.last!.sdnn
                let timeDelta = sortedHRV.last!.timestamp.timeIntervalSince(sortedHRV.first!.timestamp) / 3600
                let slope = timeDelta > 0 ? (last - first) / timeDelta : 0
                hasSlowHRVRecovery = slope < 5
                severity = min(max(0.35, 1.0 - slope / 10), 1.0)
            } else {
                let baselineRange = now.addingTimeInterval(-7 * 24 * 3600)...now
                if let baseline = try await healthKitProvider.fetchBaselineHRV(for: baselineRange),
                   let morningHRV = try await healthKitProvider.fetchMorningHRV(for: now) {
                    hasSlowHRVRecovery = morningHRV < baseline * 0.9
                    let deficit = max(0, (baseline - morningHRV) / max(baseline, 1))
                    severity = min(0.45 + deficit, 1.0)
                } else {
                    hasSlowHRVRecovery = false
                }
            }

            guard hasSlowHRVRecovery else { return nil }

            let refuelMessage: String
            if underFueledByCalories {
                refuelMessage = "You burned \(Int(caloriesBurned)) kcal but only refueled about \(Int(caloriesConsumed))."
            } else {
                refuelMessage = "You had a hard session and Monch couldn't find a solid refuel in the first couple of hours."
            }

            return InsightEvent(
                timestamp: now,
                type: .recoveryGap,
                severity: severity,
                message: "\(refuelMessage) Recovery still looks heavy this morning. This may be a fuel problem more than a rest problem.",
                associatedMealID: nil
            )
        } catch {
            print("InsightEngine: Recovery Gap detection failed: \(error)")
        }
        
        return nil
    }
    
    /// Detects morning readiness based on HRV vs baseline
    /// Algorithm: Morning HRV compared to 7-day average
    func detectMorningReadiness() async -> InsightEvent? {
        do {
            guard let morningHRV = try await healthKitProvider.fetchMorningHRV(for: Date()) else { return nil }
            
            let baselineRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()
            guard let baseline = try await healthKitProvider.fetchBaselineHRV(for: baselineRange) else { return nil }
            
            let readinessScore = morningHRV / baseline
            let percentDiff = Int(abs(readinessScore - 1) * 100)
            
            if readinessScore >= 1.1 {
                return InsightEvent(
                    timestamp: Date(),
                    type: .morningReadiness,
                    severity: 0.2, // Positive
                    message: "Fully charged! HRV is \(percentDiff)% above baseline. Great day for intensity!",
                    associatedMealID: nil
                )
            } else if readinessScore < 0.85 {
                return InsightEvent(
                    timestamp: Date(),
                    type: .morningReadiness,
                    severity: 0.5 + (0.85 - readinessScore),
                    message: "Recovery isn't complete. HRV is \(percentDiff)% below normal. Consider an easier day.",
                    associatedMealID: nil
                )
            }
        } catch {
            print("InsightEngine: Morning Readiness detection failed: \(error)")
        }
        
        return nil
    }
    
    /// Detects meal impact on HRV
    /// Algorithm: Compare HRV before and after meal
    func detectMealImpactScore(for meal: MealLog) async -> InsightEvent? {
        // Need at least 1 hour post-meal
        let hoursSinceMeal = Date().timeIntervalSince(meal.timestamp) / 3600
        guard hoursSinceMeal >= 1 && hoursSinceMeal <= 2 else { return nil }
        
        let preMealRange = meal.timestamp.addingTimeInterval(-1800)...meal.timestamp
        let postMealRange = meal.timestamp...meal.timestamp.addingTimeInterval(3600)
        
        do {
            let preHRV = try await healthKitProvider.fetchHRVSamples(for: preMealRange)
            let postHRV = try await healthKitProvider.fetchHRVSamples(for: postMealRange)
            
            guard !preHRV.isEmpty, !postHRV.isEmpty else { return nil }
            
            let preAvg = preHRV.map(\.sdnn).reduce(0, +) / Double(preHRV.count)
            let postAvg = postHRV.map(\.sdnn).reduce(0, +) / Double(postHRV.count)
            
            let impact = (preAvg - postAvg) / preAvg
            
            if impact > 0.2 { // >20% drop = significant
                return InsightEvent(
                    timestamp: Date(),
                    type: .mealImpactScore,
                    severity: min(impact, 1.0),
                    message: "That \(meal.name) dropped your HRV by \(Int(impact * 100))%. Your body is working hard to digest it.",
                    associatedMealID: meal.id
                )
            }
        } catch {
            print("InsightEngine: Meal Impact Score failed: \(error)")
        }
        
        return nil
    }
    
    /// Detects HRV improvement during fasting window
    /// Algorithm: HRV trend during 12+ hour fast (awake samples only)
    func detectFastingBenefit(in modelContext: ModelContext) async -> InsightEvent? {
        // Get most recent meal
        let mealDescriptor = FetchDescriptor<MealLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let meals = try modelContext.fetch(mealDescriptor)
            guard let lastMeal = meals.first else { return nil }
            
            let hoursSinceMeal = Date().timeIntervalSince(lastMeal.timestamp) / 3600
            guard hoursSinceMeal >= 12 else { return nil } // 12+ hour fast
            
            // Check if HRV is trending up during fast
            let fastingRange = lastMeal.timestamp...Date()
            let fastingHRV = try await healthKitProvider.fetchHRVSamples(for: fastingRange)
            
            // Filter to awake samples only (6 AM - 10 PM) to avoid sleep confound
            let calendar = Calendar.current
            let awakeSamples = fastingHRV.filter { sample in
                let hour = calendar.component(.hour, from: sample.timestamp)
                return hour >= 6 && hour < 22
            }
            
            guard awakeSamples.count >= 4 else { return nil }
            
            let sorted = awakeSamples.sorted { $0.timestamp < $1.timestamp }
            let firstHalf = sorted.prefix(sorted.count / 2).map(\.sdnn)
            let secondHalf = sorted.suffix(sorted.count / 2).map(\.sdnn)
            
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
            
            let improvement = (secondAvg - firstAvg) / firstAvg
            
            if improvement > 0.1 { // >10% improvement
                return InsightEvent(
                    timestamp: Date(),
                    type: .fastingBenefit,
                    severity: 0.2, // Positive insight
                    message: "Your \(Int(hoursSinceMeal))-hour fast is working! Daytime HRV improved \(Int(improvement * 100))% as digestion rested.",
                    associatedMealID: nil
                )
            }
        } catch {
            print("InsightEngine: Fasting Benefit detection failed: \(error)")
        }
        
        return nil
    }
    
    /// Detects when protein intake protected HRV during stressful period
    /// Algorithm: High stress day (low avg HRV) + high protein = HRV didn't crash
    func detectStressBuffer(in modelContext: ModelContext) async -> InsightEvent? {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayRange = todayStart...Date()
        
        do {
            // Get today's HRV
            let todayHRV = try await healthKitProvider.fetchHRVSamples(for: todayRange)
            guard !todayHRV.isEmpty else { return nil }
            
            let avgTodayHRV = todayHRV.map(\.sdnn).reduce(0, +) / Double(todayHRV.count)
            
            // Get baseline
            let baselineRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()
            guard let baseline = try await healthKitProvider.fetchBaselineHRV(for: baselineRange) else { return nil }
            
            // Was today "stressful" (HRV 10-20% below baseline but not crashed)?
            let hrvRatio = avgTodayHRV / baseline
            guard hrvRatio >= 0.8 && hrvRatio < 0.9 else { return nil }
            
            // Check protein intake today
            let mealPredicate = #Predicate<MealLog> { meal in
                meal.timestamp >= todayStart
            }
            let meals = try modelContext.fetch(FetchDescriptor<MealLog>(predicate: mealPredicate))
            let totalProtein = meals.compactMap { $0.protein }.reduce(0, +)
            
            // High protein (>50g) during stress = buffered
            if totalProtein > 50 {
                return InsightEvent(
                    timestamp: Date(),
                    type: .stressBuffer,
                    severity: 0.2, // Positive
                    message: "You handled today's stress well! \(Int(totalProtein))g protein kept your HRV stable.",
                    associatedMealID: nil
                )
            }
        } catch {
            print("InsightEngine: Stress Buffer detection failed: \(error)")
        }
        
        return nil
    }
    
    /// Detects chronic low HRV that may indicate mineral deficiency
    /// Algorithm: HRV flat/low for 2+ weeks despite good sleep
    func detectMineralGap(in modelContext: ModelContext) async -> InsightEvent? {
        let twoWeeksAgo = Date().addingTimeInterval(-14 * 24 * 3600)
        let range = twoWeeksAgo...Date()
        
        do {
            let hrvSamples = try await healthKitProvider.fetchHRVSamples(for: range)
            guard hrvSamples.count >= 14 else { return nil } // Need at least 2 weeks of data
            
            // Group by day and calculate daily averages
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: hrvSamples) { sample in
                calendar.startOfDay(for: sample.timestamp)
            }
            
            let dailyAverages = grouped.values.map { samples in
                samples.map(\.sdnn).reduce(0, +) / Double(samples.count)
            }.sorted()
            
            guard dailyAverages.count >= 10 else { return nil }
            
            // Check for low variance (flat HRV)
            let minHRV = dailyAverages.min()!
            let maxHRV = dailyAverages.max()!
            let variance = maxHRV - minHRV
            
            // Also check if consistently low (<40ms average)
            let overallAvg = dailyAverages.reduce(0, +) / Double(dailyAverages.count)
            
            // Low and flat = possible mineral gap
            if variance < 10 && overallAvg < 40 {
                return InsightEvent(
                    timestamp: Date(),
                    type: .mineralGap,
                    severity: 0.6,
                    message: "Your HRV has been flat for 2 weeks (\(Int(overallAvg))ms avg). Magnesium or Zinc might help.",
                    associatedMealID: nil
                )
            }
        } catch {
            print("InsightEngine: Mineral Gap detection failed: \(error)")
        }
        
        return nil
    }
    
    /// Predicts brain fog based on low morning HRV
    /// Algorithm: Morning HRV significantly below baseline = tough focus day
    func detectBrainFogForecast() async -> InsightEvent? {
        do {
            guard let morningHRV = try await healthKitProvider.fetchMorningHRV(for: Date()) else { return nil }
            
            let baselineRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()
            guard let baseline = try await healthKitProvider.fetchBaselineHRV(for: baselineRange) else { return nil }
            
            let deficit = (baseline - morningHRV) / baseline
            
            // >25% below baseline = brain fog risk
            if deficit > 0.25 {
                return InsightEvent(
                    timestamp: Date(),
                    type: .brainFogForecast,
                    severity: min(deficit, 1.0),
                    message: "Focus might be tricky today. HRV is \(Int(deficit * 100))% below normal. Tackle hard work early.",
                    associatedMealID: nil
                )
            }
        } catch {
            print("InsightEngine: Brain Fog Forecast failed: \(error)")
        }
        
        return nil
    }
    
    /// Detects overnight HRV suppression from alcohol
    /// Algorithm: Unusually low overnight HRV on nights with no late meals
    func detectAlcoholImpact(in modelContext: ModelContext) async -> InsightEvent? {
        // Check overnight HRV from last night
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let lastNightStart = calendar.date(byAdding: .hour, value: -8, to: todayStart),
              let lastNightEnd = calendar.date(byAdding: .hour, value: -1, to: todayStart) else { return nil }
        
        do {
            let overnightHRV = try await healthKitProvider.fetchOvernightHRV(
                sleepStart: lastNightStart,
                sleepEnd: lastNightEnd
            )
            
            let baselineRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()
            guard let baseline = try await healthKitProvider.fetchBaselineHRV(for: baselineRange),
                  let overnight = overnightHRV else { return nil }
            
            let suppression = (baseline - overnight) / baseline
            
            // Check if there was a late meal (could explain the dip via digestion debt)
            let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
            let mealPredicate = #Predicate<MealLog> { meal in
                meal.timestamp >= yesterdayStart && meal.timestamp < todayStart
            }
            let meals = try modelContext.fetch(FetchDescriptor<MealLog>(predicate: mealPredicate))
            let hasLateMeal = meals.contains { meal in
                let hour = calendar.component(.hour, from: meal.timestamp)
                return hour >= 20
            }
            let hasAlcoholEvent = meals.contains { $0.contextTags.contains("alcohol-event") }
            
            // Explicit alcohol event lowers the confirmation threshold slightly.
            let threshold = hasAlcoholEvent ? 0.25 : 0.35
            
            if suppression > threshold && !hasLateMeal {
                return InsightEvent(
                    timestamp: Date(),
                    type: .alcoholImpact,
                    severity: min(suppression, 1.0),
                    message: hasAlcoholEvent
                        ? "Overnight HRV was \(Int(suppression * 100))% below normal, and you logged alcohol last night. That's the most likely driver."
                        : "Overnight HRV was \(Int(suppression * 100))% below normal. If you drank last night, that's a likely explanation. Illness or travel could also cause this.",
                    associatedMealID: nil
                )
            }
        } catch {
            print("InsightEngine: Alcohol Impact detection failed: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Integration: Scheduled Checks
    
    /// Run morning insight checks (call from app launch)
    func runMorningChecks(in modelContext: ModelContext, now: Date = Date()) async -> [InsightEvent] {
        var insights: [InsightEvent] = []

        // Intelligence v1 keeps the morning path intentionally narrow:
        // use it to surface sleep disruption and overnight workout recovery
        // without activating the broader dormant HRV layer yet.
        if let deepSleepRobber = await detectDeepSleepRobber(in: modelContext),
           persistInsightIfNeeded(deepSleepRobber, in: modelContext) {
            insights.append(deepSleepRobber)
        }

        let recentWorkoutRangeStart = now.addingTimeInterval(-36 * 3600)
        let workoutPredicate = #Predicate<WorkoutLog> { workout in
            workout.endTime >= recentWorkoutRangeStart && workout.endTime <= now
        }

        do {
            let recentWorkouts = try modelContext.fetch(
                FetchDescriptor<WorkoutLog>(
                    predicate: workoutPredicate,
                    sortBy: [SortDescriptor(\.endTime, order: .reverse)]
                )
            )

            for workout in recentWorkouts {
                if let recoveryGap = await detectRecoveryGap(for: workout, in: modelContext),
                   persistInsightIfNeeded(recoveryGap, in: modelContext) {
                    insights.append(recoveryGap)
                    break
                }
            }
        } catch {
            print("InsightEngine: Morning recovery evaluation failed: \(error)")
        }

        if let latestInsight = insights.max(by: { $0.timestamp < $1.timestamp }) {
            currentMood = moodFromInsight(latestInsight.type)
        } else if !hasInsight(.deepSleepRobber, on: now, in: modelContext)
                    && !hasInsight(.recoveryGap, on: now, in: modelContext) {
            refreshMood(meals: [], insights: [])
        }

        return insights
    }
    
    /// Run weekly chronic checks (call on Sunday morning)
    func runWeeklyChecks(in modelContext: ModelContext) async -> [InsightEvent] {
        var insights: [InsightEvent] = []
        
        if let deepSleepRobber = await detectDeepSleepRobber(in: modelContext) {
            insights.append(deepSleepRobber)
            modelContext.insert(deepSleepRobber)
        }
        
        if let mineralGap = await detectMineralGap(in: modelContext) {
            insights.append(mineralGap)
            modelContext.insert(mineralGap)
        }
        
        return insights
    }

    // MARK: - Insight Persistence

    private func persistInsightIfNeeded(_ insight: InsightEvent, in modelContext: ModelContext) -> Bool {
        if isDuplicateInsight(insight, in: modelContext) {
            return false
        }

        modelContext.insert(insight)
        pendingInsights.append(insight)
        return true
    }

    private func isDuplicateInsight(_ insight: InsightEvent, in modelContext: ModelContext) -> Bool {
        let windowStart = insight.timestamp.addingTimeInterval(-30 * 60)
        let windowEnd = insight.timestamp.addingTimeInterval(30 * 60)
        let predicate = #Predicate<InsightEvent> { existing in
            existing.timestamp >= windowStart && existing.timestamp <= windowEnd
        }

        do {
            let nearbyInsights = try modelContext.fetch(FetchDescriptor<InsightEvent>(predicate: predicate))
            return nearbyInsights.contains { existing in
                guard existing.type == insight.type else { return false }

                if insight.type == .caffeineJitter {
                    return abs(existing.timestamp.timeIntervalSince(insight.timestamp)) <= 30 * 60
                }

                if let associatedMealID = insight.associatedMealID {
                    return existing.associatedMealID == associatedMealID
                }

                return abs(existing.timestamp.timeIntervalSince(insight.timestamp)) <= 30 * 60
            }
        } catch {
            print("InsightEngine: Failed to dedupe insight - \(error)")
            return false
        }
    }

    private func recentMeals(since startDate: Date, in modelContext: ModelContext, now: Date = Date()) -> [MealLog] {
        recentMeals(since: startDate, until: now, in: modelContext)
    }

    private func recentMeals(since startDate: Date, until endDate: Date, in modelContext: ModelContext) -> [MealLog] {
        let predicate = #Predicate<MealLog> { meal in
            meal.timestamp >= startDate && meal.timestamp <= endDate
        }

        do {
            return try modelContext.fetch(
                FetchDescriptor<MealLog>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
            )
        } catch {
            print("InsightEngine: Failed to fetch recent meals - \(error)")
            return []
        }
    }

    private func latestCompletedSleepEnd(in modelContext: ModelContext, now: Date) -> Date? {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now
        let predicate = #Predicate<SleepLog> { sleep in
            sleep.endTime <= now && sleep.endTime >= twoDaysAgo
        }

        do {
            return try modelContext.fetch(
                FetchDescriptor<SleepLog>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.endTime, order: .reverse)]
                )
            ).first?.endTime
        } catch {
            print("InsightEngine: Failed to fetch latest completed sleep - \(error)")
            return nil
        }
    }

    private func hasInsight(_ type: InsightType, on day: Date, in modelContext: ModelContext) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: day)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? day
        let predicate = #Predicate<InsightEvent> { existing in
            existing.timestamp >= startOfDay && existing.timestamp < endOfDay
        }

        do {
            let dayInsights = try modelContext.fetch(FetchDescriptor<InsightEvent>(predicate: predicate))
            return dayInsights.contains { $0.type == type }
        } catch {
            print("InsightEngine: Failed to check existing insight state - \(error)")
            return false
        }
    }
}
