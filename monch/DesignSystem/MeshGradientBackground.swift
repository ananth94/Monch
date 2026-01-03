//
//  MeshGradientBackground.swift
//  monch
//
//  iOS 18 MeshGradient backgrounds for the three metabolic "mood" loops.
//  Provides organic, watercolor-like gradients that respond to app context.
//

import SwiftUI

/// The three metabolic insight loops, plus neutral state
enum GradientMood: String, CaseIterable {
    case acute    // Coral → Peach (Sugar spikes, immediate response)
    case recovery // Sage → Mint (Post-workout, anabolic window)
    case sleep    // Periwinkle → Lavender (Circadian, digestion debt)
    case neutral  // Cream/Midnight based on color scheme
}

/// Fluid mesh gradient background that adapts to metabolic context
struct MeshGradientBackground: View {
    let mood: GradientMood
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch mood {
        case .acute:
            acuteGradient
        case .recovery:
            recoveryGradient
        case .sleep:
            sleepGradient
        case .neutral:
            neutralBackground
        }
    }
    
    // MARK: - Gradient Definitions
    
    private var acuteGradient: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color.Monch.coral,       Color.Monch.peach,        Color.Monch.coral.opacity(0.8),
                Color.Monch.peach,       Color.Monch.coral,        Color.Monch.peach,
                Color.Monch.coral.opacity(0.9), Color.Monch.peach, Color.Monch.coral
            ]
        )
        .ignoresSafeArea()
    }
    
    private var recoveryGradient: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color.Monch.sage,        Color.Monch.mint,         Color.Monch.sage.opacity(0.8),
                Color.Monch.mint,        Color.Monch.sage,         Color.Monch.mint,
                Color.Monch.sage.opacity(0.9), Color.Monch.mint,   Color.Monch.sage
            ]
        )
        .ignoresSafeArea()
    }
    
    private var sleepGradient: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color.Monch.periwinkle,  Color.Monch.lavender,     Color.Monch.periwinkle.opacity(0.8),
                Color.Monch.lavender,    Color.Monch.periwinkle,   Color.Monch.lavender,
                Color.Monch.periwinkle.opacity(0.9), Color.Monch.lavender, Color.Monch.periwinkle
            ]
        )
        .ignoresSafeArea()
    }
    
    private var neutralBackground: some View {
        Group {
            if colorScheme == .dark {
                Color.Monch.midnightNavy
            } else {
                Color.Monch.cream
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Animated Variant

/// Animated mesh gradient with subtle movement for "alive" feel
struct AnimatedMeshGradientBackground: View {
    let mood: GradientMood
    @State private var animationPhase: Double = 0
    
    var body: some View {
        MeshGradientBackground(mood: mood)
            .hueRotation(.degrees(animationPhase))
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animationPhase = 5
                }
            }
    }
}

// MARK: - Previews

#Preview("Acute (Sugar Spike)") {
    MeshGradientBackground(mood: .acute)
}

#Preview("Recovery (Anabolic)") {
    MeshGradientBackground(mood: .recovery)
}

#Preview("Sleep (Circadian)") {
    MeshGradientBackground(mood: .sleep)
}

#Preview("Neutral (Light)") {
    MeshGradientBackground(mood: .neutral)
        .environment(\.colorScheme, .light)
}

#Preview("Neutral (Dark)") {
    MeshGradientBackground(mood: .neutral)
        .environment(\.colorScheme, .dark)
}
