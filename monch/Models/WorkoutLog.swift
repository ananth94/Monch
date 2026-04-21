//
//  WorkoutLog.swift
//  monch
//
//  SwiftData model for workout data synced from HealthKit.
//  Enables ambient insight computation (Muscle Sponge, Good Spike Suppression).
//

import Foundation
import SwiftData

/// Represents a single workout session synced from HealthKit
@Model
final class WorkoutLog {
    /// Unique identifier (matches HealthKit workout UUID when possible)
    var id: UUID
    
    /// When the workout started
    var startTime: Date
    
    /// When the workout ended
    var endTime: Date
    
    /// Total workout duration in seconds
    var duration: TimeInterval
    
    // MARK: - Activity Type
    
    /// Raw value of HKWorkoutActivityType for persistence
    var activityTypeRaw: UInt
    
    /// Human-readable activity name (e.g., "Running", "Weight Training")
    var activityName: String
    
    // MARK: - Metrics (populated based on workout type)
    
    /// Distance in meters (cardio workouts)
    var distanceMeters: Double?
    
    /// Active calories burned
    var activeCalories: Double?
    
    /// Total calories burned (active + basal during workout)
    var totalCalories: Double?
    
    /// Average heart rate during workout (bpm)
    var avgHeartRate: Double?
    
    /// Maximum heart rate during workout (bpm)
    var maxHeartRate: Double?
    
    // MARK: - Derived Values
    
    /// Pre-computed anabolic window end time (endTime + 2 hours)
    var anabolicWindowEnd: Date
    
    /// Dominant HR zone during workout (1-5)
    var dominantHRZone: Int?
    
    // MARK: - HR Zone Breakdown (stored as JSON)
    
    /// Time spent in each HR zone (zone1-5) in minutes
    var hrZoneBreakdownData: Data?
    
    // MARK: - Sync Metadata
    
    /// When this record was last synced from HealthKit
    var healthKitSyncDate: Date
    
    /// HealthKit source bundle identifier
    var sourceBundleId: String?
    
    /// Whether this workout was manually entered (vs synced from HealthKit)
    var isManualEntry: Bool
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        duration: TimeInterval? = nil,
        activityTypeRaw: UInt,
        activityName: String,
        distanceMeters: Double? = nil,
        activeCalories: Double? = nil,
        totalCalories: Double? = nil,
        avgHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        dominantHRZone: Int? = nil,
        sourceBundleId: String? = nil,
        isManualEntry: Bool = false
    ) {
        precondition(endTime >= startTime, "Workout end time must be after or equal to start time")
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration ?? endTime.timeIntervalSince(startTime)
        self.activityTypeRaw = activityTypeRaw
        self.activityName = activityName
        self.distanceMeters = distanceMeters
        self.activeCalories = activeCalories
        self.totalCalories = totalCalories
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.dominantHRZone = dominantHRZone
        self.anabolicWindowEnd = endTime.addingTimeInterval(2 * 60 * 60) // +2 hours
        self.healthKitSyncDate = Date()
        self.sourceBundleId = sourceBundleId
        self.isManualEntry = isManualEntry
    }
}

// MARK: - Exercise Category

/// High-level exercise categories for adaptive UI
enum ExerciseCategory: String, CaseIterable {
    case cardio      // Running, Cycling, Swimming, Rowing, etc.
    case strength    // Weight Training, Functional Strength
    case hiit        // High Intensity Interval Training, CrossTraining
    case flexibility // Yoga, Pilates, Stretching
    case other       // Fallback
    
    /// Display name
    var displayName: String {
        switch self {
        case .cardio: return "Cardio"
        case .strength: return "Strength"
        case .hiit: return "HIIT"
        case .flexibility: return "Flexibility"
        case .other: return "Workout"
        }
    }
    
    /// Icon for display
    var icon: String {
        switch self {
        case .cardio: return "🏃"
        case .strength: return "🏋️"
        case .hiit: return "⚡"
        case .flexibility: return "🧘"
        case .other: return "💪"
        }
    }

    var iconToken: MonchIconToken {
        switch self {
        case .strength:
            return .asset("insight_recovery_kawaii")
        default:
            return .asset("workout_kawaii")
        }
    }
    
    /// Initialize from HKWorkoutActivityType raw value
    init(fromActivityTypeRaw raw: UInt) {
        // Map common HealthKit activity types to categories
        // These raw values correspond to HKWorkoutActivityType
        switch raw {
        case 37, 13, 46, 35, 52:  // running, cycling, swimming, rowing, walking
            self = .cardio
        case 50, 20:              // traditionalStrengthTraining, functionalStrengthTraining
            self = .strength
        case 63, 12:              // highIntensityIntervalTraining, crossTraining
            self = .hiit
        case 33, 58:              // yoga, pilates
            self = .flexibility
        default:
            self = .other
        }
    }
}

