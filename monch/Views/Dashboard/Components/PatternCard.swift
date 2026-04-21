//
//  PatternCard.swift
//  monch
//
//  Behavioral pattern card showing what happened, why it matters, and what to try.
//

import SwiftUI

struct PatternCard: View {
    let pattern: Pattern
    var onSeeEntries: (() -> Void)?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                MonchIconView(token: pattern.icon, size: 24, tint: patternBorderColor)
                
                Text(pattern.name)
                    .font(.Monch.callout)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Description
            Text(pattern.description)
                .font(.Monch.body)
                .foregroundStyle(.secondary)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Impact
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.caption)
                            .foregroundStyle(Color.Monch.coral)
                        Text(pattern.impact)
                            .font(.Monch.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Suggestion
                    HStack(alignment: .top, spacing: Spacing.xs) {
                        Image(systemName: "lightbulb")
                            .font(.caption)
                            .foregroundStyle(Color.Monch.sage)
                        Text(pattern.suggestion)
                            .font(.Monch.caption)
                            .foregroundStyle(.primary)
                    }
                    
                    // Drill-down link
                    if !pattern.linkedEntryIDs.isEmpty {
                        Button {
                            onSeeEntries?()
                        } label: {
                            HStack {
                                Text("See linked meals")
                                    .font(.Monch.caption)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                            }
                            .foregroundStyle(Color.Monch.sage)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(patternBorderColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var patternBorderColor: Color {
        switch pattern.loopColor {
        case .acute: return Color.Monch.coral
        case .recovery: return Color.Monch.sage
        case .sleep: return Color.Monch.periwinkle
        case .neutral: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PatternCard(pattern: Pattern(
            name: "Weekend Wind-Down",
            icon: .asset("sleep_kawaii"),
            description: "Late meals detected on Fri & Sat",
            impact: "~12% less Deep Sleep on those nights",
            suggestion: "Try closing the kitchen by 8pm on weekends",
            linkedEntryIDs: [UUID(), UUID()],
            loopColor: .sleep
        ))
        
        PatternCard(pattern: Pattern(
            name: "Post-Workout Refuel",
            icon: .asset("insight_recovery_kawaii"),
            description: "4/5 workouts followed by protein",
            impact: "Better recovery correlation",
            suggestion: "Keep it up! Your muscles are responding.",
            linkedEntryIDs: [],
            loopColor: .recovery
        ))
    }
    .padding()
}
