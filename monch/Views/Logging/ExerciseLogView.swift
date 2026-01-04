//
//  ExerciseLogView.swift
//  monch
//
//  Manual workout entry form for users without wearables.
//

import SwiftUI
import SwiftData

struct ExerciseLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Form State
    
    @State private var selectedCategory: ExerciseCategory = .cardio
    @State private var customActivityName: String = ""
    @State private var durationMinutes: Int = 30
    @State private var activeCalories: String = ""
    @State private var distanceKm: String = ""
    @State private var startTime: Date = Date()
    
    // MARK: - Callbacks
    
    var onSave: ((WorkoutLog) -> Void)?
    
    // Duration options
    private let durationOptions = [15, 20, 30, 45, 60, 90, 120, 180]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MeshGradientBackground(mood: .recovery)
                    .opacity(0.2)
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Activity Type Section
                        activityTypeSection
                        
                        // Duration Section
                        durationSection
                        
                        // Start Time Section
                        startTimeSection
                        
                        // Optional Metrics Section
                        optionalMetricsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Activity Type Section
    
    private var activityTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("activity type")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    ActivityTypeButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            
            // Custom name field
            TextField("Activity name (optional)", text: $customActivityName)
                .textFieldStyle(.roundedBorder)
                .padding(.top, Spacing.xs)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Duration Section
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("duration")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        DurationPill(
                            minutes: minutes,
                            isSelected: durationMinutes == minutes
                        ) {
                            durationMinutes = minutes
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Start Time Section
    
    private var startTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("when")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            DatePicker(
                "Start time",
                selection: $startTime,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Optional Metrics Section
    
    private var optionalMetricsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("optional metrics")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading) {
                    Text("Calories")
                        .font(.Monch.caption2)
                        .foregroundStyle(.tertiary)
                    TextField("kcal", text: $activeCalories)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                
                if selectedCategory == .cardio {
                    VStack(alignment: .leading) {
                        Text("Distance")
                            .font(.Monch.caption2)
                            .foregroundStyle(.tertiary)
                        TextField("km", text: $distanceKm)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Save Workout
    
    private func saveWorkout() {
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let activityName = customActivityName.isEmpty ? selectedCategory.displayName : customActivityName
        
        let workout = WorkoutLog(
            startTime: startTime,
            endTime: endTime,
            duration: TimeInterval(durationMinutes * 60),
            activityTypeRaw: activityTypeRaw(for: selectedCategory),
            activityName: activityName,
            distanceMeters: Double(distanceKm).map { $0 * 1000 },
            activeCalories: Double(activeCalories),
            isManualEntry: true
        )
        
        modelContext.insert(workout)
        onSave?(workout)
        dismiss()
    }
    
    /// Map ExerciseCategory to raw activity type value
    private func activityTypeRaw(for category: ExerciseCategory) -> UInt {
        switch category {
        case .cardio: return 37 // Running
        case .strength: return 50 // Traditional Strength Training
        case .hiit: return 63 // HIIT
        case .flexibility: return 33 // Yoga
        case .other: return 3000 // Other
        }
    }
}

// MARK: - Activity Type Button

private struct ActivityTypeButton: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text(category.icon)
                    .font(.title)
                Text(category.displayName)
                    .font(.Monch.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? Color.Monch.sage.opacity(0.3) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .strokeBorder(
                                isSelected ? Color.Monch.sage : Color.secondary.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duration Pill

private struct DurationPill: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(formattedDuration)
                .font(.Monch.callout)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.Monch.sage : Color.secondary.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private var formattedDuration: String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    ExerciseLogView()
        .modelContainer(for: WorkoutLog.self, inMemory: true)
}
