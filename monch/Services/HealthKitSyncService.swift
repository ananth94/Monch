//
//  HealthKitSyncService.swift
//  monch
//
//  Background sync service that imports Sleep and Workout data from HealthKit
//  into SwiftData models for ambient insight computation.
//

import Foundation
import HealthKit
import SwiftData
import Combine

/// Service responsible for syncing HealthKit data to local SwiftData storage
@MainActor
class HealthKitSyncService: ObservableObject {
    static let shared = HealthKitSyncService()
    
    private let healthStore = HKHealthStore()
    
    @Published var lastSleepSyncDate: Date?
    @Published var lastWorkoutSyncDate: Date?
    @Published var isSyncing = false
    @Published var syncError: Error?
    
    private init() {}
    
    // MARK: - Public Sync Methods
    
    /// Sync all health data (call on app launch and periodically)
    func syncAll(modelContext: ModelContext) async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil
        
        do {
            async let sleepSync: () = syncSleepData(modelContext: modelContext)
            async let workoutSync: () = syncWorkoutData(modelContext: modelContext)
            
            try await sleepSync
            try await workoutSync
            
        } catch {
            syncError = error
            print("HealthKitSyncService: Sync failed - \(error)")
        }
        
        isSyncing = false
    }
    
    /// Sync only sleep data (last 7 days)
    func syncSleepData(modelContext: ModelContext) async throws {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        // 1. Fetch authoritative data from HealthKit
        let samples = try await fetchSleepSamples(from: sevenDaysAgo, to: now)
        let sleepSessions = groupSleepSamplesIntoSessions(samples)
        
        // 2. Fetch existing local data for the same period
        let predicate = #Predicate<SleepLog> { log in
            log.startTime >= sevenDaysAgo
        }
        let descriptor = FetchDescriptor<SleepLog>(predicate: predicate)
        let existingLogs = try modelContext.fetch(descriptor)
        
        var touchedLogIds = Set<UUID>()
        
        // 3. Match and Update/Insert
        for session in sleepSessions {
            // Find match by start time proximity (standard sync practice)
            let match = existingLogs.first { log in
                abs(log.startTime.timeIntervalSince(session.startTime)) < 1800 // 30 mins tolerance
            }
            
            if let log = match {
                updateSleepLog(log, from: session)
                touchedLogIds.insert(log.id)
            } else {
                let newLog = createSleepLog(from: session)
                modelContext.insert(newLog)
                touchedLogIds.insert(newLog.id)
            }
        }
        
        // 4. Prune obsolete logs (e.g. phantom fragments from previous bugs, or deleted sessions)
        for log in existingLogs {
            if !touchedLogIds.contains(log.id) {
                modelContext.delete(log)
            }
        }
        
        try modelContext.save()
        lastSleepSyncDate = now
    }
    
    /// Sync only workout data (last 7 days)
    func syncWorkoutData(modelContext: ModelContext) async throws {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let workouts = try await fetchWorkouts(from: sevenDaysAgo, to: now)
        
        for workout in workouts {
            if let workoutLog = await upsertWorkoutLog(workout, modelContext: modelContext) {
                await InsightEngine.shared.analyzeWorkout(workoutLog, in: modelContext)
            }
        }
        
        lastWorkoutSyncDate = now
    }
    
    // MARK: - HealthKit Fetching
    
    private func fetchSleepSamples(from startDate: Date, to endDate: Date) async throws -> [HKCategorySample] {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Sleep Processing
    
    /// Group individual sleep samples into coherent sleep sessions
    private func groupSleepSamplesIntoSessions(_ samples: [HKCategorySample]) -> [SleepSession] {
        guard !samples.isEmpty else { return [] }
        
        // Group samples by night (samples ending before noon belong to previous night)
        var sessionsByNight: [Date: [HKCategorySample]] = [:]
        let calendar = Calendar.current
        
        for sample in samples {
            // Use the END time (wake time) to determine which night this belongs to
            // If you wake up before noon, it's part of the previous night's sleep
            let wakeHour = calendar.component(.hour, from: sample.endDate)
            var sessionDate = calendar.startOfDay(for: sample.endDate)
            
            // If waking up before noon, attribute to previous night
            if wakeHour < 12 {
                sessionDate = calendar.date(byAdding: .day, value: -1, to: sessionDate) ?? sessionDate
            }
            
            sessionsByNight[sessionDate, default: []].append(sample)
        }
        
        // Convert grouped samples into sessions
        return sessionsByNight.compactMap { (nightDate, nightSamples) -> SleepSession? in
            guard let earliest = nightSamples.min(by: { $0.startDate < $1.startDate }),
                  let latest = nightSamples.max(by: { $0.endDate < $1.endDate }) else {
                return nil
            }
            
            return SleepSession(
                nightDate: nightDate,
                startTime: earliest.startDate,
                endTime: latest.endDate,
                samples: nightSamples
            )
        }.sorted { $0.startTime > $1.startTime }
    }
    
    private func createSleepLog(from session: SleepSession) -> SleepLog {
        let breakdown = calculateSleepStageBreakdown(session.samples)
        let segments = createSleepSegments(from: session.samples)
        
        let log = SleepLog(
            startTime: session.startTime,
            endTime: session.endTime,
            deepSleepMinutes: breakdown.deep,
            remSleepMinutes: breakdown.rem,
            lightSleepMinutes: breakdown.light,
            awakeMinutes: breakdown.awake,
            sourceBundleId: session.samples.first?.sourceRevision.source.bundleIdentifier
        )
        
        log.setStageSegments(segments)
        return log
    }
    
    private func updateSleepLog(_ log: SleepLog, from session: SleepSession) {
        let breakdown = calculateSleepStageBreakdown(session.samples)
        let segments = createSleepSegments(from: session.samples)
        
        log.startTime = session.startTime
        log.endTime = session.endTime
        log.totalDuration = session.endTime.timeIntervalSince(session.startTime)
        log.deepSleepMinutes = breakdown.deep
        log.remSleepMinutes = breakdown.rem
        log.lightSleepMinutes = breakdown.light
        log.awakeMinutes = breakdown.awake
        log.healthKitSyncDate = Date()
        log.setStageSegments(segments)
    }
    
    private func calculateSleepStageBreakdown(_ samples: [HKCategorySample]) -> (deep: Int, rem: Int, light: Int, awake: Int) {
        var deep = 0, rem = 0, light = 0, awake = 0
        
        for sample in samples {
            let minutes = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
            
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deep += minutes
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                rem += minutes
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                light += minutes
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += minutes
            default:
                // asleepUnspecified or inBed - count as light
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    light += minutes
                }
            }
        }
        
        return (deep, rem, light, awake)
    }
    
    private func createSleepSegments(from samples: [HKCategorySample]) -> [SleepSegment] {
        return samples.compactMap { sample -> SleepSegment? in
            let stage: SleepStage
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                stage = .deep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                stage = .rem
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                stage = .light
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                stage = .awake
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                stage = .inBed
            default:
                return nil
            }
            
            return SleepSegment(
                startTime: sample.startDate,
                endTime: sample.endDate,
                stage: stage
            )
        }.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - Workout Processing
    
    /// Upsert a workout into SwiftData
    private func upsertWorkoutLog(_ workout: HKWorkout, modelContext: ModelContext) async -> WorkoutLog? {
        let workoutStart = workout.startDate
        let predicate = #Predicate<WorkoutLog> { log in
            log.startTime == workoutStart
        }
        
        let descriptor = FetchDescriptor<WorkoutLog>(predicate: predicate)
        
        do {
            let existing = try modelContext.fetch(descriptor)
            
            if let workoutLog = existing.first {
                // Update existing
                updateWorkoutLog(workoutLog, from: workout)
                try modelContext.save()
                return workoutLog
            } else {
                // Insert new
                let workoutLog = createWorkoutLog(from: workout)
                modelContext.insert(workoutLog)
                try modelContext.save()
                return workoutLog
            }
        } catch {
            print("HealthKitSyncService: Failed to upsert WorkoutLog - \(error)")
            return nil
        }
    }
    
    private func createWorkoutLog(from workout: HKWorkout) -> WorkoutLog {
        let log = WorkoutLog(
            id: workout.uuid,
            startTime: workout.startDate,
            endTime: workout.endDate,
            duration: workout.duration,
            activityTypeRaw: workout.workoutActivityType.rawValue,
            activityName: workout.workoutActivityType.displayName,
            distanceMeters: extractDistance(from: workout),
            activeCalories: extractActiveCalories(from: workout),
            totalCalories: extractTotalCalories(from: workout),
            avgHeartRate: nil, // Would need separate query
            maxHeartRate: nil,
            sourceBundleId: workout.sourceRevision.source.bundleIdentifier
        )
        
        return log
    }
    
    private func updateWorkoutLog(_ log: WorkoutLog, from workout: HKWorkout) {
        log.endTime = workout.endDate
        log.duration = workout.duration
        log.anabolicWindowEnd = workout.endDate.addingTimeInterval(2 * 60 * 60)
        log.distanceMeters = extractDistance(from: workout)
        log.activeCalories = extractActiveCalories(from: workout)
        log.totalCalories = extractTotalCalories(from: workout)
        log.healthKitSyncDate = Date()
    }
    
    private func extractDistance(from workout: HKWorkout) -> Double? {
        if let distance = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity() {
            return distance.doubleValue(for: .meter())
        }
        if let distance = workout.statistics(for: HKQuantityType(.distanceCycling))?.sumQuantity() {
            return distance.doubleValue(for: .meter())
        }
        if let distance = workout.statistics(for: HKQuantityType(.distanceSwimming))?.sumQuantity() {
            return distance.doubleValue(for: .meter())
        }
        return nil
    }
    
    private func extractActiveCalories(from workout: HKWorkout) -> Double? {
        workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
    }
    
    private func extractTotalCalories(from workout: HKWorkout) -> Double? {
        if let active = extractActiveCalories(from: workout),
           let basal = workout.statistics(for: HKQuantityType(.basalEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
            return active + basal
        }
        return extractActiveCalories(from: workout)
    }
}

// MARK: - Supporting Types

/// Intermediate representation of a sleep session (one night)
private struct SleepSession {
    let nightDate: Date
    let startTime: Date
    let endTime: Date
    let samples: [HKCategorySample]
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .traditionalStrengthTraining: return "Weight Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .coreTraining: return "Core Training"
        case .mixedCardio: return "Mixed Cardio"
        default: return "Workout"
        }
    }
}
