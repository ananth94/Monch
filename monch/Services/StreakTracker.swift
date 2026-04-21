//
//  StreakTracker.swift
//  monch
//
//  Service to calculate and persist streak data for logging consistency.
//  Tracks consecutive days with at least one meaningful logging signal.
//

import Foundation
import SwiftData
import Combine

/// Milestone days for streak celebrations
enum StreakMilestone: Int, CaseIterable {
    case week = 7
    case twoWeeks = 14
    case month = 30
    case hundredDays = 100
    
    var celebrationMessage: String {
        switch self {
        case .week: return "One week strong! 🎉"
        case .twoWeeks: return "Two weeks of consistency! 💪"
        case .month: return "A full month! You're unstoppable! 🌟"
        case .hundredDays: return "100 days! Legendary status! 🏆"
        }
    }
    
    var mascotMessage: String {
        switch self {
        case .week: return "Monch is so proud of you!"
        case .twoWeeks: return "You and Monch make a great team!"
        case .month: return "Monch has never been happier!"
        case .hundredDays: return "You're Monch's favorite human!"
        }
    }
}

/// Observable service for tracking logging streaks
@MainActor
class StreakTracker: ObservableObject {
    static let shared = StreakTracker()
    
    // MARK: - Published Properties
    
    /// Current consecutive day streak
    @Published private(set) var currentStreak: Int = 0
    
    /// Personal best streak
    @Published private(set) var longestStreak: Int = 0
    
    /// Most recent milestone achieved (nil if none pending celebration)
    @Published var pendingMilestone: StreakMilestone?
    
    /// Whether streak was broken since last check
    @Published private(set) var didBreakStreak: Bool = false
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    
    private let currentStreakKey = "monch.streak.current"
    private let longestStreakKey = "monch.streak.longest"
    private let lastLogDateKey = "monch.streak.lastLogDate"
    private let lastCelebratedMilestoneKey = "monch.streak.lastCelebratedMilestone"
    
    // MARK: - Initialization
    
    private init() {
        loadPersistedData()
    }
    
    // MARK: - Public Methods
    
    /// Calculate and update streak based on meaningful logging signals.
    func updateStreak(
        meals: [MealLog],
        insights: [InsightEvent] = [],
        workouts: [WorkoutLog] = [],
        sleepLogs: [SleepLog] = []
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let mealDates = meals.map { calendar.startOfDay(for: $0.timestamp) }
        let insightDates = insights.map { calendar.startOfDay(for: $0.timestamp) }
        let workoutDates = workouts.map { calendar.startOfDay(for: $0.startTime) }
        let sleepDates = sleepLogs.map { calendar.startOfDay(for: $0.endTime) }
        
        // Get unique dates with any logging signal, sorted descending.
        let logDates = Set(mealDates + insightDates + workoutDates + sleepDates)
            .sorted(by: >)
        
        guard let mostRecentLogDate = logDates.first else {
            // No logs at all
            handleNoLogs()
            return
        }
        
        // Check if there's a log today or yesterday (streak is still active)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if mostRecentLogDate < yesterday {
            // Streak is broken - gap of more than 1 day
            handleStreakBreak()
            return
        }
        
        // Count consecutive days going back from most recent
        var streak = 0
        var checkDate = mostRecentLogDate
        
        while logDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }
        
        // Update streak values
        let previousStreak = currentStreak
        currentStreak = streak
        
        if streak > longestStreak {
            longestStreak = streak
        }
        
        // Check for milestone achievement
        checkForMilestone(previousStreak: previousStreak, newStreak: streak)
        
        // Clear break flag if streak is active
        didBreakStreak = false
        
        // Persist
        persist()
    }
    
    /// Acknowledge and dismiss the pending milestone celebration
    func dismissMilestone() {
        if let milestone = pendingMilestone {
            userDefaults.set(milestone.rawValue, forKey: lastCelebratedMilestoneKey)
        }
        pendingMilestone = nil
    }
    
    /// Reset streak (for testing or user request)
    func resetStreak() {
        currentStreak = 0
        didBreakStreak = false
        pendingMilestone = nil
        userDefaults.removeObject(forKey: currentStreakKey)
        userDefaults.removeObject(forKey: lastLogDateKey)
        userDefaults.removeObject(forKey: lastCelebratedMilestoneKey)
    }
    
    // MARK: - Private Methods
    
    private func loadPersistedData() {
        currentStreak = userDefaults.integer(forKey: currentStreakKey)
        longestStreak = userDefaults.integer(forKey: longestStreakKey)
    }
    
    private func persist() {
        userDefaults.set(currentStreak, forKey: currentStreakKey)
        userDefaults.set(longestStreak, forKey: longestStreakKey)
        userDefaults.set(Date(), forKey: lastLogDateKey)
    }
    
    private func handleNoLogs() {
        if currentStreak > 0 {
            handleStreakBreak()
        }
    }
    
    private func handleStreakBreak() {
        didBreakStreak = currentStreak > 0
        currentStreak = 0
        persist()
    }
    
    private func checkForMilestone(previousStreak: Int, newStreak: Int) {
        let lastCelebrated = userDefaults.integer(forKey: lastCelebratedMilestoneKey)
        
        // Find milestones crossed between previous and new streak
        for milestone in StreakMilestone.allCases {
            let milestoneDay = milestone.rawValue
            
            // Check if we just crossed this milestone
            if previousStreak < milestoneDay && newStreak >= milestoneDay {
                // Only celebrate if we haven't celebrated this milestone before
                if lastCelebrated < milestoneDay {
                    pendingMilestone = milestone
                    return
                }
            }
        }
    }
}

// MARK: - Preview Helpers

extension StreakTracker {
    /// Create a mock tracker for previews
    static func preview(streak: Int = 7, milestone: StreakMilestone? = nil) -> StreakTracker {
        let tracker = StreakTracker.shared
        tracker.currentStreak = streak
        tracker.longestStreak = max(streak, tracker.longestStreak)
        tracker.pendingMilestone = milestone
        return tracker
    }
}
