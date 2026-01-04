//
//  FirstMealCelebrationView.swift
//  monch
//
//  Celebration modal shown after user logs their first meal.
//

import SwiftUI

struct FirstMealCelebrationView: View {
    @Binding var isPresented: Bool
    @State private var animateIn = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Celebration card
            VStack(spacing: Spacing.lg) {
                // Confetti burst
                if showConfetti {
                    ConfettiView()
                        .frame(height: 100)
                }
                
                // Happy mascot
                Image("monch_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .rotationEffect(.degrees(animateIn ? 0 : -10))
                
                Text("Monch's First Bite!")
                    .font(.Monch.title)
                    .foregroundStyle(.primary)
                
                Text("I'm learning your patterns now. Keep logging and I'll start noticing things about your metabolism.")
                    .font(.Monch.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button {
                    dismiss()
                } label: {
                    Text("Let's Go!")
                        .font(.Monch.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .fill(Color.Monch.coral)
                        )
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(.regularMaterial)
            )
            .padding(Spacing.xl)
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                animateIn = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                // Haptic
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(duration: 0.3)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Simple Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
                animateParticles()
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [.Monch.coral, .Monch.sage, .Monch.periwinkle, .yellow, .orange]
        particles = (0..<30).map { _ in
            ConfettiParticle(
                position: CGPoint(x: size.width / 2, y: 0),
                color: colors.randomElement() ?? .Monch.coral,
                size: CGFloat.random(in: 4...10),
                velocity: CGPoint(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: 50...150)
                ),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.5)) {
            particles = particles.map { particle in
                var updated = particle
                updated.position = CGPoint(
                    x: particle.position.x + particle.velocity.x,
                    y: particle.position.y + particle.velocity.y
                )
                updated.opacity = 0
                return updated
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let velocity: CGPoint
    var opacity: Double
}

// MARK: - Preview

#Preview {
    FirstMealCelebrationView(isPresented: .constant(true))
}