// MARK: - HR Zone Breakdown

/// Heart rate zone distribution for a workout
struct HRZoneBreakdown: Codable, Sendable {
    /// Time in Zone 1 (50-60% max HR) in minutes
    var zone1Minutes: Int = 0
    /// Time in Zone 2 (60-70% max HR) in minutes
    var zone2Minutes: Int = 0
    /// Time in Zone 3 (70-80% max HR) in minutes
    var zone3Minutes: Int = 0
    /// Time in Zone 4 (80-90% max HR) in minutes
    var zone4Minutes: Int = 0
    /// Time in Zone 5 (90-100% max HR) in minutes
    var zone5Minutes: Int = 0
    
    /// Total time covered by zone data
    var totalMinutes: Int {
        zone1Minutes + zone2Minutes + zone3Minutes + zone4Minutes + zone5Minutes
    }
    
    /// Get percentage for a given zone
    func percentage(for zone: Int) -> Double {
        guard totalMinutes > 0 else { return 0 }
        let minutes: Int
        switch zone {
        case 1: minutes = zone1Minutes
        case 2: minutes = zone2Minutes
        case 3: minutes = zone3Minutes
        case 4: minutes = zone4Minutes
        case 5: minutes = zone5Minutes
        default: minutes = 0
        }
        return Double(minutes) / Double(totalMinutes)
    }
    
    /// Dominant zone (most time spent)
    var dominantZone: Int {
        let zones = [zone1Minutes, zone2Minutes, zone3Minutes, zone4Minutes, zone5Minutes]
        guard let maxIndex = zones.indices.max(by: { zones[$0] < zones[$1] }) else { return 2 }
        return maxIndex + 1
    }
}

// MARK: - Computed Properties

extension WorkoutLog {
    /// Exercise category for adaptive UI
    var category: ExerciseCategory {
        ExerciseCategory(fromActivityTypeRaw: activityTypeRaw)
    }
    
    /// Check if currently in anabolic window
    var isInAnabolicWindow: Bool {
        Date() < anabolicWindowEnd
    }
    
    /// Time remaining in anabolic window (if active)
    var anabolicWindowRemaining: TimeInterval? {
        guard isInAnabolicWindow else { return nil }
        return anabolicWindowEnd.timeIntervalSince(Date())
    }
    
    /// Formatted anabolic window remaining (e.g., "1h 32m left")
    var formattedAnabolicWindowRemaining: String? {
        guard let remaining = anabolicWindowRemaining else { return nil }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        }
        return "\(minutes)m left"
    }
    
    /// Formatted duration string (e.g., "35 min")
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) min"
    }
    
    /// Formatted distance (e.g., "5.2 km")
    var formattedDistance: String? {
        guard let meters = distanceMeters, meters > 0 else { return nil }
        let km = meters / 1000
        if km >= 1 {
            return String(format: "%.1f km", km)
        }
        return "\(Int(meters)) m"
    }
    
    /// Calculated pace (for cardio) in min/km
    var pacePerKm: TimeInterval? {
        guard let meters = distanceMeters, meters > 0 else { return nil }
        let km = meters / 1000
        return duration / km
    }
    
    /// Formatted pace string (e.g., "6:44 /km")
    var formattedPace: String? {
        guard let pace = pacePerKm else { return nil }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    /// Decode HR zone breakdown from stored JSON
    @MainActor var hrZoneBreakdown: HRZoneBreakdown? {
        guard let data = hrZoneBreakdownData else { return nil }
        return try? JSONDecoder().decode(HRZoneBreakdown.self, from: data)
    }
    
    /// Encode and store HR zone breakdown as JSON
    @MainActor func setHRZoneBreakdown(_ breakdown: HRZoneBreakdown) {
        hrZoneBreakdownData = try? JSONEncoder().encode(breakdown)
        dominantHRZone = breakdown.dominantZone
    }
    
    /// Context tag for display (e.g., "Zone 2", "Strength")
    var contextTag: String {
        if let zone = dominantHRZone {
            return "💪 Zone \(zone)"
        }
        return category.displayName
    }
    
    /// Whether this workout meets the threshold for anabolic window activation
    /// (300+ kcal OR reached Zone 3+)
    var triggersAnabolicWindow: Bool {
        if let cal = activeCalories, cal >= 300 {
            return true
        }
        if let zone = dominantHRZone, zone >= 3 {
            return true
        }
        // Default: any workout with HR data triggers it
        return avgHeartRate != nil
    }
}
