//
//  MetabolicVibeIndicator.swift
//  monch
//
//  Qualitative 5-tier metabolic status display.
//  Supportive, not punitive — no harsh numbers or red states.
//

import SwiftUI

struct MetabolicVibeIndicator: View {
    let tier: MetabolicTier
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Emoji and ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.2)
                    .foregroundStyle(tierColor)
                
                // Animated progress ring
                Circle()
                    .trim(from: 0, to: appeared ? tierProgress : 0)
                    .stroke(
                        tierGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8, bounce: 0.3), value: appeared)
                
                // Emoji
                Text(tier.emoji)
                    .font(.system(size: 50))
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.spring(duration: 0.5, bounce: 0.4).delay(0.3), value: appeared)
            }
            .frame(width: 140, height: 140)
            
            // Tier name
            Text(tier.name.uppercased())
                .font(.Monch.headline)
                .fontWeight(.bold)
                .tracking(1)
            
            // Encouraging copy
            Text(tier.encouragingCopy)
                .font(.Monch.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            appeared = true
        }
    }
    
    // MARK: - Computed Properties
    
    private var tierColor: Color {
        switch tier {
        case .thriving, .balanced: return Color.Monch.sage
        case .steady: return Color.secondary
        case .learning: return Color.Monch.coral
        case .resetting: return Color.Monch.periwinkle
        }
    }
    
    private var tierGradient: AngularGradient {
        AngularGradient(
            colors: [tierColor.opacity(0.5), tierColor],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
    
    private var tierProgress: Double {
        switch tier {
        case .thriving: return 1.0
        case .balanced: return 0.8
        case .steady: return 0.6
        case .learning: return 0.4
        case .resetting: return 0.25
        }
    }
}

// MARK: - Preview

#Preview("Thriving") {
    MetabolicVibeIndicator(tier: .thriving)
        .padding()
}

#Preview("Learning") {
    MetabolicVibeIndicator(tier: .learning)
        .padding()
}

#Preview("Resetting") {
    MetabolicVibeIndicator(tier: .resetting)
        .padding()
}
