//
//  HRVSample.swift
//  monch
//
//  Model representing a Heart Rate Variability (SDNN) sample from HealthKit.
//

import Foundation
import HealthKit

/// A single HRV measurement from Apple Watch
struct HRVSample: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let sdnn: Double  // milliseconds
    
    init(id: UUID = UUID(), timestamp: Date, sdnn: Double) {
        self.id = id
        self.timestamp = timestamp
        self.sdnn = sdnn
    }
    
    /// Initialize from HealthKit sample
    nonisolated init(from sample: HKQuantitySample) {
        self.id = UUID()
        self.timestamp = sample.startDate
        self.sdnn = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
    }
    
    // MARK: - HRV State Classification
    
    /// HRV below 30ms typically indicates high stress or poor recovery
    var isLow: Bool { sdnn < 30 }
    
    /// HRV between 30-100ms is considered normal range for most adults
    var isNormal: Bool { sdnn >= 30 && sdnn <= 100 }
    
    /// HRV above 100ms indicates excellent recovery/relaxation
    var isHigh: Bool { sdnn > 100 }
    
    /// Human-readable state
    var state: HRVState {
        if isHigh { return .high }
        if isLow { return .low }
        return .normal
    }
}

/// HRV state for UI display
enum HRVState: String, CaseIterable {
    case high       // Excellent recovery
    case normal     // Baseline
    case low        // Stressed/working hard
    case suppressed // Deep recovery (sleep)
    
    var displayName: String {
        switch self {
        case .high: return "Recovered"
        case .normal: return "Normal"
        case .low: return "Working Hard"
        case .suppressed: return "Deep Rest"
        }
    }
    
    var emoji: String {
        switch self {
        case .high: return "🟢"
        case .normal: return "⚪"
        case .low: return "🟠"
        case .suppressed: return "🟣"
        }
    }
}

// MARK: - HRV Analysis Helpers

extension Array where Element == HRVSample {
    /// Calculate the average SDNN across samples
    var averageSDNN: Double? {
        guard !isEmpty else { return nil }
        return map(\.sdnn).reduce(0, +) / Double(count)
    }
    
    /// Get the most recent sample
    var latest: HRVSample? {
        self.max(by: { $0.timestamp < $1.timestamp })
    }
    
    /// Calculate HRV trend (positive = improving, negative = declining)
    var trend: Double? {
        guard count >= 2 else { return nil }
        let sorted = self.sorted { $0.timestamp < $1.timestamp }
        let first = sorted.prefix(count / 2).map(\.sdnn).reduce(0, +) / Double(count / 2)
        let second = sorted.suffix(count / 2).map(\.sdnn).reduce(0, +) / Double(count / 2)
        return (second - first) / first
    }
    
    /// Group samples by day
    func groupedByDay() -> [[HRVSample]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { sample in
            calendar.startOfDay(for: sample.timestamp)
        }
        return grouped.values.sorted { ($0.first?.timestamp ?? Date()) < ($1.first?.timestamp ?? Date()) }
    }
}
