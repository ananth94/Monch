//
//  MealEventLogView.swift
//  monch
//
//  Lightweight meal event capture without food search or macro entry.
//

import SwiftUI
import SwiftData

struct MealEventLogView: View {
    @Environment(\.dismiss) private var dismiss
    var onMealLogged: ((MealLog) -> Void)?

    @State private var selectedMealType: MealLog.MealType = MealLog.MealType.defaultForCurrentTime
    @State private var customName = ""

    private let quickNames: [String] = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snack",
        "Dessert"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground(mood: .neutral)
                    .opacity(0.2)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        headerSection
                        mealTypeSection
                        mealNameSection
                        quickNameSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Meal Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeal()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            MonchIconView(token: .asset("meal_kawaii"), size: 60)

            Text("Log a meal moment")
                .font(.Monch.headline)

            Text("Capture when you ate. Monch will use timing, context, and biometrics to interpret the rest.")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.lg)
    }

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("meal type")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(MealLog.MealType.allCases, id: \.self) { type in
                    Button {
                        selectedMealType = type
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: type.symbolName)
                                .foregroundStyle(selectedMealType == type ? .white : Color.Monch.sage)

                            Text(type.rawValue)
                                .font(.Monch.caption)
                                .foregroundStyle(selectedMealType == type ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(selectedMealType == type ? Color.Monch.sage : Color.white.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }

    private var mealNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("name (optional)")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)

            TextField(selectedMealType.rawValue, text: $customName)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }

    private var quickNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("quick picks")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.sm) {
                ForEach(quickNames, id: \.self) { name in
                    Button(name) {
                        customName = name
                    }
                    .font(.Monch.caption)
                    .buttonStyle(.bordered)
                    .tint(Color.Monch.sage)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func saveMeal() {
        let meal = MealLog(
            timestamp: Date(),
            name: customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedMealType.rawValue : customName.trimmingCharacters(in: .whitespacesAndNewlines),
            mealType: selectedMealType
        )

        HapticManager.shared.play(.success)
        onMealLogged?(meal)
        dismiss()
    }
}

#Preview {
    MealEventLogView()
        .modelContainer(for: MealLog.self, inMemory: true)
}
