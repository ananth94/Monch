//
//  MonchCard.swift
//  monch
//
//  Reusable glass card container for the "Cozy Science" design language.
//  Provides consistent ultraThinMaterial background with xl corner radius.
//

import SwiftUI

/// A glass-morphism card container for content sections
struct MonchCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.md
    
    init(padding: CGFloat = Spacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }
}

/// A section card with header label
struct MonchCardSection<Content: View>: View {
    let label: String
    let icon: String?
    let content: Content
    
    init(_ label: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.Monch.caption)
                }
                Text(label.lowercased())
                    .font(.Monch.caption)
            }
            .foregroundStyle(.secondary)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }
}

// MARK: - Pill Selector

/// A horizontal pill/segment selector matching the "Cozy Science" style
struct MonchPillSelector<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.Monch.body)
                        .fontWeight(selection == option ? .semibold : .regular)
                        .foregroundStyle(selection == option ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(selection == option ? Color.Monch.sage : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Quick Action Button

/// Primary action button with sage fill
struct MonchPrimaryButton: View {
    let label: String
    let icon: String?
    let action: () -> Void
    
    init(_ label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(label)
            }
            .font(.Monch.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.Monch.sage)
            )
        }
    }
}

/// Secondary action button with outlined style
struct MonchSecondaryButton: View {
    let label: String
    let action: () -> Void
    
    init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.Monch.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

/// Soft delete button
struct MonchDeleteButton: View {
    let action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
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
    }
}

// MARK: - Previews

#Preview("MonchCard") {
    VStack(spacing: 16) {
        MonchCard {
            Text("Basic card content")
        }
        
        MonchCardSection("macros", icon: "chart.bar.fill") {
            Text("Section content here")
        }
    }
    .padding()
    .background(Color.Monch.cream)
}

#Preview("MonchPillSelector") {
    struct PreviewWrapper: View {
        @State private var selection = 1.0
        
        var body: some View {
            MonchPillSelector(
                options: [0.5, 1.0, 1.5, 2.0],
                selection: $selection
            ) { value in
                if value == 0.5 { return "½" }
                if value == 1.5 { return "1½" }
                return String(format: "%.0f", value)
            }
            .padding()
            .background(Color.Monch.cream)
        }
    }
    return PreviewWrapper()
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        MonchPrimaryButton("Log Meal", icon: "fork.knife") {}
        MonchSecondaryButton("Dismiss") {}
        MonchDeleteButton {}
    }
    .padding()
    .background(Color.Monch.cream)
}
