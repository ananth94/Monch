//
//  WeekView.swift
//  monch
//
//  Weekly trends: 7-day bar chart, week-over-week comparisons, and pattern cards.
//

import SwiftUI
import SwiftData

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.timestamp, order: .reverse) private var meals: [MealLog]
    @Query(sort: \InsightEvent.timestamp, order: .reverse) private var insights: [InsightEvent]
    @Query(sort: \WorkoutLog.startTime, order: .reverse) private var workouts: [WorkoutLog]
    @Query(sort: \SleepLog.startTime, order: .reverse) private var sleepLogs: [SleepLog]
    
    @ObservedObject private var dataService = DashboardDataService.shared
    @ObservedObject private var insightEngine = InsightEngine.shared
    
    @State private var selectedPattern: Pattern?
    var healthKitMealCountsByDay: [Date: Int] = [:]
    var onSeeEntries: (() -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Mascot Header
                MascotHeader(mood: insightEngine.currentMood) { }
                    .padding(.horizontal)
                
                if weeklySummary.dailyData.contains(where: \.hasAnySignal) {
                    // Weekly Bar Chart
                    WeeklyBarChart(dailyData: weeklySummary.dailyData)
                        .padding(.horizontal)
                    
                    // Week-over-Week Trends
                    if !weeklySummary.trends.isEmpty {
                        trendsSection
                    }
                    
                    // Weekly Insight Summary
                    insightSummarySection
                    
                    // Pattern Cards
                    if !weeklySummary.patterns.isEmpty {
                        patternsSection
                    }
                } else {
                    // Empty/Partial State
                    emptyState
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedPattern) { pattern in
            PatternDetailView(pattern: pattern)
        }
    }
    
    // MARK: - Computed Data
    
    private var weeklySummary: WeeklySummary {
        dataService.computeWeeklyTrends(
            meals: meals,
            insights: insights.filter { !$0.isDismissed },
            workouts: workouts,
            sleepLogs: sleepLogs,
            healthKitMealCountsByDay: healthKitMealCountsByDay
        )
    }
    
    private var daysWithData: Int {
        weeklySummary.dailyData.filter(\.hasAnySignal).count
    }
    
    // MARK: - Trends Section
    
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("compared to last week")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: Spacing.xs) {
                ForEach(weeklySummary.trends) { trend in
                    TrendRow(trend: trend)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Insight Summary
    
    private var insightSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("this week's insights")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: Spacing.md) {
                InsightSummaryPill(
                    count: weeklySummary.spikeCount,
                    label: "Spikes",
                    icon: .asset("insight_spike_kawaii"),
                    color: Color.Monch.coral
                )
                InsightSummaryPill(
                    count: weeklySummary.spongeCount,
                    label: "Sponges",
                    icon: .asset("insight_recovery_kawaii"),
                    color: Color.Monch.sage
                )
                InsightSummaryPill(
                    count: weeklySummary.debtCount,
                    label: "Debts",
                    icon: .asset("sleep_kawaii"),
                    color: Color.Monch.periwinkle
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Patterns Section
    
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("patterns detected")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ForEach(weeklySummary.patterns) { pattern in
                PatternCard(pattern: pattern, onSeeEntries: onSeeEntries)
                    .onTapGesture {
                        selectedPattern = pattern
                    }
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            // Ghosted bar preview
            HStack(spacing: Spacing.sm) {
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 60)
                }
            }
            .padding(.horizontal)
            
            Text("\(daysWithData)/7 days logged")
                .font(.Monch.headline)
            
            Text("Patterns emerge after 7 days of logging.")
                .font(.Monch.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xl)
    }
}

// MARK: - Insight Summary Pill

private struct InsightSummaryPill: View {
    let count: Int
    let label: String
    let icon: MonchIconToken
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            MonchIconView(token: icon, size: 28)
            Text("\(count)")
                .font(.Monch.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.Monch.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview {
    WeekView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}
