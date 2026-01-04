//
//  CaffeineQuickAddView.swift
//  monch
//
//  One-tap caffeine logging with preset amounts.
//

import SwiftUI
import SwiftData

struct CaffeineQuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onCaffeineLogged: ((MealLog) -> Void)?
    
    private let presets: [(emoji: String, name: String, caffeine: Double, calories: Double)] = [
        ("☕", "Espresso", 63, 3),
        ("☕", "Coffee", 95, 2),
        ("🥤", "Americano", 95, 10),
        ("🍵", "Green Tea", 28, 2),
        ("🧋", "Matcha Latte", 70, 120),
        ("🥤", "Energy Drink", 80, 110),
        ("🥤", "Cold Brew", 200, 5),
        ("💊", "Caffeine Pill", 200, 0),
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
            .navigationTitle("Quick Caffeine")
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
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.Monch.coral)
            
            Text("One Tap Coffee")
                .font(.Monch.headline)
            
            Text("Tap to log. We'll track timing for the Caffeine Jitter insight.")
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
                        Text(preset.emoji)
                            .font(.system(size: 36))
                        
                        Text(preset.name)
                            .font(.Monch.headline)
                            .foregroundStyle(.primary)
                        
                        Text("\(Int(preset.caffeine))mg caffeine")
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
    
    private func logCaffeine(_ preset: (emoji: String, name: String, caffeine: Double, calories: Double)) {
        let meal = MealLog(
            timestamp: Date(),
            name: preset.name,
            mealType: .afternoonSnack,
            calories: preset.calories,
            caffeine: preset.caffeine
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
