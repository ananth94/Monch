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
        
        // Phase 2: Check for Muscle Sponge (post-workout anabolic window)
        if let muscleSponge = await detectMuscleSponge(for: meal, modelContext: modelContext) {
            insights.append(muscleSponge)
            modelContext.insert(muscleSponge)
            // Send notification for positive reinforcement
            NotificationManager.shared.notifyMuscleSponge()
        }
        
        // Phase 3: Check for Sugar Spike (with Good Spike suppression)
        // Skip if in exercise context OR if meal is tagged as "refeed"
        if !meal.autoTags.contains("refeed") {
            if let sugarSpike = await detectSugarSpike(for: meal, modelContext: modelContext) {
                insights.append(sugarSpike)
                modelContext.insert(sugarSpike)
                // Send notification alert
                NotificationManager.shared.notifySugarSpike(mealName: meal.name)
            }
        }
        
        // Phase 4: Check for Digestion Debt (late eating)
        if let digestionDebt = await detectDigestionDebt(for: meal) {
            insights.append(digestionDebt)
            modelContext.insert(digestionDebt)
            // Send notification (will appear next morning)
            NotificationManager.shared.notifyDigestionDebt()
        }
        
        // Update mascot mood based on insights
        updateMood(from: insights, meal: meal)
        
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
    func detectAnxietyMimic(for meal: MealLog, in modelContext: ModelContext) async -> InsightEvent? {
        // Trigger: high carb meal 2-3 hours ago
        guard let carbs = meal.carbs, carbs > 40 else { return nil }
        
        let hoursSinceMeal = Date().timeIntervalSince(meal.timestamp) / 3600
        guard hoursSinceMeal >= 2 && hoursSinceMeal <= 3.5 else { return nil }
        
        // Check for HR gradient (dropping) - simplified heuristic
        let recentRange = Date().addingTimeInterval(-1800)...Date()
        
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
            let baselineRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()
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
                    timestamp: Date(),
                    type: .anxietyMimic,
                    severity: min(abs(gradient) / 5, 1.0),
                    message: "Feeling anxious? Your HRV is \(hrvDeficit)% below normal—likely a blood sugar dip from \(meal.name), not stress.",
                    associatedMealID: meal.id
                )
            } else if gradient < -2.0 {
                // Very rapid drop even without HRV confirmation
                return InsightEvent(
                    timestamp: Date(),
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
        
        // Check for Zone 2 duration via zone breakdown
        guard let breakdown = workout.hrZoneBreakdown else { return nil }
        let zone2Minutes = breakdown.zone2Minutes
        
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
    
    /// Detects chronic patterns that erode deep sleep
    /// Algorithm: 7-day rolling window with avg deep sleep <45 min + late meals/caffeine
    func detectDeepSleepRobber(in modelContext: ModelContext) async -> InsightEvent? {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        // Fetch recent sleep logs
        let sleepPredicate = #Predicate<SleepLog> { sleep in
            sleep.startTime > sevenDaysAgo
        }
        
        let mealPredicate = #Predicate<MealLog> { meal in
            meal.timestamp > sevenDaysAgo
        }
        
        do {
            let sleepLogs = try modelContext.fetch(FetchDescriptor<SleepLog>(predicate: sleepPredicate))
            let meals = try modelContext.fetch(FetchDescriptor<MealLog>(predicate: mealPredicate))
            
            guard sleepLogs.count >= 4 else { return nil } // Relaxed to 4 days
            
            // Calculate average deep sleep
            let deepSleepMinutes = sleepLogs.map { Double($0.deepSleepMinutes) }.reduce(0, +)
            let avgDeepSleep = deepSleepMinutes / Double(sleepLogs.count)
            
            guard avgDeepSleep < 45 else { return nil }
            
            // Count late meals (after 9pm)
            let lateMeals = meals.filter { meal in
                let hour = Calendar.current.component(.hour, from: meal.timestamp)
                return hour >= 21 || hour < 5
            }.count
            
            // Count late caffeine (after 2pm)
            let lateCaffeine = meals.filter { meal in
                let hour = Calendar.current.component(.hour, from: meal.timestamp)
                return hour >= 14 && (meal.caffeine ?? 0) > 0
            }.count
            
            if lateMeals >= 3 || lateCaffeine >= 3 {
                let culprit = lateMeals > lateCaffeine ? "late meals" : "afternoon caffeine"
                
                return InsightEvent(
                    timestamp: Date(),
                    type: .deepSleepRobber,
                    severity: min((45 - avgDeepSleep) / 30, 1.0),
                    message: "Your deep sleep has been under 45 min for a week. Those \(culprit) might be the culprit.",
                    associatedMealID: nil
                )
            }
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
        
        // Must be at least 1 hour post-workout
        guard now.timeIntervalSince(workoutEnd) > 3600 else { return nil }
        
        // Check caloric intake since workout
        let mealPredicate = #Predicate<MealLog> { meal in
            meal.timestamp > workoutEnd
        }
        
        do {
            let meals = try modelContext.fetch(FetchDescriptor<MealLog>(predicate: mealPredicate))
            let caloriesConsumed = meals.compactMap { $0.calories }.reduce(0, +)
            let caloriesBurned = workout.activeCalories ?? 0
            
            // Under-fueled if consumed < 50% of burned
            guard caloriesBurned > 300 && caloriesConsumed < caloriesBurned * 0.5 else { return nil }
            
            // Check HRV recovery slope (should rise post-workout)
            let recoveryRange = workoutEnd...min(workoutEnd.addingTimeInterval(3600), now)
            let recoveryHRV = try await healthKitProvider.fetchHRVSamples(for: recoveryRange)
            
            guard recoveryHRV.count >= 2 else { return nil }
            
            let sortedHRV = recoveryHRV.sorted { $0.timestamp < $1.timestamp }
            let first = sortedHRV.first!.sdnn
            let last = sortedHRV.last!.sdnn
            let timeDelta = sortedHRV.last!.timestamp.timeIntervalSince(sortedHRV.first!.timestamp) / 3600
            guard timeDelta > 0 else { return nil }
            
            let slope = (last - first) / timeDelta
            
            // Slow recovery = slope < 5 ms/hour
            if slope < 5 {
                return InsightEvent(
                    timestamp: Date(),
                    type: .recoveryGap,
                    severity: min(1.0 - slope / 10, 1.0),
                    message: "Your HRV isn't bouncing back. You burned \(Int(caloriesBurned)) kcal but only ate \(Int(caloriesConsumed)). Fuel up!",
                    associatedMealID: nil
                )
            }
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
    func runMorningChecks(in modelContext: ModelContext) async -> [InsightEvent] {
        var insights: [InsightEvent] = []
        
        // Morning Readiness
        if let readiness = await detectMorningReadiness() {
            insights.append(readiness)
            modelContext.insert(readiness)
        }
        
        // Brain Fog Forecast (if HRV is significantly below baseline)
        if let brainFog = await detectBrainFogForecast() {
            insights.append(brainFog)
            modelContext.insert(brainFog)
        }
        
        // Alcohol Impact (if overnight HRV was suppressed)
        if let alcohol = await detectAlcoholImpact(in: modelContext) {
            insights.append(alcohol)
            modelContext.insert(alcohol)
        }
        
        // Fasting Benefit (if applicable)
        if let fasting = await detectFastingBenefit(in: modelContext) {
            insights.append(fasting)
            modelContext.insert(fasting)
        }
        
        // Stress Buffer (end of day check - can also run in evening)
        if let stress = await detectStressBuffer(in: modelContext) {
            insights.append(stress)
            modelContext.insert(stress)
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
}
