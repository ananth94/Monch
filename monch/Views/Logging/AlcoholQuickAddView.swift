//
//  AlcoholQuickAddView.swift
//  monch
//
//  Simple event-based alcohol logging.
//

import SwiftUI
import SwiftData

struct AlcoholQuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let presets: [(assetName: String, name: String)] = [
        ("alcohol_kawaii", "Drink"),
        ("alcohol_kawaii", "Wine"),
        ("alcohol_kawaii", "Beer"),
        ("alcohol_kawaii", "Cocktail")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                        ForEach(presets, id: \.name) { preset in
                            Button {
                                logAlcohol(named: preset.name)
                            } label: {
                                VStack(spacing: Spacing.sm) {
                                    MonchIconView(token: .asset(preset.assetName), size: 42)

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
                .padding()
            }
            .navigationTitle("Log Alcohol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            MonchIconView(token: .asset("alcohol_kawaii"), size: 60)

            Text("Log an alcohol event")
                .font(.Monch.headline)

            Text("Keep it lightweight. Monch will use timing and overnight recovery signals instead of drink counts.")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.lg)
    }

    private func logAlcohol(named name: String) {
        let event = MealLog(
            timestamp: Date(),
            name: name,
            mealType: .eveningSnack,
            tags: ["alcohol-event"]
        )

        modelContext.insert(event)
        HapticManager.shared.play(.success)
        dismiss()
    }
}

#Preview {
    AlcoholQuickAddView()
        .modelContainer(for: MealLog.self, inMemory: true)
}
