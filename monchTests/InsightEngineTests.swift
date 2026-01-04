//
//  InsightEngineTests.swift
//  monchTests
//
//  Unit tests for InsightEngine insight detection algorithms.
//

import XCTest
@testable import monch

final class InsightEngineTests: XCTestCase {
    
    // MARK: - Sugar Spike Detection with Mock HR Data
    
    @MainActor
    func testSugarSpikeDetectedWithHRSpike() async {
        // Given a mock provider with baseline 70bpm and spike to 90bpm
        let mockProvider = MockHealthKitDataProvider()
        let engine = InsightEngine(healthKitProvider: mockProvider)
        
        let mealTime = Date().addingTimeInterval(-3700) // 61+ min ago (past analysis window)
        
        // Baseline samples (30 min before meal)
        let baselineStart = mealTime.addingTimeInterval(-1800)
        mockProvider.heartRateSamples = [
            HeartRateSample(timestamp: baselineStart, bpm: 68),
            HeartRateSample(timestamp: baselineStart.addingTimeInterval(300), bpm: 70),
            HeartRateSample(timestamp: baselineStart.addingTimeInterval(600), bpm: 72),
            HeartRateSample(timestamp: baselineStart.addingTimeInterval(900), bpm: 70),
            HeartRateSample(timestamp: baselineStart.addingTimeInterval(1200), bpm: 71),
            // Post-meal samples (spike within 40 min)
            HeartRateSample(timestamp: mealTime.addingTimeInterval(1200), bpm: 85), // 20 min
            HeartRateSample(timestamp: mealTime.addingTimeInterval(1800), bpm: 92), // 30 min - PEAK (+22bpm)
            HeartRateSample(timestamp: mealTime.addingTimeInterval(2400), bpm: 88), // 40 min
            HeartRateSample(timestamp: mealTime.addingTimeInterval(3000), bpm: 78), // 50 min
        ]
        
        // Create high-carb meal
        let meal = MealLog(name: "Pasta", calories: 600, carbs: 80, protein: 20, fat: 15)
        // Override timestamp
        meal.timestamp = mealTime
        
        // When detecting sugar spike
        let insight = await engine.detectSugarSpikeTestable(for: meal)
        
        // Then insight should be generated
        XCTAssertNotNil(insight, "Sugar spike should be detected with 22bpm increase within 30min")
        XCTAssertEqual(insight?.type, .sugarSpike)
        XCTAssertGreaterThan(insight?.severity ?? 0, 0.5, "Severity should reflect 22bpm increase")
    }
    
    @MainActor
    func testNoSugarSpikeWithLowHRIncrease() async {
        // Given a mock provider with only 10bpm increase (below threshold)
        let mockProvider = MockHealthKitDataProvider()
        let engine = InsightEngine(healthKitProvider: mockProvider)
        
        let mealTime = Date().addingTimeInterval(-3700)
        let baselineStart = mealTime.addingTimeInterval(-1800)
        
        mockProvider.heartRateSamples = [
            HeartRateSample(timestamp: baselineStart, bpm: 70),
            HeartRateSample(timestamp: baselineStart.addingTimeInterval(600), bpm: 72),
            // Post-meal - only 10bpm increase
            HeartRateSample(timestamp: mealTime.addingTimeInterval(1800), bpm: 80), // Only +10bpm
        ]
        
        let meal = MealLog(name: "Light Snack", calories: 300, carbs: 40, protein: 10, fat: 10)
        meal.timestamp = mealTime
        
        // When detecting
        let insight = await engine.detectSugarSpikeTestable(for: meal)
        
        // Then no insight (10bpm < 15bpm threshold)
        XCTAssertNil(insight, "10bpm increase should not trigger sugar spike")
    }
    
