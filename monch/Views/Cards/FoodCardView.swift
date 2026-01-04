//
//  FoodCardView.swift
//  monch
//
//  Detail card for viewing/editing a logged meal.
//  Shows serving size multiplier, macros with fiber/sugars hierarchy, and delete.
//

import SwiftUI
import SwiftData

struct FoodCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let meal: MealLog
    let onDelete: () -> Void
    
    // MARK: - State
    
    @State private var servingMultiplier: Double = 1.0
    @State private var showMicronutrients = false
    
    private let servingOptions: [Double] = [0.5, 1.0, 1.5, 2.0]
    
    // MARK: - Computed Properties
    
    private var contextTag: String? {
        guard let carbs = meal.carbs else { return nil }
        if carbs > 50 { return "🍞 High Carb" }
        if let protein = meal.protein, protein > 30 { return "💪 High Protein" }
        if let fat = meal.fat, fat > 25 { return "🥑 High Fat" }
        return nil
    }
    
    // Scaled values
    private var scaledCalories: Double? {
        guard let v = meal.calories else { return nil }
        return v * servingMultiplier
    }
    
    private var scaledCarbs: Double? {
        guard let v = meal.carbs else { return nil }
        return v * servingMultiplier
    }
    
    private var scaledProtein: Double? {
        guard let v = meal.protein else { return nil }
        return v * servingMultiplier
    }
    
    private var scaledFat: Double? {
        guard let v = meal.fat else { return nil }
        return v * servingMultiplier
    }
    
    private var scaledFiber: Double? {
        guard let v = meal.fiber else { return nil }
        return v * servingMultiplier
    }
    
    private var scaledSugar: Double? {
        guard let v = meal.sugar else { return nil }
        return v * servingMultiplier
    }
    
    private var scaledCaffeine: Double? {
        guard let v = meal.caffeine else { return nil }
        return v * servingMultiplier
    }
    
    // MARK: - Body
    
    private var isModified: Bool {
        servingMultiplier != 1.0
    }
    
    private var primaryActionLabel: String? {
        isModified ? "Save" : nil
    }
    
    private var primaryAction: (() -> Void)? {
        if isModified {
            return saveChanges
        }
        return nil
    }
    
    var body: some View {
        CardDetailShell(
            title: meal.name,
            icon: "🍽️",
            timestamp: meal.timestamp,
            contextTag: contextTag,
            primaryActionLabel: primaryActionLabel,
            onPrimaryAction: primaryAction,
            onDelete: onDelete
        ) {
            VStack(spacing: 24) {
                // Serving Size Section
                servingSizeSection
                
                Divider()
                
                // Macros Section
                macrosSection
                
                // Micronutrients (Expandable)
                micronutrientsSection
            }
        }
    }
    
    // MARK: - Serving Size
    
    private var servingSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Serving Size")
                .font(.Monch.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(servingOptions, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            servingMultiplier = option
                        }
                    } label: {
                        Text(formatMultiplier(option))
                            .font(.Monch.body)
                            .fontWeight(servingMultiplier == option ? .semibold : .regular)
                            .foregroundStyle(servingMultiplier == option ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(servingMultiplier == option ? Color.Monch.sage : Color.primary.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func formatMultiplier(_ value: Double) -> String {
        if value == 0.5 { return "½" }
        if value == 1.0 { return "1" }
        if value == 1.5 { return "1½" }
        if value == 2.0 { return "2" }
        return String(format: "%.1f", value)
    }
    
    // MARK: - Macros Section
    
    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("MACROS", systemImage: "chart.bar.fill")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                // Calories
                if let cal = scaledCalories {
                    MacroRow(label: "Calories", value: "\(Int(cal)) kcal", isHighlighted: true)
                }
                
                // Carbs with nested fiber/sugar
                if let carbs = scaledCarbs {
                    VStack(spacing: 4) {
                        MacroRow(label: "Total Carbs", value: "\(Int(carbs))g")
                        
                        // Fiber (nested)
                        if let fiber = scaledFiber {
                            HStack {
                                Text("└─ Fiber")
                                    .font(.Monch.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(fiber))g")
                                    .font(.Monch.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 20)
                        }
                        
                        // Sugars (nested)
                        if let sugar = scaledSugar {
                            HStack {
                                Text("└─ Sugars")
                                    .font(.Monch.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(sugar))g")
                                    .font(.Monch.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
                
                // Protein
                if let protein = scaledProtein {
                    MacroRow(label: "Protein", value: "\(Int(protein))g")
                }
                
                // Fat
                if let fat = scaledFat {
                    MacroRow(label: "Total Fat", value: "\(Int(fat))g")
                }
            }
        }
    }
    
    // MARK: - Micronutrients
    
    private var micronutrientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showMicronutrients.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showMicronutrients ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    Text("Micronutrients")
                        .font(.Monch.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            if showMicronutrients {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    if let caffeine = scaledCaffeine {
                        MicroRow(label: "Caffeine", value: "\(Int(caffeine))mg")
                    }
                    
                    // Placeholder for future micronutrients
                    if meal.magnesium != nil || meal.zinc != nil {
                        if let mg = meal.magnesium {
                            MicroRow(label: "Magnesium", value: "\(Int(mg * servingMultiplier))mg")
                        }
                        if let zn = meal.zinc {
                            MicroRow(label: "Zinc", value: "\(Int(zn * servingMultiplier))mg")
                        }
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        // Update meal with new serving size
        if let cal = meal.calories { meal.calories = cal * servingMultiplier }
        if let carbs = meal.carbs { meal.carbs = carbs * servingMultiplier }
        if let protein = meal.protein { meal.protein = protein * servingMultiplier }
        if let fat = meal.fat { meal.fat = fat * servingMultiplier }
        if let fiber = meal.fiber { meal.fiber = fiber * servingMultiplier }
        if let sugar = meal.sugar { meal.sugar = sugar * servingMultiplier }
        if let caffeine = meal.caffeine { meal.caffeine = caffeine * servingMultiplier }
        
        dismiss()
    }
}

// MARK: - Supporting Views

private struct MacroRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isHighlighted ? .Monch.headline : .Monch.body)
            Spacer()
            Text(value)
                .font(isHighlighted ? .Monch.headline : .Monch.body)
                .foregroundStyle(isHighlighted ? Color.Monch.sage : .primary)
        }
    }
}

private struct MicroRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.Monch.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    let meal = MealLog(
        name: "Oatmeal with Banana",
        calories: 350,
        carbs: 52,
        protein: 12,
        fat: 8,
        fiber: 6,
        sugar: 18
    )
    
    return FoodCardView(meal: meal) {
        print("Delete tapped")
    }
}
