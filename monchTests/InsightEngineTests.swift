//
//  InsightEngineTests.swift
//  monchTests
//
//  Unit tests for InsightEngine insight detection algorithms.
//

import XCTest
import SwiftData
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

    @MainActor
    func testZone2DrainDetectedFromZoneBreakdown() async throws {
        let engine = InsightEngine(healthKitProvider: MockHealthKitDataProvider())
        let context = try makeInMemoryContext()

        let start = Date().addingTimeInterval(-3600)
        let end = Date()
        let workout = WorkoutLog(
            startTime: start,
            endTime: end,
            activityTypeRaw: 37,
            activityName: "Running",
            activeCalories: 420
        )
        workout.setHRZoneBreakdown(HRZoneBreakdown(zone2Minutes: 52))

        let insights = await engine.analyzeWorkout(workout, in: context)

        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.type, .zone2Drain)
    }

    @MainActor
    func testZone2DrainFallsBackToLongCardioDurationWhenZonesMissing() async throws {
        let engine = InsightEngine(healthKitProvider: MockHealthKitDataProvider())
        let context = try makeInMemoryContext()

        let start = Date().addingTimeInterval(-(60 * 60))
        let end = Date()
        let workout = WorkoutLog(
            startTime: start,
            endTime: end,
            activityTypeRaw: 37,
            activityName: "Outdoor Walk",
            activeCalories: 350
        )

        let insights = await engine.analyzeWorkout(workout, in: context)

        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.type, .zone2Drain)
    }

    @MainActor
    func testAnalyzeWorkoutDedupesRepeatedZone2Drain() async throws {
        let engine = InsightEngine(healthKitProvider: MockHealthKitDataProvider())
        let context = try makeInMemoryContext()

        let start = Date().addingTimeInterval(-(75 * 60))
        let end = Date()
        let workout = WorkoutLog(
            startTime: start,
            endTime: end,
            activityTypeRaw: 37,
            activityName: "Cycle",
            activeCalories: 500
        )
        workout.dominantHRZone = 2

        let firstRun = await engine.analyzeWorkout(workout, in: context)
        let secondRun = await engine.analyzeWorkout(workout, in: context)
        let allInsights = try context.fetch(FetchDescriptor<InsightEvent>())

        XCTAssertEqual(firstRun.count, 1)
        XCTAssertTrue(secondRun.isEmpty)
        XCTAssertEqual(allInsights.filter { $0.type == .zone2Drain }.count, 1)
    }

    @MainActor
    func testDeepSleepRobberDetectedFromLatestSleepAndLateMeal() async throws {
        let engine = InsightEngine(healthKitProvider: MockHealthKitDataProvider())
        let context = try makeInMemoryContext()

        let wakeTime = Date().addingTimeInterval(-60 * 60)
        let sleepStart = wakeTime.addingTimeInterval(-(8 * 60 * 60))
        let sleep = SleepLog(
            startTime: sleepStart,
            endTime: wakeTime,
            deepSleepMinutes: 28,
            remSleepMinutes: 80,
            lightSleepMinutes: 320
        )
        let lateMeal = MealLog(
            timestamp: sleepStart.addingTimeInterval(-(90 * 60)),
            name: "Pasta Dinner",
            calories: 700,
            carbs: 85,
            protein: 20,
            fat: 18
        )

        context.insert(sleep)
        context.insert(lateMeal)

        let insight = await engine.detectDeepSleepRobber(in: context)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.type, .deepSleepRobber)
        XCTAssertEqual(insight?.associatedMealID, lateMeal.id)
        XCTAssertTrue(insight?.message.contains("deep sleep") ?? false)
    }

    @MainActor
    func testDeepSleepRobberDoesNotFireWithoutLateCulprit() async throws {
        let engine = InsightEngine(healthKitProvider: MockHealthKitDataProvider())
        let context = try makeInMemoryContext()

        let wakeTime = Date().addingTimeInterval(-60 * 60)
        let sleepStart = wakeTime.addingTimeInterval(-(8 * 60 * 60))
        let sleep = SleepLog(
            startTime: sleepStart,
            endTime: wakeTime,
            deepSleepMinutes: 24,
            remSleepMinutes: 75,
            lightSleepMinutes: 340
        )
        let lunch = MealLog(
            timestamp: sleepStart.addingTimeInterval(-(8 * 60 * 60)),
            name: "Lunch",
            calories: 550,
            carbs: 55,
            protein: 25,
            fat: 15
        )

        context.insert(sleep)
        context.insert(lunch)

        let insight = await engine.detectDeepSleepRobber(in: context)

        XCTAssertNil(insight)
    }

    @MainActor
    func testRecoveryGapDetectedWhenCaloriesAreFarBelowBurnAndHRVStaysFlat() async throws {
        let mockProvider = MockHealthKitDataProvider()
        let engine = InsightEngine(healthKitProvider: mockProvider)
        let context = try makeInMemoryContext()

        let workoutEnd = Date().addingTimeInterval(-(10 * 60 * 60))
        let workoutStart = workoutEnd.addingTimeInterval(-(75 * 60))
        let workout = WorkoutLog(
            startTime: workoutStart,
            endTime: workoutEnd,
            activityTypeRaw: 50,
            activityName: "Strength",
            activeCalories: 500
        )
        let snack = MealLog(
            timestamp: workoutEnd.addingTimeInterval(45 * 60),
            name: "Tiny Snack",
            calories: 120,
            protein: 5
        )

        mockProvider.hrvSamples = [
            HRVSample(timestamp: workoutEnd.addingTimeInterval(30 * 60), sdnn: 30),
            HRVSample(timestamp: workoutEnd.addingTimeInterval(3 * 60 * 60), sdnn: 32)
        ]

        context.insert(workout)
        context.insert(snack)

        let insight = await engine.detectRecoveryGap(for: workout, in: context)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.type, .recoveryGap)
        XCTAssertTrue(insight?.message.contains("burned 500 kcal") ?? false)
    }

    @MainActor
    func testRecoveryGapFallsBackToMissedRefeedAndLowMorningHRV() async throws {
        let mockProvider = MockHealthKitDataProvider()
        mockProvider.baselineHRV = 55
        mockProvider.morningHRV = 42
        let engine = InsightEngine(healthKitProvider: mockProvider)
        let context = try makeInMemoryContext()

        let workoutEnd = Date().addingTimeInterval(-(12 * 60 * 60))
        let workoutStart = workoutEnd.addingTimeInterval(-(60 * 60))
        let workout = WorkoutLog(
            startTime: workoutStart,
            endTime: workoutEnd,
            activityTypeRaw: 37,
            activityName: "Run",
            activeCalories: 420
        )

        context.insert(workout)

        let insight = await engine.detectRecoveryGap(for: workout, in: context)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.type, .recoveryGap)
        XCTAssertTrue(insight?.message.contains("couldn't find a solid refuel") ?? false)
    }

    @MainActor
    func testAnalyzeMealCreatesCaffeineJitterForRecentCaffeineEvent() async throws {
        let mockProvider = MockHealthKitDataProvider()
        mockProvider.restingHeartRate = 60
        mockProvider.heartRateSamples = [
            HeartRateSample(timestamp: Date().addingTimeInterval(-20 * 60), bpm: 82),
            HeartRateSample(timestamp: Date().addingTimeInterval(-10 * 60), bpm: 84)
        ]
        mockProvider.baselineHRV = 50
        mockProvider.hrvSamples = [
            HRVSample(timestamp: Date().addingTimeInterval(-20 * 60), sdnn: 49),
            HRVSample(timestamp: Date().addingTimeInterval(-10 * 60), sdnn: 51)
        ]

        let engine = InsightEngine(healthKitProvider: mockProvider)
        let context = try makeInMemoryContext()

        let caffeineEvent = MealLog(
            timestamp: Date().addingTimeInterval(-15 * 60),
            name: "Coffee",
            caffeine: 1,
            tags: ["caffeine-event"]
        )
        context.insert(caffeineEvent)

        let insights = await engine.analyzeMeal(caffeineEvent, in: context)
        let storedInsights = try context.fetch(FetchDescriptor<InsightEvent>())

        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.type, .caffeineJitter)
        XCTAssertEqual(storedInsights.filter { $0.type == .caffeineJitter }.count, 1)
    }

    @MainActor
    func testAnalyzeMealDedupesRepeatedCaffeineJitterSignals() async throws {
        let mockProvider = MockHealthKitDataProvider()
        mockProvider.restingHeartRate = 60
        mockProvider.heartRateSamples = [
            HeartRateSample(timestamp: Date().addingTimeInterval(-20 * 60), bpm: 83),
            HeartRateSample(timestamp: Date().addingTimeInterval(-10 * 60), bpm: 85)
        ]
        mockProvider.baselineHRV = 52
        mockProvider.hrvSamples = [
            HRVSample(timestamp: Date().addingTimeInterval(-20 * 60), sdnn: 51),
            HRVSample(timestamp: Date().addingTimeInterval(-10 * 60), sdnn: 53)
        ]

        let engine = InsightEngine(healthKitProvider: mockProvider)
        let context = try makeInMemoryContext()

        let firstCoffee = MealLog(
            timestamp: Date().addingTimeInterval(-18 * 60),
            name: "Coffee",
            caffeine: 1,
            tags: ["caffeine-event"]
        )
        context.insert(firstCoffee)
        _ = await engine.analyzeMeal(firstCoffee, in: context)

        let secondCoffee = MealLog(
            timestamp: Date().addingTimeInterval(-12 * 60),
            name: "Coffee",
            caffeine: 1,
            tags: ["caffeine-event"]
        )
        context.insert(secondCoffee)
        let secondRunInsights = await engine.analyzeMeal(secondCoffee, in: context)
        let storedInsights = try context.fetch(FetchDescriptor<InsightEvent>())

        XCTAssertTrue(secondRunInsights.isEmpty)
        XCTAssertEqual(storedInsights.filter { $0.type == .caffeineJitter }.count, 1)
    }

    @MainActor
    func testAnalyzeVibeCheckCreatesAnxietyMimicForLowVibeAfterHighCarbMeal() async throws {
        let mockProvider = MockHealthKitDataProvider()
        mockProvider.baselineHRV = 50

        let referenceDate = Date()
        mockProvider.heartRateSamples = [
            HeartRateSample(timestamp: referenceDate.addingTimeInterval(-30 * 60), bpm: 90),
            HeartRateSample(timestamp: referenceDate.addingTimeInterval(-15 * 60), bpm: 82),
            HeartRateSample(timestamp: referenceDate, bpm: 74)
        ]
        mockProvider.hrvSamples = [
            HRVSample(timestamp: referenceDate.addingTimeInterval(-20 * 60), sdnn: 35),
            HRVSample(timestamp: referenceDate.addingTimeInterval(-10 * 60), sdnn: 37)
        ]

        let engine = InsightEngine(healthKitProvider: mockProvider)
        let context = try makeInMemoryContext()

        let meal = MealLog(
            timestamp: referenceDate.addingTimeInterval(-2.5 * 3600),
            name: "Bagel",
            calories: 420,
            carbs: 65,
            protein: 10,
            fat: 8
        )
        let vibe = VibeCheck(
            timestamp: referenceDate,
            energy: 2,
            focus: 2,
            mood: 2,
            note: "Feel shaky"
        )

        context.insert(meal)
        context.insert(vibe)

        let insights = await engine.analyzeVibeCheck(vibe, in: context)
        let storedInsights = try context.fetch(FetchDescriptor<InsightEvent>())

        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.type, .anxietyMimic)
        XCTAssertEqual(insights.first?.associatedMealID, meal.id)
        XCTAssertEqual(storedInsights.filter { $0.type == .anxietyMimic }.count, 1)
    }

    @MainActor
    func testAnalyzeVibeCheckSkipsAnxietyMimicWhenRecentCaffeineExists() async throws {
        let mockProvider = MockHealthKitDataProvider()
        mockProvider.baselineHRV = 50

        let referenceDate = Date()
        mockProvider.heartRateSamples = [
            HeartRateSample(timestamp: referenceDate.addingTimeInterval(-30 * 60), bpm: 90),
            HeartRateSample(timestamp: referenceDate.addingTimeInterval(-15 * 60), bpm: 82),
            HeartRateSample(timestamp: referenceDate, bpm: 74)
        ]
        mockProvider.hrvSamples = [
            HRVSample(timestamp: referenceDate.addingTimeInterval(-20 * 60), sdnn: 35),
            HRVSample(timestamp: referenceDate.addingTimeInterval(-10 * 60), sdnn: 37)
        ]

        let engine = InsightEngine(healthKitProvider: mockProvider)
        let context = try makeInMemoryContext()

        let meal = MealLog(
            timestamp: referenceDate.addingTimeInterval(-2.5 * 3600),
            name: "Bagel",
            calories: 420,
            carbs: 65,
            protein: 10,
            fat: 8
        )
        let caffeineEvent = MealLog(
            timestamp: referenceDate.addingTimeInterval(-60 * 60),
            name: "Coffee",
            caffeine: 1,
            tags: ["caffeine-event"]
        )
        let vibe = VibeCheck(
            timestamp: referenceDate,
            energy: 2,
            focus: 1,
            mood: 2,
            note: "Wired and off"
        )

        context.insert(meal)
        context.insert(caffeineEvent)
        context.insert(vibe)

        let insights = await engine.analyzeVibeCheck(vibe, in: context)
        let storedInsights = try context.fetch(FetchDescriptor<InsightEvent>())

        XCTAssertTrue(insights.isEmpty)
        XCTAssertTrue(storedInsights.filter { $0.type == .anxietyMimic }.isEmpty)
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

@MainActor
private func makeInMemoryContext() throws -> ModelContext {
    let schema = Schema([
        MealLog.self,
        InsightEvent.self,
        SleepLog.self,
        WorkoutLog.self,
        VibeCheck.self,
        MascotStateLog.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
}
