//
//  HealthKitDataProvider.swift
//  monch
//
//  Protocol abstracting HealthKit data access for testability.
//

import Foundation
import HealthKit

/// Protocol for HealthKit data fetching, enabling mock implementations for testing
protocol HealthKitDataProvider: Sendable {
    func fetchHeartRateSamples(for range: ClosedRange<Date>) async throws -> [HeartRateSample]
    func fetchSleepSamples(for range: ClosedRange<Date>) async throws -> [SleepSample]
}

/// Simplified heart rate sample for cross-boundary use
struct HeartRateSample: Sendable {
    let timestamp: Date
    let bpm: Double
}

/// Simplified sleep sample
struct SleepSample: Sendable {
    let startDate: Date
    let endDate: Date
    let stage: SleepStage
}

/// Sleep stage types matching HealthKit's HKCategoryValueSleepAnalysis
enum SleepStage: String, Codable, CaseIterable, Sendable {
    case awake = "awake"
    case light = "light"      // asleepCore in HealthKit
    case rem = "rem"          // asleepREM in HealthKit
    case deep = "deep"        // asleepDeep in HealthKit
    case inBed = "inBed"      // inBed (not asleep)
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light"
        case .rem: return "REM"
        case .deep: return "Deep"
        case .inBed: return "In Bed"
        }
    }
    
    /// Color association for charts (uses design system indirectly)
    var colorName: String {
        switch self {
        case .awake: return "coral"
        case .light: return "lavender"
        case .rem: return "periwinkle"
        case .deep: return "midnightNavy"
        case .inBed: return "cream"
        }
    }
    
    /// Y-axis position for hypnogram (0 = awake, 3 = deep)
    var depthValue: Int {
        switch self {
        case .awake: return 0
        case .inBed: return 0
        case .light: return 1
        case .rem: return 2
        case .deep: return 3
        }
    }
    
    /// Initialize from HealthKit category value
    init(fromHealthKit value: Int) {
        switch value {
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            self = .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            self = .rem
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
             HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            self = .light
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            self = .awake
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            self = .inBed
        default:
            self = .light
        }
    }
}

// MARK: - Production Implementation

extension HealthKitManager: HealthKitDataProvider {
    nonisolated func fetchHeartRateSamples(for range: ClosedRange<Date>) async throws -> [HeartRateSample] {
        let heartRateType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: range.lowerBound, end: range.upperBound)
        
        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
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
            self.healthStore.execute(query)
        }
        
        return samples.map { sample in
            HeartRateSample(
                timestamp: sample.startDate,
                bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            )
        }
    }
    
    nonisolated func fetchSleepSamples(for range: ClosedRange<Date>) async throws -> [SleepSample] {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: range.lowerBound, end: range.upperBound)
        
        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
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
            self.healthStore.execute(query)
        }
        
        return samples.map { sample in
            SleepSample(
                startDate: sample.startDate,
                endDate: sample.endDate,
                stage: SleepStage(fromHealthKit: sample.value)
            )
        }
    }
}

// MARK: - Mock Implementation for Testing

final class MockHealthKitDataProvider: HealthKitDataProvider, @unchecked Sendable {
    var heartRateSamples: [HeartRateSample] = []
    var sleepSamples: [SleepSample] = []
    var shouldThrowError = false
    
    func fetchHeartRateSamples(for range: ClosedRange<Date>) async throws -> [HeartRateSample] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: -1)
        }
        return heartRateSamples.filter { range.contains($0.timestamp) }
    }
    
    func fetchSleepSamples(for range: ClosedRange<Date>) async throws -> [SleepSample] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: -1)
        }
        return sleepSamples.filter { range.contains($0.startDate) }
    }
}
