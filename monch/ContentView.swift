//
//  ContentView.swift
//  monch
//
//  Main app entry view. Tab-based navigation with Timeline and Dashboard.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, MascotStateLog.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}
