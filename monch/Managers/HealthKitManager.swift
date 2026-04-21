//
//  HealthKitManager.swift
//  monch
//
//  Created by Opencode Agent on 03/01/2026.
//

import Foundation
import HealthKit
import Combine
import UIKit

/// Thread-safe manager for HealthKit data access.
/// Handles authorization and provides convenience methods for fetching health metrics.
@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationError: Error?
    
    private init() {}
    
    // MARK: - Authorization
    
    /// All HealthKit data types required by Monch's insight engine
    private var requiredReadTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            // Vitals
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            
            // Activity
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.stepCount),
            HKObjectType.workoutType(),
            
            // Sleep
            HKCategoryType(.sleepAnalysis),
            
            // Nutrition
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryFatTotal)
        ]
        
        // Wrist temperature (Series 8+ only)
        if #available(iOS 16.0, *) {
            types.insert(HKQuantityType(.appleSleepingWristTemperature))
        }
        
        return types
    }
    
    /// Request authorization for all required HealthKit data types
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device.")
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: requiredReadTypes)
            // Note: For read-only permissions, iOS doesn't tell us if user granted or denied
            // We assume success if no error was thrown. The actual test is whether data comes back.
            isAuthorized = true
            print("HealthKit authorization request complete.")
        } catch {
            self.authorizationError = error
            isAuthorized = false
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
    
    /// Verify we can actually read data (the real test for read permissions)
    func verifyDataAccess() async {
        do {
            let range = Date().addingTimeInterval(-86400)...Date()
            _ = try await fetchHeartRateSamples(for: range)
            // If we got here without error, we have access
            // Empty results just means no data, not denied access
            isAuthorized = true
        } catch {
            // Actual fetch error likely means no access
            isAuthorized = false
        }
    }
    
    /// Open the Health app settings for this app (user must manually re-enable)
    func openHealthSettings() {
        guard let url = URL(string: "x-apple-health://") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Data Fetching
    
    /// Fetch heart rate samples for a date range
    /// - Parameter range: The date range to query
    /// - Returns: Array of heart rate samples with timestamps
    func fetchHeartRate(for range: ClosedRange<Date>) async throws -> [HKQuantitySample] {
        let heartRateType = HKQuantityType(.heartRate)
        return try await fetchQuantitySamples(type: heartRateType, range: range)
    }
    
    /// Fetch HRV (SDNN) samples for a date range
    /// - Parameter range: The date range to query
    /// - Returns: Array of HRV samples
    func fetchHRV(for range: ClosedRange<Date>) async throws -> [HKQuantitySample] {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        return try await fetchQuantitySamples(type: hrvType, range: range)
    }
    
    /// Fetch resting heart rate for a date range
    /// - Parameter range: The date range to query
    /// - Returns: Array of resting HR samples (typically one per day)
    func fetchRestingHeartRate(for range: ClosedRange<Date>) async throws -> [HKQuantitySample] {
        let restingHRType = HKQuantityType(.restingHeartRate)
        return try await fetchQuantitySamples(type: restingHRType, range: range)
    }
    
    /// Fetch step count samples for a date range
    /// - Parameter range: The date range to query
    /// - Returns: Array of step count samples
    func fetchStepCount(for range: ClosedRange<Date>) async throws -> [HKQuantitySample] {
        let stepType = HKQuantityType(.stepCount)
        return try await fetchQuantitySamples(type: stepType, range: range)
    }
    
    /// Fetch sleep analysis data for a date range
    /// - Parameter range: The date range to query
    /// - Returns: Array of sleep samples (includes sleep stages on watchOS 9+)
    func fetchSleep(for range: ClosedRange<Date>) async throws -> [HKCategorySample] {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: range.lowerBound, end: range.upperBound)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch workouts for a date range
    /// - Parameter range: The date range to query
    /// - Returns: Array of workout samples
    func fetchWorkouts(for range: ClosedRange<Date>) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: range.lowerBound, end: range.upperBound)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch wrist temperature samples for a date range (Series 8+ only)
    /// - Parameter range: The date range to query
    /// - Returns: Array of temperature samples, or empty if not available
    @available(iOS 16.0, *)
    func fetchWristTemperature(for range: ClosedRange<Date>) async throws -> [HKQuantitySample] {
        let tempType = HKQuantityType(.appleSleepingWristTemperature)
        return try await fetchQuantitySamples(type: tempType, range: range)
    }
    
    // MARK: - Convenience Methods
    
    /// Backfill the last 7 days of health data for baseline calculation
    /// - Returns: A summary of fetched data counts
    func backfillLastSevenDays() async throws -> BackfillSummary {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let range = sevenDaysAgo...now
        
        async let heartRates = fetchHeartRate(for: range)
        async let hrvSamples = fetchHRV(for: range)
        async let restingHR = fetchRestingHeartRate(for: range)
        async let sleepData = fetchSleep(for: range)
        async let workouts = fetchWorkouts(for: range)
        
        let (hr, hrv, rhr, sleep, wo) = try await (heartRates, hrvSamples, restingHR, sleepData, workouts)
        
        return BackfillSummary(
            heartRateSamples: hr.count,
            hrvSamples: hrv.count,
            restingHRSamples: rhr.count,
            sleepSamples: sleep.count,
            workoutSamples: wo.count
        )
    }
    
    // MARK: - Private Helpers
    
    private func fetchQuantitySamples(type: HKQuantityType, range: ClosedRange<Date>) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: range.lowerBound, end: range.upperBound)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Nutrition / Meal Events
    
    func fetchImportedMealEvents(for range: ClosedRange<Date>) async throws -> [ImportedMealEvent] {
        async let dietaryEnergySamples = fetchQuantitySamples(type: HKQuantityType(.dietaryEnergyConsumed), range: range)
        async let carbohydrateSamples = fetchQuantitySamples(type: HKQuantityType(.dietaryCarbohydrates), range: range)
        async let proteinSamples = fetchQuantitySamples(type: HKQuantityType(.dietaryProtein), range: range)
        async let fatSamples = fetchQuantitySamples(type: HKQuantityType(.dietaryFatTotal), range: range)
        
        let samplePoints = try await nutritionSamplePoints(
            energySamples: dietaryEnergySamples,
            carbohydrateSamples: carbohydrateSamples,
            proteinSamples: proteinSamples,
            fatSamples: fatSamples
        )
        
        return inferImportedMealEvents(from: samplePoints)
    }
    
    func fetchNutritionEventDates(for range: ClosedRange<Date>) async throws -> [Date] {
        try await fetchImportedMealEvents(for: range).map(\.timestamp)
    }
    
    func fetchNutritionEventCounts(for range: ClosedRange<Date>) async throws -> [Date: Int] {
        let inferredEvents = try await fetchNutritionEventDates(for: range)
        return countNutritionEventsByDay(inferredEvents)
    }
    
    private func fetchQuantitySampleDates(type: HKQuantityType, range: ClosedRange<Date>) async throws -> [Date] {
        let samples = try await fetchQuantitySamples(type: type, range: range)
        return samples.map(\.startDate)
    }
    
    private func nutritionSamplePoints(
        energySamples: [HKQuantitySample],
        carbohydrateSamples: [HKQuantitySample],
        proteinSamples: [HKQuantitySample],
        fatSamples: [HKQuantitySample]
    ) -> [ImportedNutritionSamplePoint] {
        let energyUnit = HKUnit.kilocalorie()
        let macroUnit = HKUnit.gram()
        
        let energyPoints = energySamples.map {
            ImportedNutritionSamplePoint(
                timestamp: $0.startDate,
                foodType: $0.metadata?[HKMetadataKeyFoodType] as? String,
                sourceName: $0.sourceRevision.source.name,
                calories: $0.quantity.doubleValue(for: energyUnit)
            )
        }
        let carbohydratePoints = carbohydrateSamples.map {
            ImportedNutritionSamplePoint(
                timestamp: $0.startDate,
                foodType: $0.metadata?[HKMetadataKeyFoodType] as? String,
                sourceName: $0.sourceRevision.source.name,
                carbs: $0.quantity.doubleValue(for: macroUnit)
            )
        }
        let proteinPoints = proteinSamples.map {
            ImportedNutritionSamplePoint(
                timestamp: $0.startDate,
                foodType: $0.metadata?[HKMetadataKeyFoodType] as? String,
                sourceName: $0.sourceRevision.source.name,
                protein: $0.quantity.doubleValue(for: macroUnit)
            )
        }
        let fatPoints = fatSamples.map {
            ImportedNutritionSamplePoint(
                timestamp: $0.startDate,
                foodType: $0.metadata?[HKMetadataKeyFoodType] as? String,
                sourceName: $0.sourceRevision.source.name,
                fat: $0.quantity.doubleValue(for: macroUnit)
            )
        }
        
        return energyPoints + carbohydratePoints + proteinPoints + fatPoints
    }
    
    private func inferImportedMealEvents(from samplePoints: [ImportedNutritionSamplePoint]) -> [ImportedMealEvent] {
        let sortedSamplePoints = samplePoints.sorted { $0.timestamp < $1.timestamp }
        guard !sortedSamplePoints.isEmpty else { return [] }
        
        let clusteringWindow: TimeInterval = 20 * 60
        var inferredEvents: [ImportedMealEvent] = []
        
        var currentCluster: [ImportedNutritionSamplePoint] = [sortedSamplePoints[0]]
        var clusterAnchor = sortedSamplePoints[0].timestamp
        
        for samplePoint in sortedSamplePoints.dropFirst() {
            if samplePoint.timestamp.timeIntervalSince(clusterAnchor) > clusteringWindow {
                if let event = buildImportedMealEvent(from: currentCluster) {
                    inferredEvents.append(event)
                }
                currentCluster = [samplePoint]
                clusterAnchor = samplePoint.timestamp
            } else {
                currentCluster.append(samplePoint)
            }
        }
        
        if let event = buildImportedMealEvent(from: currentCluster) {
            inferredEvents.append(event)
        }
        
        return inferredEvents
    }
    
    private func countNutritionEventsByDay(_ inferredEvents: [Date]) -> [Date: Int] {
        let calendar = Calendar.current
        var countsByDay: [Date: Int] = [:]
        
        for timestamp in inferredEvents {
            countsByDay[calendar.startOfDay(for: timestamp), default: 0] += 1
        }
        
        return countsByDay
    }
    
    private func buildImportedMealEvent(from cluster: [ImportedNutritionSamplePoint]) -> ImportedMealEvent? {
        guard let first = cluster.first else { return nil }
        
        let title = cluster.compactMap(\.foodType).first { !$0.isEmpty }
        let sourceName = cluster.compactMap(\.sourceName).first { !$0.isEmpty }
        
        return ImportedMealEvent(
            timestamp: first.timestamp,
            title: title ?? "Imported Meal",
            sourceName: sourceName,
            calories: cluster.reduce(0) { $0 + ($1.calories ?? 0) },
            carbs: cluster.reduce(0) { $0 + ($1.carbs ?? 0) },
            protein: cluster.reduce(0) { $0 + ($1.protein ?? 0) },
            fat: cluster.reduce(0) { $0 + ($1.fat ?? 0) }
        )
    }
}

// MARK: - Supporting Types

struct ImportedMealEvent: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let title: String
    let sourceName: String?
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    
    init(
        id: UUID = UUID(),
        timestamp: Date,
        title: String,
        sourceName: String?,
        calories: Double,
        carbs: Double,
        protein: Double,
        fat: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.sourceName = sourceName
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
    }
    
    var hasNutritionDetails: Bool {
        calories > 0 || carbs > 0 || protein > 0 || fat > 0
    }
}

private struct ImportedNutritionSamplePoint {
    let timestamp: Date
    let foodType: String?
    let sourceName: String?
    var calories: Double? = nil
    var carbs: Double? = nil
    var protein: Double? = nil
    var fat: Double? = nil
}

struct BackfillSummary {
    let heartRateSamples: Int
    let hrvSamples: Int
    let restingHRSamples: Int
    let sleepSamples: Int
    let workoutSamples: Int
    
    var totalSamples: Int {
        heartRateSamples + hrvSamples + restingHRSamples + sleepSamples + workoutSamples
    }
}
