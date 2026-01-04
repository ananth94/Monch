//
//  DashboardView.swift
//  monch
//
//  The "Metabolic Status Hub" — aggregated insights across Today/Week/Month.
//

import SwiftUI
import SwiftData

enum DashboardTab: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.timestamp, order: .reverse) private var meals: [MealLog]
    @Query(sort: \InsightEvent.timestamp, order: .reverse) private var insights: [InsightEvent]
    @Query(sort: \WorkoutLog.startTime, order: .reverse) private var workouts: [WorkoutLog]
    @Query(sort: \SleepLog.startTime, order: .reverse) private var sleepLogs: [SleepLog]
    
    @ObservedObject private var dataService = DashboardDataService.shared
    @ObservedObject private var insightEngine = InsightEngine.shared
    
    @State private var selectedTab: DashboardTab = .today
    
    var onNavigateToDate: ((Date) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MeshGradientBackground(mood: insightEngine.currentMood.gradientMood)
                    .opacity(0.2)
                
                VStack(spacing: 0) {
                    // Segmented control at top
                    Picker("Time Period", selection: $selectedTab) {
                        ForEach(DashboardTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        TodayView(summary: todaySummary)
                            .tag(DashboardTab.today)
                        
                        WeekViewPlaceholder()
                            .tag(DashboardTab.week)
                        
                        MonthViewPlaceholder()
                            .tag(DashboardTab.month)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Computed Data
    
    private var todaySummary: TodaySummary {
        dataService.computeTodayMetrics(
            meals: meals,
            insights: insights.filter { !$0.isDismissed },
            workouts: workouts,
            sleepLogs: sleepLogs
        )
    }
}

// MARK: - Placeholder Views (for PR #1)

struct WeekViewPlaceholder: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                MascotHeader(mood: .neutral) { }
                    .padding(.horizontal)
                
                ContentUnavailableView(
                    "Week View",
                    systemImage: "chart.bar",
                    description: Text("Coming in PR #2")
                )
            }
        }
    }
}

struct MonthViewPlaceholder: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                MascotHeader(mood: .neutral) { }
                    .padding(.horizontal)
                
                ContentUnavailableView(
                    "Month View",
                    systemImage: "calendar",
                    description: Text("Coming in PR #2")
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}
