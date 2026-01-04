//
//  SupplementStackView.swift
//  monch
//
//  Quick-log common supplement stacks.
//

import SwiftUI
import SwiftData

struct SupplementStackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onSupplementLogged: ((MealLog) -> Void)?
    
    private let stacks: [SupplementStack] = [
        SupplementStack(
            name: "AM Stack",
            emoji: "🛡️",
            description: "Morning essentials",
            supplements: ["Vitamin D3", "Omega-3", "Magnesium"],
            magnesium: 200,
            zinc: 0
        ),
        SupplementStack(
            name: "PM Stack",
            emoji: "🌙",
            description: "Sleep support",
            supplements: ["ZMA", "Glycine"],
            magnesium: 450,
            zinc: 30
        ),
        SupplementStack(
            name: "Pre-Workout",
            emoji: "💪",
            description: "Performance boost",
            supplements: ["Creatine", "Beta-Alanine", "Caffeine"],
            magnesium: 0,
            zinc: 0,
            caffeine: 150
        ),
        SupplementStack(
            name: "Recovery",
            emoji: "🔄",
            description: "Post-workout",
            supplements: ["Glutamine", "BCAAs", "Vitamin C"],
            magnesium: 0,
            zinc: 0
        ),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Stack list
                    stackList
                }
                .padding()
            }
            .navigationTitle("Supplement Stack")
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
            Image(systemName: "pills.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.Monch.sage)
            
            Text("Log Your Stack")
                .font(.Monch.headline)
            
            Text("One tap to log your supplement routine.")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.lg)
    }
    
    // MARK: - Stack List
    
    private var stackList: some View {
        VStack(spacing: Spacing.md) {
            ForEach(stacks, id: \.name) { stack in
                Button {
                    logStack(stack)
                } label: {
                    HStack(spacing: Spacing.md) {
                        Text(stack.emoji)
                            .font(.system(size: 36))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stack.name)
                                .font(.Monch.headline)
                                .foregroundStyle(.primary)
                            
                            Text(stack.description)
                                .font(.Monch.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(stack.supplements.joined(separator: " • "))
                                .font(.Monch.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.Monch.sage)
                    }
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
    
    // MARK: - Actions
    
    private func logStack(_ stack: SupplementStack) {
        let meal = MealLog(
            timestamp: Date(),
            name: stack.name,
            mealType: .afternoonSnack,
            calories: 0,
            caffeine: stack.caffeine > 0 ? stack.caffeine : nil,
            magnesium: stack.magnesium > 0 ? stack.magnesium : nil,
            zinc: stack.zinc > 0 ? stack.zinc : nil
        )
        
        modelContext.insert(meal)
        
        // Haptic feedback
        HapticManager.shared.play(.success)
        
        onSupplementLogged?(meal)
        dismiss()
    }
}

// MARK: - Model

private struct SupplementStack {
    let name: String
    let emoji: String
    let description: String
    let supplements: [String]
    let magnesium: Double
    let zinc: Double
    var caffeine: Double = 0
}

// MARK: - Preview

#Preview {
    SupplementStackView()
        .modelContainer(for: MealLog.self, inMemory: true)
}
