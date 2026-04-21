//
//  CaffeineQuickAddView.swift
//  monch
//
//  Event-based caffeine logging with simple presets.
//

import SwiftUI
import SwiftData

struct CaffeineQuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onCaffeineLogged: ((MealLog) -> Void)?
    
    private let presets: [(icon: MonchIconToken, name: String)] = [
        (.asset("coffee_kawaii"), "Coffee"),
        (.asset("coffee_kawaii"), "Espresso"),
        (.asset("tea_kawaii"), "Tea"),
        (.asset("tea_kawaii"), "Matcha"),
        (.symbol("bolt.fill"), "Energy Drink"),
        (.symbol("pills.fill"), "Caffeine"),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Preset grid
                    presetGrid
                    
                    // Time context
                    timeContext
                }
                .padding()
            }
            .navigationTitle("Log Caffeine Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            MonchIconView(token: .asset("coffee_kawaii"), size: 60)
            
            Text("Log a caffeine event")
                .font(.Monch.headline)
            
            Text("Tap to log timing only. Monch will use recency and biometrics instead of milligram math.")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.lg)
    }
    
    // MARK: - Preset Grid
    
    private var presetGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(presets, id: \.name) { preset in
                Button {
                    logCaffeine(preset)
                } label: {
                    VStack(spacing: Spacing.sm) {
                        MonchIconView(token: preset.icon, size: 40)
                        
                        Text(preset.name)
                            .font(.Monch.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Event only")
                            .font(.Monch.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Time Context
    
    private var timeContext: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let isLate = hour >= 14 // After 2pm
        
        return Group {
            if isLate {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "moon.stars")
                        .foregroundStyle(Color.Monch.periwinkle)
                    
                    Text("Late caffeine may affect your sleep tonight.")
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.Monch.periwinkle.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func logCaffeine(_ preset: (icon: MonchIconToken, name: String)) {
        let meal = MealLog(
            timestamp: Date(),
            name: preset.name,
            mealType: .afternoonSnack,
            caffeine: 1,
            tags: ["caffeine-event"]
        )
        
        modelContext.insert(meal)
        
        // Haptic feedback
        HapticManager.shared.play(.success)
        
        onCaffeineLogged?(meal)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    CaffeineQuickAddView()
        .modelContainer(for: [MealLog.self, InsightEvent.self], inMemory: true)
}
