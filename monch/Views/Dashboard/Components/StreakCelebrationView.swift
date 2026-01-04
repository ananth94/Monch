//
//  StreakCelebrationView.swift
//  monch
//
//  Confetti celebration modal for streak milestones.
//  Shows celebratory animation with mascot and encouraging message.
//

import SwiftUI

struct StreakCelebrationView: View {
    let milestone: StreakMilestone
    let streakCount: Int
    let onDismiss: () -> Void
    
    @State private var confettiTrigger = false
    @State private var mascotScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Confetti Layer
            if !reduceMotion {
                StreakConfettiView(isActive: $confettiTrigger)
            }
            
            // Content Card
            VStack(spacing: Spacing.lg) {
                // Mascot Celebration
                Image("monch_celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(mascotScale)
                
                // Streak Count
                VStack(spacing: Spacing.xs) {
                    Text("\(streakCount)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.Monch.sage, Color.Monch.periwinkle],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("DAY STREAK")
                        .font(.Monch.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(2)
                }
                .opacity(textOpacity)
                
                // Celebration Message
                VStack(spacing: Spacing.sm) {
                    Text(milestone.celebrationMessage)
                        .font(.Monch.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(milestone.mascotMessage)
                        .font(.Monch.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)
                .padding(.horizontal)
                
                // Continue Button
                Button {
                    onDismiss()
                } label: {
                    Text("Keep Going!")
                        .font(.Monch.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.Monch.sage, Color.Monch.periwinkle],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .opacity(buttonOpacity)
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.xl)
            .padding(.horizontal, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.Monch.cream)
            )
            .padding(.horizontal, Spacing.lg)
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        guard !reduceMotion else {
            mascotScale = 1
            textOpacity = 1
            buttonOpacity = 1
            confettiTrigger = true
            return
        }
        
        // Trigger confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            confettiTrigger = true
        }
        
        // Mascot bounce in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            mascotScale = 1.1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                mascotScale = 1.0
            }
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            textOpacity = 1
        }
        
        // Button fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            buttonOpacity = 1
        }
    }
}

// MARK: - Streak Confetti View

struct StreakConfettiView: View {
    @Binding var isActive: Bool
    
    private let colors: [Color] = [
        Color.Monch.sage,
        Color.Monch.coral,
        Color.Monch.periwinkle,
        Color.Monch.lavender,
        .yellow,
        .orange
    ]
    
    @State private var particles: [StreakConfettiParticle] = []
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let age = Date().timeIntervalSince(particle.createdAt)
                guard age < 3.0 else { continue }
                
                let progress = age / 3.0
                let opacity = 1.0 - progress
                
                // Calculate position with gravity
                let x = particle.startX + particle.velocityX * age
                let y = particle.startY + particle.velocityY * age + (300 * age * age)
                
                // Calculate rotation
                let rotation = Angle(degrees: particle.rotation + particle.rotationSpeed * age * 360)
                
                // Draw particle
                context.opacity = opacity
                context.translateBy(x: x, y: y)
                context.rotate(by: rotation)
                
                let rect = CGRect(x: -4, y: -4, width: 8, height: 8)
                context.fill(
                    RoundedRectangle(cornerRadius: 2).path(in: rect),
                    with: .color(particle.color)
                )
                
                context.rotate(by: -rotation)
                context.translateBy(x: -x, y: -y)
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                spawnConfetti()
            }
        }
    }
    
    private func spawnConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        
        for _ in 0..<60 {
            let particle = StreakConfettiParticle(
                startX: screenWidth / 2 + CGFloat.random(in: -50...50),
                startY: -20,
                velocityX: CGFloat.random(in: -150...150),
                velocityY: CGFloat.random(in: 100...300),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 0.5...2),
                color: colors.randomElement() ?? .yellow,
                createdAt: Date()
            )
            particles.append(particle)
        }
        
        // Cleanup old particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            particles.removeAll()
        }
    }
}

// MARK: - Streak Confetti Particle

private struct StreakConfettiParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let color: Color
    let createdAt: Date
}

// MARK: - Preview

#Preview("7-Day Streak") {
    StreakCelebrationView(
        milestone: .week,
        streakCount: 7,
        onDismiss: {}
    )
}

#Preview("30-Day Streak") {
    StreakCelebrationView(
        milestone: .month,
        streakCount: 30,
        onDismiss: {}
    )
}
