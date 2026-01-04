//
//  CardDetailShell.swift
//  monch
//
//  Shared container for all timeline card detail views.
//  Provides consistent header, actions, and styling per Timeline_Cards_UX.md.
//

import SwiftUI

/// Reusable shell for timeline card detail views
struct CardDetailShell<Content: View>: View {
    // MARK: - Properties
    
    let title: String
    let icon: String
    let timestamp: Date
    let contextTag: String?
    
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
        primaryActionLabel: String? = nil,
        onPrimaryAction: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.timestamp = timestamp
        self.contextTag = contextTag
        self.primaryActionLabel = primaryActionLabel
        self.onPrimaryAction = onPrimaryAction
        self.onDelete = onDelete
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    cardHeader
                    
                    // Divider
                    Divider()
                        .padding(.horizontal)
                    
                    // Content
                    content()
                        .padding()
                    
                    // Delete Button (if provided)
                    if onDelete != nil {
                        deleteButton
                    }
                }
            }
            .background(Color.Monch.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
                
                if let label = primaryActionLabel, let action = onPrimaryAction {
                    ToolbarItem(placement: .primaryAction) {
                        Button(label, action: action)
                            .fontWeight(.semibold)
                    }
                }
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
    }
    
    // MARK: - Subviews
    
    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.title2)
                
                Text(title)
                    .font(.Monch.title2)
                    .lineLimit(2)
            }
            
            HStack(spacing: 8) {
                Text(timestamp, style: .time)
                    .font(.Monch.subheadline)
                    .foregroundStyle(.secondary)
                
                if let tag = contextTag {
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(tag)
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
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
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    CardDetailShell(
        title: "Oatmeal with Banana",
        icon: "🍽️",
        timestamp: Date(),
        contextTag: "🍞 High Carb",
        primaryActionLabel: "Save",
        onPrimaryAction: {},
        onDelete: {}
    ) {
        Text("Card content goes here")
            .frame(height: 200)
    }
}
