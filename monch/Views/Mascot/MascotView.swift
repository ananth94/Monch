//
//  MascotView.swift
//  monch
//
//  Central mascot view that handles assets and the detailed SwiftUI animation system.
//  Implements Breathing, Floating, and State-Specific animations (Jitter, Sway, Melt, etc.)
//

import SwiftUI

struct MascotView: View {
    let mood: MascotMoodState
    let size: CGFloat
    
    // Animation States
    @State private var breathingScale: CGFloat = 1.0
    @State private var floatingOffset: CGFloat = 0.0
    @State private var jitterOffset: CGSize = .zero
    @State private var swayRotation: Double = 0.0
    @State private var meltSlump: CGFloat = 0.0
    @State private var meltSaturation: Double = 1.0
    @State private var powerScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Glow / Aura Overlays
            glowOverlay
            
            // Base Mascot Asset
            Image(mood.assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .saturation(meltSaturation)
                .scaleEffect(breathingScale * powerScale)
                .rotationEffect(.degrees(swayRotation))
                .offset(x: jitterOffset.width, y: floatingOffset + jitterOffset.height + meltSlump)
        }
        .onAppear {
            startBaseAnimations()
            applyStateSpecificAnimations()
        }
        .onChange(of: mood) { _, _ in
            applyStateSpecificAnimations()
        }
    }
    
    // MARK: - Overlays
    
    @ViewBuilder
    private var glowOverlay: some View {
        if mood == .spiking {
            Circle()
                .fill(Color.Monch.coral)
                .blur(radius: size * 0.4)
                .opacity(0.3)
                .frame(width: size, height: size)
        } else if mood == .strong {
            Circle()
                .fill(Color.Monch.sage)
                .blur(radius: size * 0.4)
                .opacity(0.3)
                .frame(width: size, height: size)
        }
    }
    
    // MARK: - Animation Logic
    
    private func startBaseAnimations() {
        // Breathing: 1.0 to 1.02 over 2.5s
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breathingScale = 1.02
        }
        
        // Floating: 2pt oscillation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            floatingOffset = -2
        }
    }
    
    private func applyStateSpecificAnimations() {
        // Reset state-specific values
        withAnimation(.spring()) {
            jitterOffset = .zero
            swayRotation = 0
            meltSlump = 0
            meltSaturation = 1.0
            powerScale = 1.0
        }
        
        switch mood {
        case .hungry:
            // Eager Bounce: 1s repeating hop
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                floatingOffset = -8
            }
            
        case .digesting:
            // Content Sway: Slow rotation
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                swayRotation = 5
            }
            
        case .spiking:
            // Jitter/Vibration: High frequency
            withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.1).repeatForever()) {
                jitterOffset = CGSize(width: 2, height: 1)
            }
            
        case .crashing:
            // The "Melt": Slump + desaturate
            withAnimation(.easeIn(duration: 2.0)) {
                meltSlump = size * 0.05
                meltSaturation = 0.6
            }
            
        case .sleepy:
            // The "Nod": Head-heavy rotation + slow breath
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                swayRotation = 10
            }
            
        case .strong:
            // Power Pulse: 1.1x scale expansion
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                powerScale = 1.1
            }
            
        case .neutral:
            break
        }
    }
}

#Preview("Small - Spiking") {
    MascotView(mood: .spiking, size: 64)
}

#Preview("Large - Strong") {
    MascotView(mood: .strong, size: 200)
}

#Preview("Crashing (Melt)") {
    MascotView(mood: .crashing, size: 200)
}
