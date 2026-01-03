//
//  ContentView.swift
//  monch
//
//  Created by Ananth Radhakrishnan on 03/01/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.timestamp, order: .reverse) private var meals: [MealLog]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MascotHeader()
                
                List {
                    if meals.isEmpty {
                        ContentUnavailableView(
                            "Your timeline is empty",
                            systemImage: "fork.knife",
                            description: Text("Log your first meal to wake up Monch.")
                        )
                    } else {
                        ForEach(meals) { meal in
                            Text(meal.name)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Timeline")
            //.toolbar(.hidden, for: .navigationBar) // iOS 16+
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addSampleMeal) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addSampleMeal() {
        withAnimation {
            let newMeal = MealLog(name: "Sample Oatmeal", calories: 300)
            modelContext.insert(newMeal)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MealLog.self, inMemory: true)
}
