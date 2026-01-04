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
            MascotStateLog.self,
            SleepLog.self,
            WorkoutLog.self,
            VibeCheck.self
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
                .onAppear {
                    Task {
                        // Request HealthKit authorization
                        await HealthKitManager.shared.requestAuthorization()
                        
                        // Request notification authorization
                        let notificationGranted = await NotificationManager.shared.requestAuthorization()
                        if notificationGranted {
                            // Schedule daily Kitchen Closing nudge at 8:30 PM
                            NotificationManager.shared.scheduleKitchenClosingNudge()
                        }
                        
                        // Sync health data to local storage for ambient insights
                        let context = sharedModelContainer.mainContext
                        await HealthKitSyncService.shared.syncAll(modelContext: context)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