    @MainActor
    func testNoSugarSpikeWithLowCarbs() async {
        // Given a low-carb meal
        let mockProvider = MockHealthKitDataProvider()
        let engine = InsightEngine(healthKitProvider: mockProvider)
        
        let meal = MealLog(name: "Steak", calories: 500, carbs: 5, protein: 50, fat: 30)
        
        // When detecting
        let insight = await engine.detectSugarSpikeTestable(for: meal)
        
        // Then no insight (carbs < 30g)
        XCTAssertNil(insight, "Low carb meal should not trigger sugar spike detection")
    }
    
    @MainActor
    func testSugarSpikeTimingGate() async {
        // Given HR spike that occurs too late (> 40 min)
        let mockProvider = MockHealthKitDataProvider()
        let engine = InsightEngine(healthKitProvider: mockProvider)
        
        let mealTime = Date().addingTimeInterval(-3700)
        let baselineStart = mealTime.addingTimeInterval(-1800)
        
        mockProvider.heartRateSamples = [
            HeartRateSample(timestamp: baselineStart, bpm: 70),
            // Peak at 50 min (outside 40 min window)
            HeartRateSample(timestamp: mealTime.addingTimeInterval(3000), bpm: 95),
        ]
        
        let meal = MealLog(name: "Pasta", calories: 600, carbs: 80, protein: 20, fat: 15)
        meal.timestamp = mealTime
        
        // When detecting
        let insight = await engine.detectSugarSpikeTestable(for: meal)
        
        // Then no insight (peak at 50 min > 40 min threshold)
        XCTAssertNil(insight, "Spike at 50 min should not trigger (> 40 min threshold)")
    }
    
    // MARK: - Digestion Debt Detection
    
    @MainActor
    func testDigestionDebtTriggeredAt10PM() async {
        let mockProvider = MockHealthKitDataProvider()
        let engine = InsightEngine(healthKitProvider: mockProvider)
        
        // Create meal at 10 PM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 22
        components.minute = 0
        let lateTime = Calendar.current.date(from: components)!
        
        let meal = MealLog(name: "Late Snack", calories: 400, carbs: 50, protein: 15, fat: 20)
        meal.timestamp = lateTime
        
        // When detecting
        let insight = await engine.detectDigestionDebtTestable(for: meal)
        
        // Then insight should be generated with high severity
        XCTAssertNotNil(insight, "10 PM meal should trigger digestion debt")
        XCTAssertEqual(insight?.type, .digestionDebt)
        XCTAssertEqual(insight?.severity, 0.9, "10 PM should have severity 0.9")
    }
    
    @MainActor
    func testNoDigestionDebtAt6PM() async {
        let mockProvider = MockHealthKitDataProvider()
        let engine = InsightEngine(healthKitProvider: mockProvider)
        
        // Create meal at 6 PM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 0
        let earlyTime = Calendar.current.date(from: components)!
        
        let meal = MealLog(name: "Dinner", calories: 600, carbs: 60, protein: 30, fat: 25)
        meal.timestamp = earlyTime
        
        // When detecting
        let insight = await engine.detectDigestionDebtTestable(for: meal)
        
        // Then no insight
        XCTAssertNil(insight, "6 PM meal should not trigger digestion debt")
    }
    
    // MARK: - Mood Mapping
    
    @MainActor
    func testMoodWithNoMealsIsHungry() async {
        let engine = InsightEngine.shared
        engine.refreshMood(meals: [], insights: [])
        XCTAssertEqual(engine.currentMood, .hungry)
    }
    
    @MainActor
    func testMoodAfterRecentMealIsDigesting() async {
        let engine = InsightEngine.shared
        let recentMeal = MealLog(name: "Lunch", calories: 500, carbs: 50, protein: 30, fat: 20)
        
        engine.refreshMood(meals: [recentMeal], insights: [])
        XCTAssertEqual(engine.currentMood, .digesting)
    }
    
    // MARK: - Muscle Sponge / Anabolic Window Tests
    
