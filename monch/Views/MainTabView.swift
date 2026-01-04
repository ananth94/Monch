//
//  MainTabView.swift
//  monch
//
//  Root tab navigation container for the app.
//  Timeline (home) and Dashboard tabs.
//

import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case timeline
    case dashboard
    
    var title: String {
        switch self {
        case .timeline: return "Timeline"
        case .dashboard: return "Dashboard"
        }
    }
    
    var icon: String {
        switch self {
        case .timeline: return "house.fill"
        case .dashboard: return "chart.bar.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .timeline
    @State private var timelineDate: Date? = nil
    @State private var showStreakCelebration = false
    
    @Query(sort: \MealLog.timestamp, order: .reverse) private var meals: [MealLog]
    @ObservedObject private var streakTracker = StreakTracker.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label(AppTab.timeline.title, systemImage: AppTab.timeline.icon)
                }
                .tag(AppTab.timeline)
            
            DashboardView(
                onNavigateToDate: { date in
                    timelineDate = date
                    selectedTab = .timeline
                }
            )
                .tabItem {
                    Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
                }
                .tag(AppTab.dashboard)
        }
        .tint(Color.Monch.sage)
        .onAppear {
            streakTracker.updateStreak(meals: meals)
            checkForCelebration()
        }
        .onChange(of: meals.count) { _, _ in
            streakTracker.updateStreak(meals: meals)
            checkForCelebration()
        }
        .fullScreenCover(isPresented: $showStreakCelebration) {
            if let milestone = streakTracker.pendingMilestone {
                StreakCelebrationView(
                    milestone: milestone,
                    streakCount: streakTracker.currentStreak
                ) {
                    streakTracker.dismissMilestone()
                    showStreakCelebration = false
                }
            }
        }
    }
    
    private func checkForCelebration() {
        if streakTracker.pendingMilestone != nil {
            // Slight delay for UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showStreakCelebration = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}
