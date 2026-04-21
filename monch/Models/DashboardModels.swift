//
//  DashboardModels.swift
//  monch
//
//  Data models for Dashboard aggregation and display.
//

import Foundation
import SwiftUI

// MARK: - Metabolic Vibe (Qualitative Score)

/// 5-tier qualitative metabolic status — supportive, not punitive
enum MetabolicTier: String, CaseIterable, Identifiable {
    case thriving   // 🌟 Best day
    case balanced   // 💚 Good day
    case steady     // 😊 Neutral
    case learning   // 🌤️ Room to grow
    case resetting  // 🌱 Fresh start tomorrow
    
    var id: String { rawValue }
    
    var symbolName: String {
        switch self {
        case .thriving: return "sparkles"
        case .balanced: return "leaf.fill"
        case .steady: return "circle.fill"
        case .learning: return "cloud.sun.fill"
        case .resetting: return "arrow.clockwise"
        }
    }
    
    var name: String {
        switch self {
        case .thriving: return "Thriving"
        case .balanced: return "Balanced"
        case .steady: return "Steady"
        case .learning: return "Learning"
        case .resetting: return "Resetting"
        }
    }
    
    var encouragingCopy: String {
        switch self {
        case .thriving: return "Nailed it. Your body thanks you."
        case .balanced: return "You're doing great!"
        case .steady: return "Steady as she goes."
        case .learning: return "Every day is practice."
        case .resetting: return "Tomorrow is fresh."
        }
    }
    
    var color: GradientMood {
        switch self {
        case .thriving, .balanced: return .recovery // Sage
        case .steady: return .neutral
        case .learning: return .acute // Coral
        case .resetting: return .sleep // Periwinkle
        }
    }
}

// MARK: - Macro Breakdown

struct MacroBreakdown: Equatable {
    let carbs: Double // grams
    let protein: Double // grams
    let fat: Double // grams
    
    var totalCalories: Double {
        (carbs * 4) + (protein * 4) + (fat * 9)
    }
    
    var carbsPercent: Double {
        guard totalCalories > 0 else { return 0 }
        return (carbs * 4) / totalCalories
    }
    
    var proteinPercent: Double {
        guard totalCalories > 0 else { return 0 }
        return (protein * 4) / totalCalories
    }
    
    var fatPercent: Double {
        guard totalCalories > 0 else { return 0 }
        return (fat * 9) / totalCalories
    }
    
    static let empty = MacroBreakdown(carbs: 0, protein: 0, fat: 0)
}

// MARK: - Today Summary

struct TodaySummary {
    let vibe: MetabolicTier
    let calories: Double
    let sleepDuration: TimeInterval?
    let zone2Minutes: Int
    let insights: [InsightEvent]
    let macros: MacroBreakdown
    let mealCount: Int
    
    var hasData: Bool {
        mealCount > 0 || sleepDuration != nil || !insights.isEmpty
    }
    
    static let empty = TodaySummary(
        vibe: .steady,
        calories: 0,
        sleepDuration: nil,
        zone2Minutes: 0,
        insights: [],
        macros: .empty,
        mealCount: 0
    )
}

// MARK: - Daily Summary (for Week View)

struct DailySummary: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let vibe: MetabolicTier
    let macros: MacroBreakdown
    let mealCount: Int
    let insightCount: Int
    let workoutCount: Int
    let hasSleepData: Bool
    
    var hasNutritionData: Bool {
        calories > 0 || macros.totalCalories > 0
    }
    
    var signalCount: Int {
        mealCount + insightCount + workoutCount + (hasSleepData ? 1 : 0)
    }
    
    var hasAnySignal: Bool {
        signalCount > 0
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var shortDayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Weekly Summary

struct WeeklySummary {
    let dailyData: [DailySummary]
    let trends: [Trend]
    let patterns: [Pattern]
    let totalInsights: Int
    let spikeCount: Int
    let spongeCount: Int
    let debtCount: Int
}

// MARK: - Trend (Week-over-Week)

struct Trend: Identifiable {
    let id = UUID()
    let metric: String
    let delta: Double // Positive = improvement
    let deltaDisplay: String
    let commentary: String
    
    var isImprovement: Bool { delta >= 0 }
    
    var arrow: String {
        delta > 0 ? "↑" : (delta < 0 ? "↓" : "→")
    }
}

// MARK: - Pattern

struct Pattern: Identifiable {
    let id = UUID()
    let name: String
    let icon: MonchIconToken
    let description: String
    let impact: String
    let suggestion: String
    let linkedEntryIDs: [UUID]
    let loopColor: GradientMood
}

// MARK: - Monthly Summary

struct MonthlySummary {
    let calendar: [Date: MetabolicTier]
    let streaks: [Streak]
    let chronicInsights: [InsightEvent]
    
    var daysWithData: Int { calendar.count }
}

// MARK: - Streak

enum StreakType: String, CaseIterable {
    case kitchenClosed = "Kitchen Closed by 9pm"
    case postWorkoutRefuel = "Post-Workout Refueling"
    case noSpikes = "Spike-Free Days"
    case consistentLogging = "Consistent Logging"
    
    var iconToken: MonchIconToken {
        switch self {
        case .kitchenClosed: return .asset("sleep_kawaii")
        case .postWorkoutRefuel: return .asset("insight_recovery_kawaii")
        case .noSpikes: return .asset("insight_spike_kawaii")
        case .consistentLogging: return .symbol("checklist")
        }
    }
}

struct Streak: Identifiable {
    let id = UUID()
    let type: StreakType
    let count: Int
    let personalBest: Int
    let isAtRisk: Bool
    
    var progressTowardsBest: Double {
        guard personalBest > 0 else { return 0 }
        return min(1.0, Double(count) / Double(personalBest))
    }
}
