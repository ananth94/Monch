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

enum SleepStage: Sendable {
    case inBed
    case asleepCore
    case asleepDeep
    case asleepREM
    case awake
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
        
        return samples.compactMap { sample in
            let stage: SleepStage
            if #available(iOS 16.0, *) {
                switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                case .inBed: stage = .inBed
                case .asleepCore: stage = .asleepCore
                case .asleepDeep: stage = .asleepDeep
                case .asleepREM: stage = .asleepREM
                case .awake: stage = .awake
                default: stage = .inBed
                }
            } else {
                stage = sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ? .inBed : .asleepCore
            }
            return SleepSample(startDate: sample.startDate, endDate: sample.endDate, stage: stage)
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