    @MainActor
    func testQualifyingWorkoutThresholds() {
        let engine = InsightEngine.shared
        
        // 1. Calories threshold (exactly 300)
        let workout1 = WorkoutLog(type: .running, startTime: Date(), endTime: Date(), activeCalories: 300)
        XCTAssertTrue(engine.qualifyingWorkout(workout1), "Exactly 300kcal should qualify")
        
        // 2. Calories below threshold
        let workout2 = WorkoutLog(type: .running, startTime: Date(), endTime: Date(), activeCalories: 299)
        XCTAssertFalse(engine.qualifyingWorkout(workout2), "299kcal should not qualify if zone is low")
        
        // 3. Zone threshold (exactly 3)
        let workout3 = WorkoutLog(type: .running, startTime: Date(), endTime: Date(), activeCalories: 100)
        workout3.dominantHRZone = 3
        XCTAssertTrue(engine.qualifyingWorkout(workout3), "Zone 3 should qualify even with low calories")
        
        // 4. Zone below threshold
        let workout4 = WorkoutLog(type: .running, startTime: Date(), endTime: Date(), activeCalories: 100)
        workout4.dominantHRZone = 2
        XCTAssertFalse(engine.qualifyingWorkout(workout4), "Zone 2 with low calories should not qualify")
        
        // 5. Both thresholds met
        let workout5 = WorkoutLog(type: .running, startTime: Date(), endTime: Date(), activeCalories: 500)
        workout5.dominantHRZone = 4
        XCTAssertTrue(engine.qualifyingWorkout(workout5), "Meeting both thresholds should qualify")
    }
}

// MARK: - Test Helpers

extension InsightEngine {
    /// Testable version of detectSugarSpike (skips real-time window check)
    func detectSugarSpikeTestable(for meal: MealLog) async -> InsightEvent? {
        guard let carbs = meal.carbs, carbs > 30 else { return nil }
        
        let mealTime = meal.timestamp
        let baselineStart = mealTime.addingTimeInterval(-1800)
        let windowEnd = mealTime.addingTimeInterval(3600)
        
        do {
            let baselineRange = baselineStart...mealTime
            let postMealRange = mealTime...windowEnd
            
            let baselineHR = try await healthKitProvider.fetchHeartRateSamples(for: baselineRange)
            let postMealHR = try await healthKitProvider.fetchHeartRateSamples(for: postMealRange)
            
            let baselineValues = baselineHR.map(\.bpm)
            guard !baselineValues.isEmpty else { return nil }
            let baseline = baselineValues.sorted()[baselineValues.count / 2]
            
            var peak: Double = 0
            var peakTime: Date?
            for sample in postMealHR {
                if sample.bpm > peak {
                    peak = sample.bpm
                    peakTime = sample.timestamp
                }
            }
            
            guard let peakTime = peakTime else { return nil }
            
            let timeToPeak = peakTime.timeIntervalSince(mealTime) / 60
            let hrIncrease = peak - baseline
            
            if timeToPeak < 40 && hrIncrease > 15 {
                let severity = min(hrIncrease / 30, 1.0)
                return InsightEvent(
                    timestamp: peakTime,
                    type: .sugarSpike,
                    severity: severity,
                    message: "Test spike",
                    associatedMealID: meal.id
                )
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    /// Testable version of detectDigestionDebt
    func detectDigestionDebtTestable(for meal: MealLog) async -> InsightEvent? {
        let mealHour = Calendar.current.component(.hour, from: meal.timestamp)
        guard mealHour >= 20 else { return nil }
        
        let severity: Double
        if mealHour >= 22 {
            severity = 0.9
        } else if mealHour >= 21 {
            severity = 0.6
        } else {
            severity = 0.3
        }
        
        return InsightEvent(
            timestamp: meal.timestamp,
            type: .digestionDebt,
            severity: severity,
            message: "Test debt",
            associatedMealID: meal.id
        )
    }
}
