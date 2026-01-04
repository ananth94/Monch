//
//  ContentView.swift
//  monch
//
//  Main app entry view. Shows onboarding for first-time users, then tab navigation.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}

#Preview("App") {
    ContentView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, MascotStateLog.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}

#Preview("Onboarding") {
    OnboardingView(isOnboardingComplete: .constant(false))
}
