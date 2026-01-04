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
    private func detectDigestionDebt(for meal: MealLog) async -> InsightEvent? {
        let mealHour = Calendar.current.component(.hour, from: meal.timestamp)
        
        // Simple heuristic: meals after 8 PM are "late"
        // In future, use actual sleep schedule from HealthKit
        guard mealHour >= 20 else { return nil }
        
        // Calculate severity based on how late
        let severity: Double
        if mealHour >= 22 {
            severity = 0.9
        } else if mealHour >= 21 {
            severity = 0.6
        } else {
            severity = 0.3
        }
        
        let hourString = mealHour >= 22 ? "very late" : "late"
        
        return InsightEvent(
            timestamp: meal.timestamp,
            type: .digestionDebt,
            severity: severity,
            message: "Eating this \(hourString) may keep your heart working while you sleep, reducing recovery.",
            associatedMealID: meal.id
        )
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
            
            // Detect rapid HR drop (anxiety mimic signal)
            if gradient < -1.0 {
                return InsightEvent(
                    timestamp: Date(),
                    type: .anxietyMimic,
                    severity: min(abs(gradient) / 5, 1.0),
                    message: "Feeling anxious? It might be a blood sugar dip from that \(meal.name). Try a small snack.",
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
    /// Algorithm: >100mg caffeine in last 4h + HR elevated + stable respiratory
    func detectCaffeineJitter(for meals: [MealLog]) async -> InsightEvent? {
        let fourHoursAgo = Date().addingTimeInterval(-4 * 3600)
        
        // Sum caffeine from recent meals
        let recentCaffeine = meals
            .filter { $0.timestamp > fourHoursAgo }
            .compactMap { $0.caffeine }
            .reduce(0, +)
        
        guard recentCaffeine > 100 else { return nil }
        
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
            
            if avgHR > threshold {
                return InsightEvent(
                    timestamp: Date(),
                    type: .caffeineJitter,
                    severity: min((avgHR - threshold) / 30.0, 1.0),
                    message: "Alert mode activated! That's \(Int(recentCaffeine))mg of caffeine working. Great time for focused work.",
                    associatedMealID: meals.first?.id
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
            let deepSleepMinutes = sleepLogs.compactMap { Double($0.deepSleepMinutes ?? 0) }.reduce(0, +)
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
}
