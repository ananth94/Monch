//
//  DashboardDataService.swift
//  monch
//
//  Aggregation logic for Dashboard metrics, patterns, and streaks.
//

import Foundation
import SwiftData
import Combine

@MainActor
class DashboardDataService: ObservableObject {
    static let shared = DashboardDataService()
    
    private init() {}
    
    // MARK: - Today Metrics
    
    /// Compute today's summary from meals, insights, workouts, and sleep
    func computeTodayMetrics(
        meals: [MealLog],
        insights: [InsightEvent],
        workouts: [WorkoutLog],
        sleepLogs: [SleepLog]
    ) -> TodaySummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Filter to today's data
        let todayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        let todayInsights = insights.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        let todayWorkouts = workouts.filter { calendar.isDate($0.startTime, inSameDayAs: today) }
        
        // Sleep from last night (wake time = today)
        let lastSleep = sleepLogs.first { calendar.isDate($0.endTime, inSameDayAs: today) }
        
        // Aggregate macros
        let macros = aggregateMacros(from: todayMeals)
        let calories = todayMeals.reduce(0.0) { $0 + ($1.calories ?? 0) }
        
        // Count insight types
        let spikes = todayInsights.filter { $0.type == .sugarSpike }.count
        let debts = todayInsights.filter { $0.type == .digestionDebt }.count
        let sponges = todayInsights.filter { $0.type == .muscleSponge }.count
        
        // Sleep quality check
        let goodSleep = (lastSleep?.totalDuration ?? 0) >= (7 * 60 * 60) // 7+ hours
        
        // Compute vibe
        let vibe = computeMetabolicVibe(
            spikes: spikes,
            debts: debts,
            sponges: sponges,
            goodSleep: goodSleep
        )
        
        // Zone 2 minutes (HR Zone 2 workouts)
        let zone2Minutes = todayWorkouts
            .filter { $0.dominantHRZone == 2 }
            .reduce(0) { $0 + Int($1.duration / 60) }
        
        return TodaySummary(
            vibe: vibe,
            calories: calories,
            sleepDuration: lastSleep?.totalDuration,
            zone2Minutes: zone2Minutes,
            insights: todayInsights,
            macros: macros,
            mealCount: todayMeals.count
        )
    }
    
    // MARK: - Metabolic Vibe Algorithm
    
    /// Compute qualitative vibe tier — supportive, not punitive
    func computeMetabolicVibe(
        spikes: Int,
        debts: Int,
        sponges: Int,
        goodSleep: Bool
    ) -> MetabolicTier {
        let negatives = spikes + (debts * 2)
        let positives = sponges + (goodSleep ? 2 : 0)
        let net = positives - negatives
        
        switch net {
        case 3...: return .thriving
        case 1...2: return .balanced
        case 0: return .steady
        case -2...(-1): return .learning
        default: return .resetting
        }
    }
    
    // MARK: - Macro Aggregation
    
    func aggregateMacros(from meals: [MealLog]) -> MacroBreakdown {
        let carbs = meals.reduce(0.0) { $0 + ($1.carbs ?? 0) }
        let protein = meals.reduce(0.0) { $0 + ($1.protein ?? 0) }
        let fat = meals.reduce(0.0) { $0 + ($1.fat ?? 0) }
        return MacroBreakdown(carbs: carbs, protein: protein, fat: fat)
    }
    
    // MARK: - Week Metrics
    
    /// Compute weekly summary with daily breakdown
    func computeWeeklyTrends(
        meals: [MealLog],
        insights: [InsightEvent],
        workouts: [WorkoutLog],
        sleepLogs: [SleepLog]
    ) -> WeeklySummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get start of week (Monday)
        var weekStart = today
        while calendar.component(.weekday, from: weekStart) != 2 { // Monday = 2
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }
        
        // Build 7 daily summaries
        var dailyData: [DailySummary] = []
        for dayOffset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let dayInsights = insights.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let daySleep = sleepLogs.first { calendar.isDate($0.endTime, inSameDayAs: day) }
            
            let macros = aggregateMacros(from: dayMeals)
            let spikes = dayInsights.filter { $0.type == .sugarSpike }.count
            let debts = dayInsights.filter { $0.type == .digestionDebt }.count
            let sponges = dayInsights.filter { $0.type == .muscleSponge }.count
            let goodSleep = (daySleep?.totalDuration ?? 0) >= (7 * 60 * 60)
            
            let vibe = computeMetabolicVibe(spikes: spikes, debts: debts, sponges: sponges, goodSleep: goodSleep)
            
            dailyData.append(DailySummary(
                date: day,
                calories: dayMeals.reduce(0.0) { $0 + ($1.calories ?? 0) },
                vibe: vibe,
                macros: macros
            ))
        }
        
        // Count total insights
        let weekInsights = insights.filter { $0.timestamp >= weekStart && $0.timestamp <= today }
        let spikeCount = weekInsights.filter { $0.type == .sugarSpike }.count
        let spongeCount = weekInsights.filter { $0.type == .muscleSponge }.count
        let debtCount = weekInsights.filter { $0.type == .digestionDebt }.count
        
        return WeeklySummary(
            dailyData: dailyData,
            trends: [], // TODO: Compute in PR #2
            patterns: [], // TODO: Compute in PR #2
            totalInsights: weekInsights.count,
            spikeCount: spikeCount,
            spongeCount: spongeCount,
            debtCount: debtCount
        )
    }
    
    // MARK: - Streak Calculation (Preview for PR #2)
    
    /// Calculate active streaks
    func calculateStreaks(meals: [MealLog], insights: [InsightEvent]) -> [Streak] {
        // Placeholder — full implementation in PR #2
        return []
    }
    
    /// Check if a streak is at risk
    func checkStreakAtRisk(streak: Streak, currentTime: Date) -> Bool {
        // Placeholder — full implementation in PR #2
        return false
    }
}
