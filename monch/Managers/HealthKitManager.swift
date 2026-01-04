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
            HKCategoryType(.sleepAnalysis)
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
            await checkAuthorizationStatus()
            print("HealthKit authorization request complete.")
        } catch {
            self.authorizationError = error
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
    
    /// Check if we have authorization for at least heart rate data
    func checkAuthorizationStatus() async {
        let heartRateType = HKQuantityType(.heartRate)
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        switch status {
        case .sharingAuthorized:
            isAuthorized = true
        case .sharingDenied, .notDetermined:
            isAuthorized = false
        @unknown default:
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
}

// MARK: - Supporting Types

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
