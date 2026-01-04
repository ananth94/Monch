//
//  TrendRow.swift
//  monch
//
//  Week-over-week comparison row with metric, delta, and commentary.
//

import SwiftUI

struct TrendRow: View {
    let trend: Trend
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Metric name
            Text(trend.metric)
                .font(.Monch.callout)
                .frame(width: 70, alignment: .leading)
            
            // Arrow + Delta
            HStack(spacing: 4) {
                Text(trend.arrow)
                    .font(.body)
                    .foregroundStyle(trend.isImprovement ? Color.Monch.sage : .secondary)
                
                Text(trend.deltaDisplay)
                    .font(.Monch.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(trend.isImprovement ? Color.Monch.sage : .secondary)
            }
            .frame(width: 60)
            
            Spacer()
            
            // Commentary
            Text(trend.commentary)
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TrendRow(trend: Trend(metric: "Carbs", delta: -12, deltaDisplay: "12%", commentary: "Better control"))
        TrendRow(trend: Trend(metric: "Protein", delta: 8, deltaDisplay: "8%", commentary: "Nice!"))
        TrendRow(trend: Trend(metric: "Spikes", delta: -2, deltaDisplay: "2", commentary: "Fewer crashes"))
        TrendRow(trend: Trend(metric: "Sleep", delta: 23, deltaDisplay: "23m", commentary: "More rest"))
    }
    .padding()
}
