//
//  SleepLog.swift
//  monch
//
//  SwiftData model for sleep data synced from HealthKit.
//  Enables ambient insight computation (Digestion Debt, Deep Sleep Robber).
//

import Foundation
import SwiftData

/// Represents a single sleep session synced from HealthKit
@Model
final class SleepLog {
    /// Unique identifier (matches HealthKit sample UUID when possible)
    var id: UUID
    
    /// When the user went to bed
    var startTime: Date
    
    /// When the user woke up
    var endTime: Date
    
    /// Total sleep duration in seconds
    var totalDuration: TimeInterval
    
    // MARK: - Sleep Stage Breakdown (pre-computed from HealthKit samples)
    
    /// Deep sleep duration in minutes
    var deepSleepMinutes: Int
    
    /// REM sleep duration in minutes
    var remSleepMinutes: Int
    
    /// Light/Core sleep duration in minutes
    var lightSleepMinutes: Int
    
    /// Time awake during sleep session in minutes
    var awakeMinutes: Int
    
    // MARK: - Hypnogram Data (for timeline visualization)
    
    /// Ordered list of sleep stage segments for hypnogram chart
    /// Stored as JSON-encoded array
    var stageSegmentsData: Data?
    
    // MARK: - Computed / User-Annotated
    
    /// Sleep quality score (0.0 - 1.0), computed or user-adjusted
    var qualityScore: Double?
    
    /// Optional user notes about sleep
    var notes: String?
    
    // MARK: - Sync Metadata
    
    /// When this record was last synced from HealthKit
    var healthKitSyncDate: Date
    
    /// HealthKit source bundle identifier (e.g., "com.apple.health")
    var sourceBundleId: String?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        deepSleepMinutes: Int = 0,
        remSleepMinutes: Int = 0,
        lightSleepMinutes: Int = 0,
        awakeMinutes: Int = 0,
        qualityScore: Double? = nil,
        notes: String? = nil,
        sourceBundleId: String? = nil
    ) {
        precondition(endTime >= startTime, "Sleep end time must be after or equal to start time")
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.totalDuration = endTime.timeIntervalSince(startTime)
        self.deepSleepMinutes = deepSleepMinutes
        self.remSleepMinutes = remSleepMinutes
        self.lightSleepMinutes = lightSleepMinutes
        self.awakeMinutes = awakeMinutes
        self.qualityScore = qualityScore
        self.notes = notes
        self.healthKitSyncDate = Date()
        self.sourceBundleId = sourceBundleId
    }
}

// MARK: - Sleep Segment (for Hypnogram)

/// Represents a single segment in the sleep hypnogram
struct SleepSegment: Codable, Identifiable {
    var id: UUID = UUID()
    let startTime: Date
    let endTime: Date
    let stage: SleepStage
    
    /// Duration in minutes
    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
}

// Note: SleepStage enum is defined in HealthKitDataProvider.swift

// MARK: - Computed Properties

extension SleepLog {
    /// Total time actually asleep (excluding awake periods)
    var actualSleepMinutes: Int {
        deepSleepMinutes + remSleepMinutes + lightSleepMinutes
    }
    
    /// Sleep efficiency: actual sleep / total time in bed
    var sleepEfficiency: Double {
        let totalMinutes = totalDuration / 60
        guard totalMinutes > 0 else { return 0 }
        return Double(actualSleepMinutes) / totalMinutes
    }
    
    /// Deep sleep percentage (important for insight detection)
    var deepSleepPercentage: Double {
        guard actualSleepMinutes > 0 else { return 0 }
        return Double(deepSleepMinutes) / Double(actualSleepMinutes)
    }
    
    /// REM sleep percentage
    var remSleepPercentage: Double {
        guard actualSleepMinutes > 0 else { return 0 }
        return Double(remSleepMinutes) / Double(actualSleepMinutes)
    }
    
    /// Formatted duration string (e.g., "7h 32m")
    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    /// Decode stage segments from stored JSON data
    var stageSegments: [SleepSegment] {
        guard let data = stageSegmentsData else { return [] }
        return (try? JSONDecoder().decode([SleepSegment].self, from: data)) ?? []
    }
    
    /// Encode and store stage segments as JSON
    func setStageSegments(_ segments: [SleepSegment]) {
        stageSegmentsData = try? JSONEncoder().encode(segments)
    }
    
    /// Computed quality score if not user-provided
    /// Based on: deep sleep %, sleep efficiency, total duration
    var computedQualityScore: Double {
        if let manual = qualityScore { return manual }
        
        var score = 0.0
        
        // Deep sleep: ideal is 15-25%
        let deepPct = deepSleepPercentage
        if deepPct >= 0.15 && deepPct <= 0.25 {
            score += 0.35
        } else if deepPct >= 0.10 {
            score += 0.20
        }
        
        // Sleep efficiency: ideal is > 85%
        if sleepEfficiency >= 0.85 {
            score += 0.35
        } else if sleepEfficiency >= 0.75 {
            score += 0.20
        }
        
        // Duration: ideal is 7-9 hours
        let hours = totalDuration / 3600
        if hours >= 7 && hours <= 9 {
            score += 0.30
        } else if hours >= 6 {
            score += 0.15
        }
        
        return min(score, 1.0)
    }
}
