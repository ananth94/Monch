//
//  ChronicInsightCard.swift
//  monch
//
//  Card for long-term/chronic metabolic insights with educational tone.
//

import SwiftUI

struct ChronicInsightCard: View {
    let insight: InsightEvent
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: "waveform.path.ecg")
                .font(.title2)
                .foregroundStyle(Color.Monch.periwinkle)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(insight.type.displayTitle)
                    .font(.Monch.callout)
                    .fontWeight(.medium)
                
                Text(insight.message)
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
                
                Button {
                    // TODO: Link to educational content
                } label: {
                    HStack(spacing: 4) {
                        Text("Learn more")
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                    }
                    .font(.Monch.caption)
                    .foregroundStyle(Color.Monch.sage)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.Monch.periwinkle.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ChronicInsightCard(insight: InsightEvent(
        type: .deepSleepRobber,
        severity: 0.6,
        message: "High sugar variability correlates with foggy mornings"
    ))
    .padding()
}

