//
//  monchApp.swift
//  monch
//
//  Created by Ananth Radhakrishnan on 03/01/2026.
//

import SwiftUI
import SwiftData

@main
struct monchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealLog.self,
            InsightEvent.self,
            MascotStateLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
