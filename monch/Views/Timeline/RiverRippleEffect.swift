//
//  RiverRippleEffect.swift
//  monch
//
//  Ripple effect for timeline card interactions.
//  Shows expanding circle animation on tap, concentric ripples on long-press.
//

import SwiftUI

/// Expanding ripple effect that emanates from a touch point
struct RiverRippleEffect: View {
    let position: CGPoint
    let isActive: Bool
    
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0.3
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Circle()
            .stroke(Color.white.opacity(rippleOpacity), lineWidth: 2)
            .frame(width: 240, height: 240)
            .scaleEffect(rippleScale)
            .position(position)
            .opacity(isActive ? 1 : 0)
            .onChange(of: isActive) { _, active in
                if active {
                    triggerRipple()
                } else {
                    resetRipple()
                }
            }
    }
    
    private func triggerRipple() {
        guard !reduceMotion else {
            rippleScale = 1
            rippleOpacity = 0
            return
        }
        
        rippleScale = 0
        rippleOpacity = 0.3
        
        withAnimation(.easeOut(duration: 0.4)) {
            rippleScale = 1
            rippleOpacity = 0
        }
    }
    
    private func resetRipple() {
        rippleScale = 0
        rippleOpacity = 0
    }
}

/// Modifier to add tap ripple effect to any view
struct RippleEffectModifier: ViewModifier {
    @State private var ripplePosition: CGPoint = .zero
    @State private var showRipple = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    RiverRippleEffect(position: ripplePosition, isActive: showRipple)
                        .onTapGesture { location in
                            ripplePosition = location
                            showRipple = true
                            
                            // Auto-hide after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showRipple = false
                            }
                        }
                        .allowsHitTesting(false)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        ripplePosition = value.location
                        if !showRipple {
                            showRipple = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showRipple = false
                            }
                        }
                    }
            )
    }
}

/// Long-press concentric ripples effect
struct ConcentricRipplesEffect: View {
    let position: CGPoint
    let isActive: Bool
    
    @State private var ripples: [RippleState] = []
    @State private var timer: Timer?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            ForEach(ripples) { ripple in
                Circle()
                    .stroke(Color.white.opacity(ripple.opacity), lineWidth: 1.5)
                    .frame(width: 120, height: 120)
                    .scaleEffect(ripple.scale)
                    .position(position)
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                startRipples()
            } else {
                stopRipples()
            }
        }
    }
    
    private func startRipples() {
        guard !reduceMotion else { return }
        
        // Spawn new ripple every 0.3s, max 3
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            guard ripples.count < 3 else { return }
            
            let newRipple = RippleState()
            ripples.append(newRipple)
            
            // Animate the ripple
            withAnimation(.easeOut(duration: 0.6)) {
                if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                    ripples[index].scale = 1.5
                    ripples[index].opacity = 0
                }
            }
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                ripples.removeAll { $0.id == newRipple.id }
            }
        }
    }
    
    private func stopRipples() {
        timer?.invalidate()
        timer = nil
        ripples.removeAll()
    }
    
    struct RippleState: Identifiable {
        let id = UUID()
        var scale: CGFloat = 0.5
        var opacity: Double = 0.25
    }
}

// MARK: - View Extension

extension View {
    /// Adds a tap ripple effect to the view
    func riverRipple() -> some View {
        modifier(RippleEffectModifier())
    }
}

// MARK: - Preview

#Preview("Tap Ripple") {
    ZStack {
        Color.Monch.cream.ignoresSafeArea()
        
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .frame(width: 300, height: 100)
            .overlay {
                Text("Tap me!")
            }
            .riverRipple()
    }
}
