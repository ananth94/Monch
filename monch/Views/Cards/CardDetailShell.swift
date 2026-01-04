//
//  CardDetailShell.swift
//  monch
//
//  Shared container for all timeline card detail views.
//  Provides consistent header, actions, and styling per Timeline_Cards_UX.md.
//  Updated for "Cozy Science" design language with mesh gradients and glass material.
//

import SwiftUI

/// Reusable shell for timeline card detail views
struct CardDetailShell<Content: View>: View {
    // MARK: - Properties
    
    let title: String
    let icon: String
    let timestamp: Date
    let contextTag: String?
    
    /// Optional mood for context-aware gradient background
    let mood: GradientMood
    
    let primaryActionLabel: String?
    let onPrimaryAction: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @ViewBuilder let content: () -> Content
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    
    public init(
        title: String,
        icon: String,
        timestamp: Date,
        contextTag: String? = nil,
        mood: GradientMood = .neutral,
        primaryActionLabel: String? = nil,
        onPrimaryAction: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.timestamp = timestamp
        self.contextTag = contextTag
        self.mood = mood
        self.primaryActionLabel = primaryActionLabel
        self.onPrimaryAction = onPrimaryAction
        self.onDelete = onDelete
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle mesh gradient background (0.2 opacity per design decision)
                MeshGradientBackground(mood: mood)
                    .opacity(0.2)
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        cardHeader
                        
                        // Content wrapped in glass card
                        MonchCard(padding: Spacing.lg) {
                            content()
                        }
                        .padding(.horizontal)
                        
                        // Delete Button (if provided)
                        if onDelete != nil {
                            deleteButton
                                .padding(.horizontal)
                        }
                        
                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.top, Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                    }
                }
                
                if let label = primaryActionLabel, let action = onPrimaryAction {
                    ToolbarItem(placement: .primaryAction) {
                        Button(label, action: action)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Monch.sage)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Subviews
    
    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                // Icon with subtle glow effect
                Text(icon)
                    .font(.title)
                    .shadow(color: moodAccentColor.opacity(0.3), radius: 8)
                
                Text(title)
                    .font(.Monch.title3)
                    .lineLimit(2)
            }
            
            HStack(spacing: Spacing.sm) {
                Text(timestamp, style: .time)
                    .font(.Monch.subheadline)
                    .foregroundStyle(.secondary)
                
                if let tag = contextTag {
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(tag)
                        .font(.Monch.caption)
                        .foregroundStyle(moodAccentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(moodAccentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Entry")
            }
            .font(.Monch.body)
            .foregroundStyle(Color.Monch.coral)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.Monch.coral.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    /// Accent color based on mood
    private var moodAccentColor: Color {
        switch mood {
        case .acute: return Color.Monch.coral
        case .recovery: return Color.Monch.sage
        case .sleep: return Color.Monch.periwinkle
        case .neutral: return Color.Monch.sage
        }
    }
}

// MARK: - Preview

#Preview("Neutral Mood") {
    CardDetailShell(
        title: "Oatmeal with Banana",
        icon: "🍽️",
        timestamp: Date(),
        contextTag: "🍞 High Carb",
        mood: .neutral,
        primaryActionLabel: "Save",
        onPrimaryAction: {},
        onDelete: {}
    ) {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card content goes here")
            Text("With glass material background")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Acute Mood (Sugar Spike)") {
    CardDetailShell(
        title: "Sugar Spike Detected",
        icon: "💡",
        timestamp: Date(),
        contextTag: "🔶 Moderate",
        mood: .acute,
        primaryActionLabel: nil,
        onPrimaryAction: nil,
        onDelete: nil
    ) {
        Text("Your heart rate spiked after lunch. A 10-minute walk could help.")
            .foregroundStyle(.secondary)
    }
}

#Preview("Recovery Mood (Anabolic)") {
    CardDetailShell(
        title: "Morning Run",
        icon: "🏃",
        timestamp: Date(),
        contextTag: "💪 Zone 2",
        mood: .recovery,
        onDelete: {}
    ) {
        Text("Workout details here")
    }
}
