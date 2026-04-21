//
//  EmptyTimelineView.swift
//  monch
//
//  River UI empty state with peaceful river and ambient life.
//  Features floating lily pads, fish blips, and dragonfly fly-across.
//

import SwiftUI

struct EmptyTimelineView: View {
    var onLogMeal: () -> Void
    
    @State private var isAnimating = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ambient River Layer
                RiverSplineView(
                    itemCount: 0,
                    mood: .hungry,
                    geometry: geometry
                )
                
                // Ambient Creatures Layer
                RiverAmbientLayer(size: geometry.size)
                
                // Main Content
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Hungry Monch on riverbank
                    Image("monch_hungry")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .opacity(0.8)
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // River-themed copy
                    VStack(spacing: 8) {
                        Text("The river is quiet...")
                            .font(.Monch.title2)
                            .multilineTextAlignment(.center)
                        
                        Text("Log your first meal event to start your journey")
                            .font(.Monch.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
                    // CTA Button
                    Button(action: onLogMeal) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Meal Event")
                        }
                        .font(.Monch.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.Monch.sage)
                        )
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - River Ambient Layer

struct RiverAmbientLayer: View {
    let size: CGSize
    
    @State private var dragonFlyOffset: CGFloat = -100
    @State private var showDragonfly = false
    @State private var lilyPads: [LilyPadState] = []
    @State private var fishBlips: [FishBlipState] = []
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Lily Pads (gentle float)
            ForEach(lilyPads) { lilyPad in
                LilyPadView(state: lilyPad)
            }
            
            // Fish Blips (random appear/disappear)
            ForEach(fishBlips) { blip in
                FishBlipView(state: blip)
            }
            
            // Dragonfly (fly across every 30s)
            if showDragonfly {
                Image("dragonfly")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .offset(x: dragonFlyOffset, y: size.height * 0.3)
            }
        }
        .onAppear {
            setupAmbientLife()
            startDragonflyLoop()
        }
        .allowsHitTesting(false)
    }
    
    private func setupAmbientLife() {
        guard !reduceMotion else { return }
        
        // Generate 1-2 lily pads at random positions
        lilyPads = (0..<2).map { i in
            LilyPadState(
                id: UUID(),
                position: CGPoint(
                    x: size.width * 0.3 + CGFloat(i) * size.width * 0.4,
                    y: size.height * 0.4 + CGFloat.random(in: -50...50)
                ),
                scale: 0.8 + CGFloat.random(in: 0...0.4),
                hasFlower: i == 0
            )
        }
        
        // Start fish blip timer
        startFishBlips()
    }
    
    private func startFishBlips() {
        guard !reduceMotion else { return }
        
        // Random fish blip every 3-6 seconds
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
            let blip = FishBlipState(
                id: UUID(),
                position: CGPoint(
                    x: size.width * CGFloat.random(in: 0.3...0.7),
                    y: size.height * CGFloat.random(in: 0.3...0.7)
                )
            )
            
            withAnimation(.easeOut(duration: 0.3)) {
                fishBlips.append(blip)
            }
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.3)) {
                    fishBlips.removeAll { $0.id == blip.id }
                }
            }
        }
    }
    
    private func startDragonflyLoop() {
        guard !reduceMotion else { return }
        
        // Dragonfly loops across every 30s
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            dragonFlyOffset = -100
            showDragonfly = true
            
            withAnimation(.linear(duration: 4)) {
                dragonFlyOffset = size.width + 100
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showDragonfly = false
            }
        }
    }
}

// MARK: - Lily Pad View

struct LilyPadView: View {
    let state: LilyPadState
    
    @State private var floatOffset: CGFloat = 0
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            Image("lily_pad")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            if state.hasFlower {
                Image("lily_flower")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .offset(y: -8)
            }
        }
        .scaleEffect(state.scale)
        .position(state.position)
        .offset(y: floatOffset)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatOffset = 5
            }
        }
    }
}

// MARK: - Fish Blip View

struct FishBlipView: View {
    let state: FishBlipState
    
    @State private var scale: CGFloat = 0.5
    @State private var wiggle: CGFloat = 0
    
    var body: some View {
        Image("fish_blip")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .scaleEffect(scale)
            .rotationEffect(.degrees(wiggle))
            .position(state.position)
            .onAppear {
                // Appear animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
                
                // Wiggle
                withAnimation(.easeInOut(duration: 0.15).repeatCount(3, autoreverses: true)) {
                    wiggle = 10
                }
                
                // Disappear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        scale = 0
                    }
                }
            }
    }
}

// MARK: - State Types

struct LilyPadState: Identifiable {
    let id: UUID
    let position: CGPoint
    let scale: CGFloat
    let hasFlower: Bool
}

struct FishBlipState: Identifiable {
    let id: UUID
    let position: CGPoint
}

// MARK: - Preview

#Preview {
    EmptyTimelineView {
        print("Log meal tapped")
    }
    .background(Color.Monch.cream)
}
