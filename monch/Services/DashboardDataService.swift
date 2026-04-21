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
        
        // Zone 2 minutes (Granular sum from heart rate breakdown)
        let zone2Minutes = todayWorkouts.reduce(0) { total, workout in
            if let breakdown = workout.hrZoneBreakdown {
                return total + breakdown.zone2Minutes
            } else if workout.dominantHRZone == 2 {
                // Fallback for logs with dominant zone but no specific breakdown data
                return total + Int(workout.duration / 60)
            }
            return total
        }
        
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
            trends: [], // TODO: Week-over-week comparison requires previous week data tracking
            patterns: detectPatterns(meals: meals, insights: insights, workouts: workouts),
            totalInsights: weekInsights.count,
            spikeCount: spikeCount,
            spongeCount: spongeCount,
            debtCount: debtCount
        )
    }
    
    // MARK: - Month Metrics
    
    /// Compute monthly data with calendar heat map and streaks
    func computeMonthlyData(
        meals: [MealLog],
        insights: [InsightEvent],
        workouts: [WorkoutLog],
        sleepLogs: [SleepLog]
    ) -> MonthlySummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Build calendar dict for last 30 days
        var calendarData: [Date: MetabolicTier] = [:]
        
        for dayOffset in -30..<1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            
            // Check if there's any data for this day
            let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            guard !dayMeals.isEmpty else { continue }
            
            let dayInsights = insights.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let daySleep = sleepLogs.first { calendar.isDate($0.endTime, inSameDayAs: day) }
            
            let spikes = dayInsights.filter { $0.type == .sugarSpike }.count
            let debts = dayInsights.filter { $0.type == .digestionDebt }.count
            let sponges = dayInsights.filter { $0.type == .muscleSponge }.count
            let goodSleep = (daySleep?.totalDuration ?? 0) >= (7 * 60 * 60)
            
            let vibe = computeMetabolicVibe(spikes: spikes, debts: debts, sponges: sponges, goodSleep: goodSleep)
            calendarData[dayStart] = vibe
        }
        
        // Calculate streaks
        let streaks = calculateStreaks(meals: meals, insights: insights)
        
        // Get chronic insights (if any)
        let chronicInsights = insights.filter { $0.type == .deepSleepRobber || $0.type == .anxietyMimic }
        
        return MonthlySummary(
            calendar: calendarData,
            streaks: streaks,
            chronicInsights: Array(chronicInsights.prefix(3))
        )
    }
    
    // MARK: - Pattern Detection
    
    /// Detect behavioral patterns from recent data
    func detectPatterns(
        meals: [MealLog],
        insights: [InsightEvent],
        workouts: [WorkoutLog]
    ) -> [Pattern] {
        var patterns: [Pattern] = []
        let calendar = Calendar.current
        
        // Pattern: Weekend Late Meals
        let weekendLateMeals = meals.filter { meal in
            let weekday = calendar.component(.weekday, from: meal.timestamp)
            let hour = calendar.component(.hour, from: meal.timestamp)
            // Friday (6), Saturday (7), Sunday (1) after 9pm
            return (weekday == 6 || weekday == 7 || weekday == 1) && hour >= 21
        }
        
        if weekendLateMeals.count >= 2 {
            patterns.append(Pattern(
                name: "Weekend Wind-Down",
                icon: .asset("sleep_kawaii"),
                description: "Late meals detected on weekends",
                impact: "May affect sleep quality",
                suggestion: "Try closing the kitchen by 8pm on weekends",
                linkedEntryIDs: weekendLateMeals.map { $0.id },
                loopColor: .sleep
            ))
        }
        
        // Pattern: Post-Workout Refueling
        let recentWorkouts = workouts.prefix(10)
        let refueledWorkouts = recentWorkouts.filter { workout in
            // Check if there's a meal within 2 hours after workout
            let windowEnd = workout.endTime.addingTimeInterval(2 * 60 * 60)
            return meals.contains { meal in
                meal.timestamp > workout.endTime && meal.timestamp <= windowEnd
            }
        }
        
        if recentWorkouts.count >= 3 && !refueledWorkouts.isEmpty {
            let ratio = refueledWorkouts.count
            patterns.append(Pattern(
                name: "Post-Workout Refuel",
                icon: .asset("insight_recovery_kawaii"),
                description: "\(ratio)/\(recentWorkouts.count) workouts followed by nutrition",
                impact: ratio >= 3 ? "Good recovery potential" : "Could improve muscle recovery",
                suggestion: ratio >= 3 ? "Keep it up! Your muscles thank you." : "Try eating within 2h of exercise",
                linkedEntryIDs: [],
                loopColor: .recovery
            ))
        }
        
        // Pattern: Morning Sugar Spikes
        let morningSpikes = insights.filter { insight in
            let hour = calendar.component(.hour, from: insight.timestamp)
            return insight.type == .sugarSpike && hour < 12
        }
        
        if morningSpikes.count >= 3 {
            patterns.append(Pattern(
                name: "Morning Rollercoaster",
                icon: .asset("insight_spike_kawaii"),
                description: "Multiple sugar spikes before noon",
                impact: "Energy crashes later in the day",
                suggestion: "Add protein to breakfast to flatten the curve",
                linkedEntryIDs: morningSpikes.map { $0.associatedMealID }.compactMap { $0 },
                loopColor: .acute
            ))
        }
        
        return patterns
    }
    
    // MARK: - Streak Calculation
    
    /// Calculate active streaks
    func calculateStreaks(meals: [MealLog], insights: [InsightEvent]) -> [Streak] {
        var streaks: [Streak] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Streak: Kitchen Closed by 9pm
        var kitchenClosedCount = 0
        for dayOffset in (0..<30).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            
            let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            
            // Check if all meals were before 9pm
            let lateMeal = dayMeals.first { meal in
                calendar.component(.hour, from: meal.timestamp) >= 21
            }
            
            if lateMeal == nil && !dayMeals.isEmpty {
                kitchenClosedCount += 1
            } else if !dayMeals.isEmpty {
                break // Streak broken
            }
        }
        
        if kitchenClosedCount >= 2 {
            let hour = calendar.component(.hour, from: Date())
            let isAtRisk = hour >= 20 && hour < 21 // 8-9pm warning zone
            
            streaks.append(Streak(
                type: .kitchenClosed,
                count: kitchenClosedCount,
                personalBest: calculatePersonalBest(meals: meals, insights: insights, type: .kitchenClosed),
                isAtRisk: isAtRisk
            ))
        }
        
        // Streak: No Sugar Spikes
        var noSpikeCount = 0
        for dayOffset in (0..<30).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            
            let daySpikes = insights.filter {
                calendar.isDate($0.timestamp, inSameDayAs: day) && $0.type == .sugarSpike
            }
            
            let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            
            if daySpikes.isEmpty && !dayMeals.isEmpty {
                noSpikeCount += 1
            } else if !dayMeals.isEmpty {
                break
            }
        }
        
        if noSpikeCount >= 2 {
            streaks.append(Streak(
                type: .noSpikes,
                count: noSpikeCount,
                personalBest: calculatePersonalBest(meals: meals, insights: insights, type: .noSpikes),
                isAtRisk: false
            ))
        }
        
        return streaks
    }
    
    /// Check if a streak is at risk
    func checkStreakAtRisk(streak: Streak, currentTime: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        switch streak.type {
        case .kitchenClosed:
            return hour >= 20 && hour < 21 // Warning zone: 8-9pm
        default:
            return false
        }
    }
    
    // MARK: - Internal Helpers
    
    /// Calculate the historical record for a specific streak type
    private func calculatePersonalBest(meals: [MealLog], insights: [InsightEvent], type: StreakType) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find the earliest data point to know how far back to look
        let earliestMeal = meals.map { $0.timestamp }.min() ?? today
        let earliestInsight = insights.map { $0.timestamp }.min() ?? today
        let startDate = calendar.startOfDay(for: min(earliestMeal, earliestInsight))
        
        var maxStreak = 0
        var currentStreak = 0
        
        var currentDay = startDate
        while currentDay <= today {
            let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: currentDay) }
            
            var dayQualified = false
            if !dayMeals.isEmpty {
                switch type {
                case .kitchenClosed:
                    let lateMeal = dayMeals.first { calendar.component(.hour, from: $0.timestamp) >= 21 }
                    dayQualified = (lateMeal == nil)
                case .noSpikes:
                    let daySpikes = insights.filter { calendar.isDate($0.timestamp, inSameDayAs: currentDay) && $0.type == .sugarSpike }
                    dayQualified = daySpikes.isEmpty
                default:
                    dayQualified = false
                }
            }
            
            if dayQualified {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if !dayMeals.isEmpty {
                currentStreak = 0
            }
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        
        return maxStreak
    }
}
