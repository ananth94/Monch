//
//  MascotHeader.swift
//  monch
//
//  Header component displaying Monch mascot with current metabolic state.
//  Uses actual image assets from Assets.xcassets/Monch/InApp/
//

import SwiftUI

/// Monch's emotional states matching the mascot assets
enum MascotMoodState: String, CaseIterable {
    case neutral    // Default calm state
    case spiking    // Sugar spike detected
    case crashing   // Hypoglycemia / energy crash
    case hungry     // Long time since last meal
    case sleepy     // Evening / circadian window
    case strong     // Post-workout / anabolic
    case digesting  // Recent large meal
    
    /// Asset name in Assets.xcassets
    var assetName: String {
        "monch_\(rawValue)"
    }
    
    /// 8-bit version for notifications/Live Island
    var assetName8Bit: String {
        "monch_8bit_\(rawValue)"
    }
    
    /// Descriptive text for the mascot state
    var statusText: String {
        switch self {
        case .neutral: return "Monch is calm"
        case .spiking: return "Monch is buzzing!"
        case .crashing: return "Monch is melting..."
        case .hungry: return "Monch is hungry"
        case .sleepy: return "Monch is sleepy"
        case .strong: return "Monch is powered up!"
        case .digesting: return "Monch is full"
        }
    }
    
    /// Prompt text for the user
    var promptText: String {
        switch self {
        case .neutral: return "Ready to log?"
        case .spiking: return "A walk could help"
        case .crashing: return "Grab a snack?"
        case .hungry: return "Time to eat?"
        case .sleepy: return "Kitchen closing soon"
        case .strong: return "Fuel those muscles!"
        case .digesting: return "Digesting..."
        }
    }
    
    /// Background gradient mood for the header
    var gradientMood: GradientMood {
        switch self {
        case .neutral, .hungry, .digesting: return .neutral
        case .spiking, .crashing: return .acute
        case .strong: return .recovery
        case .sleepy: return .sleep
        }
    }
}

struct MascotHeader: View {
    /// Current mascot mood - will be bound to MascotStateManager
    var mood: MascotMoodState = .neutral
    
    /// Callback when header is tapped
    var onTap: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Mascot Image
                mascotImage
                
                // Status Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.statusText)
                        .font(.Monch.headline)
                        .foregroundStyle(.primary)
                    
                    Text(mood.promptText)
                        .font(.Monch.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(headerBackground)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews
    
    private var mascotImage: some View {
        Image(mood.assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 64, height: 64)
            .scaleEffect(isAnimating && mood == .spiking ? 1.05 : 1.0)
            .animation(
                mood == .spiking 
                    ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true)
                    : .default,
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
    
    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(backgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var backgroundGradient: some ShapeStyle {
        switch mood.gradientMood {
        case .acute:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.Monch.coral.opacity(0.3), Color.Monch.peach.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .recovery:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.Monch.sage.opacity(0.3), Color.Monch.mint.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .sleep:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.Monch.periwinkle.opacity(0.3), Color.Monch.lavender.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .neutral:
            return AnyShapeStyle(Color.primary.opacity(0.05))
        }
    }
}

// MARK: - Previews

#Preview("Neutral") {
    MascotHeader(mood: .neutral)
        .padding()
}

#Preview("Spiking") {
    MascotHeader(mood: .spiking)
        .padding()
}

#Preview("Strong") {
    MascotHeader(mood: .strong)
        .padding()
}

#Preview("Sleepy") {
    MascotHeader(mood: .sleepy)
        .padding()
}

#Preview("All States") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(MascotMoodState.allCases, id: \.self) { mood in
                MascotHeader(mood: mood)
            }
        }
        .padding()
    }
}
