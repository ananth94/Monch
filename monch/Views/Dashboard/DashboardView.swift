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
    
    @Binding var selectedDate: Date
    @State private var selectedTab: DashboardTab = .today
    @State private var healthKitMealCountsByDay: [Date: Int] = [:]
    @State private var showingDatePicker = false
    
    var onNavigateToDate: ((Date) -> Void)?
    
    init(selectedDate: Binding<Date> = .constant(Date()), onNavigateToDate: ((Date) -> Void)? = nil) {
        self._selectedDate = selectedDate
        self.onNavigateToDate = onNavigateToDate
    }
    
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
                        TodayView(summary: todaySummary, selectedDate: selectedDate)
                            .tag(DashboardTab.today)
                        
                        WeekView(
                            healthKitMealCountsByDay: healthKitMealCountsByDay,
                            onSeeEntries: {
                            onNavigateToDate?(Date())
                        })
                            .tag(DashboardTab.week)
                        
                        MonthView(
                            healthKitMealCountsByDay: healthKitMealCountsByDay,
                            onNavigateToDate: { date in
                                selectedDate = date
                                selectedTab = .today
                                onNavigateToDate?(date)
                            }
                        )
                            .tag(DashboardTab.month)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
            }
            .navigationTitle(selectedTab == .today && !selectedDate.isToday ? selectedDate.formatted(date: .abbreviated, time: .omitted) : "Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(selectedDate.isToday ? .secondary : Color.Monch.sage)
                    }
                }
            }
        }
        .task {
            await loadHealthKitMealCounts()
        }
        .task(id: selectedDate) {
            await ensureHealthKitMealCountLoaded(for: selectedDate)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
    }
    
    // MARK: - Computed Data
    
    private var todaySummary: TodaySummary {
        dataService.computeDayMetrics(
            meals: meals,
            insights: insights.filter { !$0.isDismissed },
            workouts: workouts,
            sleepLogs: sleepLogs,
            date: selectedDate,
            healthKitMealCount: healthKitMealCountsByDay[Calendar.current.startOfDay(for: selectedDate)] ?? 0
        )
    }
    
    private func loadHealthKitMealCounts() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else { return }
        
        do {
            healthKitMealCountsByDay = try await HealthKitManager.shared.fetchNutritionEventCounts(for: thirtyDaysAgo...Date())
        } catch {
            healthKitMealCountsByDay = [:]
        }
    }
    
    private func ensureHealthKitMealCountLoaded(for date: Date) async {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        if healthKitMealCountsByDay[dayStart] != nil {
            return
        }
        
        guard let dayEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) else {
            return
        }
        
        do {
            let dayCounts = try await HealthKitManager.shared.fetchNutritionEventCounts(for: dayStart...dayEnd)
            await MainActor.run {
                healthKitMealCountsByDay.merge(dayCounts) { _, new in new }
            }
        } catch {
            // Keep the existing cache if HealthKit fetch fails for the selected day.
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}
