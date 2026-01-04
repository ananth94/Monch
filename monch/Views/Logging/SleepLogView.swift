//
//  SleepLogView.swift
//  monch
//
//  Manual sleep entry form for users without wearables.
//

import SwiftUI
import SwiftData

struct SleepLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Form State
    
    @State private var bedtime: Date = Calendar.current.date(
        bySettingHour: 22, minute: 30, second: 0, of: Date()
    ) ?? Date()
    @State private var wakeTime: Date = Calendar.current.date(
        bySettingHour: 7, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var qualityRating: Int = 3
    @State private var notes: String = ""
    
    // MARK: - Callbacks
    
    var onSave: ((SleepLog) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MeshGradientBackground(mood: .sleep)
                    .opacity(0.2)
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Sleep Duration Preview
                        durationPreview
                        
                        // Bedtime Section
                        bedtimeSection
                        
                        // Wake Time Section
                        wakeTimeSection
                        
                        // Quality Rating Section
                        qualitySection
                        
                        // Notes Section
                        notesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSleep()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidTimeRange)
                }
            }
        }
    }
    
    // MARK: - Duration Preview
    
    private var durationPreview: some View {
        VStack(spacing: Spacing.xs) {
            Text("😴")
                .font(.system(size: 50))
            
            Text(sleepDurationFormatted)
                .font(.Monch.title2)
                .fontWeight(.semibold)
            
            Text("of sleep")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Bedtime Section
    
    private var bedtimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("bedtime")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            DatePicker(
                "Bedtime",
                selection: $bedtime,
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
    
    // MARK: - Wake Time Section
    
    private var wakeTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("wake time")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            DatePicker(
                "Wake time",
                selection: $wakeTime,
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
    
    // MARK: - Quality Section
    
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("how did you sleep?")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.md) {
                ForEach(1...5, id: \.self) { rating in
                    QualityButton(
                        rating: rating,
                        isSelected: qualityRating == rating
                    ) {
                        qualityRating = rating
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("notes (optional)")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            TextField("How did you feel waking up?", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Computed Properties
    
    private var isValidTimeRange: Bool {
        wakeTime > bedtime
    }
    
    private var sleepDuration: TimeInterval {
        guard isValidTimeRange else { return 0 }
        return wakeTime.timeIntervalSince(bedtime)
    }
    
    private var sleepDurationFormatted: String {
        let hours = Int(sleepDuration) / 3600
        let minutes = (Int(sleepDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - Save Sleep
    
    private func saveSleep() {
        guard isValidTimeRange else { return }
        
        // Convert 1-5 rating to 0.0-1.0 score
        let qualityScore = Double(qualityRating) / 5.0
        
        let sleepLog = SleepLog(
            startTime: bedtime,
            endTime: wakeTime,
            qualityScore: qualityScore,
            notes: notes.isEmpty ? nil : notes,
            isManualEntry: true
        )
        
        modelContext.insert(sleepLog)
        onSave?(sleepLog)
        dismiss()
    }
}

// MARK: - Quality Button

private struct QualityButton: View {
    let rating: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.title2)
                Text(label)
                    .font(.Monch.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? Color.Monch.periwinkle.opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var emoji: String {
        switch rating {
        case 1: return "😫"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🤩"
        default: return "😐"
        }
    }
    
    private var label: String {
        switch rating {
        case 1: return "Awful"
        case 2: return "Poor"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return ""
        }
    }
}

// MARK: - Preview

#Preview {
    SleepLogView()
        .modelContainer(for: SleepLog.self, inMemory: true)
}
