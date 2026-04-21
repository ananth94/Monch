//
//  StreakCard.swift
//  monch
//
//  Streak tracking card with count, progress toward personal best, and at-risk indicator.
//

import SwiftUI

struct StreakCard: View {
    let streak: Streak
    
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            MonchIconView(token: streak.type.iconToken, size: 32)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Count and type
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak.count)")
                        .font(.Monch.title2)
                        .fontWeight(.bold)
                    Text("DAYS")
                        .font(.Monch.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(streak.type.rawValue)
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.secondary.opacity(0.2))
                            .frame(height: 4)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.Monch.sage)
                            .frame(width: appeared ? geo.size.width * streak.progressTowardsBest : 0, height: 4)
                            .animation(.spring(duration: 0.8), value: appeared)
                    }
                }
                .frame(height: 4)
                
                // Personal best
                Text("Personal best: \(streak.personalBest) days")
                    .font(.Monch.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // At-risk indicator
            if streak.isAtRisk {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.Monch.coral)
                    .modifier(PulsingModifier())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(streak.isAtRisk ? Color.Monch.coral.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Pulsing Animation

private struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        StreakCard(streak: Streak(
            type: .kitchenClosed,
            count: 12,
            personalBest: 14,
            isAtRisk: false
        ))
        
        StreakCard(streak: Streak(
            type: .postWorkoutRefuel,
            count: 5,
            personalBest: 10,
            isAtRisk: true
        ))
    }
    .padding()
}
