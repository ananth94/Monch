//
//  MonthView.swift
//  monch
//
//  Monthly overview: metabolic calendar heat map, streaks, and chronic insights.
//

import SwiftUI
import SwiftData

struct MonthView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.timestamp, order: .reverse) private var meals: [MealLog]
    @Query(sort: \InsightEvent.timestamp, order: .reverse) private var insights: [InsightEvent]
    @Query(sort: \WorkoutLog.startTime, order: .reverse) private var workouts: [WorkoutLog]
    @Query(sort: \SleepLog.startTime, order: .reverse) private var sleepLogs: [SleepLog]
    
    @ObservedObject private var dataService = DashboardDataService.shared
    @ObservedObject private var insightEngine = InsightEngine.shared
    
    var onNavigateToDate: ((Date) -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Mascot Header
                MascotHeader(mood: insightEngine.currentMood) { }
                    .padding(.horizontal)
                
                if monthlySummary.daysWithData >= 7 {
                    // Metabolic Calendar
                    MetabolicCalendar(
                        calendar: monthlySummary.calendar,
                        onTapDay: { date in
                            onNavigateToDate?(date)
                        }
                    )
                    .padding(.horizontal)
                    
                    // Streaks Section
                    if !monthlySummary.streaks.isEmpty {
                        streaksSection
                    }
                    
                    // Chronic Insights
                    if !monthlySummary.chronicInsights.isEmpty {
                        chronicInsightsSection
                    }
                } else {
                    // Empty State
                    emptyState
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Computed Data
    
    private var monthlySummary: MonthlySummary {
        dataService.computeMonthlyData(
            meals: meals,
            insights: insights.filter { !$0.isDismissed },
            workouts: workouts,
            sleepLogs: sleepLogs
        )
    }
    
    // MARK: - Streaks Section
    
    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("streaks")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ForEach(monthlySummary.streaks) { streak in
                StreakCard(streak: streak)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Chronic Insights Section
    
    private var chronicInsightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("long-term patterns")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ForEach(monthlySummary.chronicInsights) { insight in
                ChronicInsightCard(insight: insight)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            // Ghosted calendar
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(0..<28, id: \.self) { _ in
                    Circle()
                        .fill(.secondary.opacity(0.1))
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal)
            
            Text("Building your baseline...")
                .font(.Monch.headline)
            
            Text("Monthly patterns become visible after 2+ weeks of consistent logging.")
                .font(.Monch.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    MonthView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}
