//
//  ContentView.swift
//  monch
//
//  Main app entry view. Displays the Timeline as the primary interface.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TimelineView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, MascotStateLog.self], inMemory: true)
}
