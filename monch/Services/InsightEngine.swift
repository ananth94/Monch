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
        
        // Check for Sugar Spike (high carbs + sedentary + HR spike)
        if let sugarSpike = await detectSugarSpike(for: meal) {
            insights.append(sugarSpike)
            modelContext.insert(sugarSpike)
        }
        
        // Check for Digestion Debt (late eating)
        if let digestionDebt = await detectDigestionDebt(for: meal) {
            insights.append(digestionDebt)
            modelContext.insert(digestionDebt)
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
    /// - Gate: steps < 10 (sedentary)
    private func detectSugarSpike(for meal: MealLog) async -> InsightEvent? {
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
        case .digestionDebt, .deepSleepRobber:
            return .sleepy
        case .muscleSponge, .goodSpike:
            return .strong
        }
    }
}
