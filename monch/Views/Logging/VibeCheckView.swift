//
//  VibeCheckView.swift
//  monch
//
//  Quick subjective check-in modal for energy, focus, and mood.
//

import SwiftUI
import SwiftData

struct VibeCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onVibeLogged: ((VibeCheck) -> Void)?
    
    @State private var energy: Int = 3
    @State private var focus: Int = 3
    @State private var mood: Int = 3
    @State private var note: String = ""
    @State private var isAnimatingIn = false
    
    private let emojis = ["😩", "😕", "😐", "🙂", "😄"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header with overall emoji
                    headerSection
                        .opacity(isAnimatingIn ? 1 : 0)
                        .offset(y: isAnimatingIn ? 0 : 20)
                    
                    // Sliders
                    VStack(spacing: Spacing.lg) {
                        vibeSlider(label: "Energy", value: $energy, icon: "bolt.fill", color: .orange)
                        vibeSlider(label: "Focus", value: $focus, icon: "scope", color: Color.Monch.sage)
                        vibeSlider(label: "Mood", value: $mood, icon: "face.smiling", color: Color.Monch.periwinkle)
                    }
                    .opacity(isAnimatingIn ? 1 : 0)
                    .offset(y: isAnimatingIn ? 0 : 30)
                    
                    // Optional note
                    noteSection
                        .opacity(isAnimatingIn ? 1 : 0)
                        .offset(y: isAnimatingIn ? 0 : 40)
                    
                    // Submit button
                    submitButton
                        .opacity(isAnimatingIn ? 1 : 0)
                        .offset(y: isAnimatingIn ? 0 : 50)
                }
                .padding()
            }
            .navigationTitle("Vibe Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                isAnimatingIn = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(overallEmoji)
                .font(.system(size: 80))
                .scaleEffect(isAnimatingIn ? 1 : 0.5)
                .animation(.spring(duration: 0.8).delay(0.2), value: isAnimatingIn)
            
            Text("How are you feeling?")
                .font(.Monch.headline)
            
            Text("Quick check-in helps Monch understand your patterns.")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.lg)
    }
    
    private var overallEmoji: String {
        let avg = Double(energy + focus + mood) / 3.0
        let index = min(4, max(0, Int(round(avg)) - 1))
        return emojis[index]
    }
    
    // MARK: - Slider
    
    private func vibeSlider(
        label: String,
        value: Binding<Int>,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.Monch.headline)
                Spacer()
                Text(emojis[value.wrappedValue - 1])
                    .font(.title2)
            }
            
            // Custom slider with emojis
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            value.wrappedValue = level
                        }
                        HapticManager.shared.play(.selection)
                    } label: {
                        Text(emojis[level - 1])
                            .font(value.wrappedValue == level ? .title : .title2)
                            .opacity(value.wrappedValue == level ? 1 : 0.4)
                            .scaleEffect(value.wrappedValue == level ? 1.2 : 1)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(color.opacity(0.1))
        )
    }
    
    // MARK: - Note
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Note (optional)")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            TextField("e.g., Had coffee an hour ago", text: $note)
                .textFieldStyle(.plain)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(.ultraThinMaterial)
                )
        }
    }
    
    // MARK: - Submit
    
    private var submitButton: some View {
        Button {
            logVibe()
        } label: {
            HStack {
                Text("Log Vibe")
                    .font(.Monch.headline)
                Image(systemName: "checkmark")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.Monch.sage)
            )
        }
        .padding(.top, Spacing.lg)
    }
    
    private func logVibe() {
        let vibe = VibeCheck(
            energy: energy,
            focus: focus,
            mood: mood,
            note: note.isEmpty ? nil : note
        )
        
        modelContext.insert(vibe)
        
        HapticManager.shared.play(.success)
        
        onVibeLogged?(vibe)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    VibeCheckView()
        .modelContainer(for: VibeCheck.self, inMemory: true)
}
