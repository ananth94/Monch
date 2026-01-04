//
//  RiverSplineView.swift
//  monch
//
//  Organic spline river that flows behind timeline items.
//  Studio Ghibli-inspired watercolor aesthetic with:
//  - Catmull-Rom spline interpolation
//  - Watercolor texture overlay
//  - Feathered edges
//  - Animated sparkles
//  - Scroll parallax support
//

import SwiftUI

/// Canvas-based organic river spline that flows behind timeline items
struct RiverSplineView: View {
    /// Number of timeline items (affects spline length)
    let itemCount: Int
    
    /// Current mascot mood (affects gradient colors)
    let mood: MascotMoodState
    
    /// Geometry proxy from parent for sizing
    let geometry: GeometryProxy
    
    /// Optional scroll offset for parallax effect (0.8x scroll speed)
    var scrollOffset: CGFloat = 0
    
    /// Animation phase for sparkle timing
    @State private var animationPhase: CGFloat = 0
    
    /// Timer for sparkle animation
    @State private var animationTimer: Timer?
    
    /// Respect reduce motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Base river canvas
            Canvas { context, size in
                drawRiver(context: context, size: size, phase: animationPhase)
            }
            
            // Watercolor texture overlay
            Image("river_texture")
                .resizable(resizingMode: .tile)
                .opacity(0.08)
                .blendMode(.overlay)
                .allowsHitTesting(false)
            
            // Animated sparkles layer
            Canvas { context, size in
                drawSparkles(context: context, size: size, phase: animationPhase)
            }
        }
        .offset(y: scrollOffset * 0.2) // River scrolls at 0.8x (1.0 - 0.2 = 0.8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        guard !reduceMotion else {
            animationPhase = 0.5
            return
        }
        
        // Update phase at 30fps for smooth sparkle animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            animationPhase = CGFloat(Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4.0) / 4.0)
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - River Drawing
    
    private func drawRiver(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        let controlPoints = generateControlPoints(size: size, phase: phase)
        guard controlPoints.count >= 4 else { return }
        
        // Create smooth spline path using Catmull-Rom
        let centerPath = createCatmullRomPath(points: controlPoints)
        
        // Draw river with variable width (~40pt at edges, ~80pt in middle)
        let riverPath = createVariableWidthRiver(from: centerPath, size: size)
        
        // Create gradient based on mood
        let gradient = createMoodGradient(size: size)
        
        // Layer 1: Outer feathered glow (bleeding edge effect)
        var blurContext = context
        blurContext.addFilter(.blur(radius: 24))
        blurContext.opacity = 0.5
        blurContext.fill(riverPath, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: size.width / 2, y: 0),
            endPoint: CGPoint(x: size.width / 2, y: size.height)
        ))
        
        // Layer 2: Mid feather
        var midBlurContext = context
        midBlurContext.addFilter(.blur(radius: 12))
        midBlurContext.opacity = 0.7
        midBlurContext.fill(riverPath, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: size.width / 2, y: 0),
            endPoint: CGPoint(x: size.width / 2, y: size.height)
        ))
        
        // Layer 3: Core river fill
        context.fill(riverPath, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: size.width / 2, y: 0),
            endPoint: CGPoint(x: size.width / 2, y: size.height)
        ))
        
        // Layer 4: Inner highlight for depth
        var highlightContext = context
        highlightContext.opacity = 0.15
        let innerPath = createVariableWidthRiver(from: centerPath, size: size, widthMultiplier: 0.6)
        highlightContext.fill(innerPath, with: .color(.white))
    }
    
    // MARK: - Control Points Generation
    
    private func generateControlPoints(size: CGSize, phase: CGFloat) -> [CGPoint] {
        let centerX = size.width / 2
        let verticalSpacing: CGFloat = 100
        
        // Calculate number of control points based on screen height
        let pointCount = max(8, Int(size.height / verticalSpacing) + 4)
        
        var points: [CGPoint] = []
        
        for i in 0..<pointCount {
            let y = CGFloat(i) * verticalSpacing - 50 // Start slightly above screen
            
            // Gentle sway animation (±2pt as per spec)
            let swayOffset = sin(phase * .pi * 2 + CGFloat(i) * 0.5) * 2
            
            // Meandering wave pattern
            let waveAmplitude: CGFloat = 35 + swayOffset
            let frequency: CGFloat = 0.7
            
            // Alternate left/right with smooth sine wave
            let xOffset = sin(CGFloat(i) * frequency) * waveAmplitude
            
            points.append(CGPoint(x: centerX + xOffset, y: y))
        }
        
        return points
    }
    
    // MARK: - Catmull-Rom Spline
    
    private func createCatmullRomPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 4 else { return path }
        
        path.move(to: points[0])
        
        // Catmull-Rom spline interpolation
        for i in 0..<(points.count - 1) {
            let p0 = points[max(0, i - 1)]
            let p1 = points[i]
            let p2 = points[min(points.count - 1, i + 1)]
            let p3 = points[min(points.count - 1, i + 2)]
            
            // Generate intermediate points for smooth curve
            let segments = 20
            for t in 1...segments {
                let t_norm = CGFloat(t) / CGFloat(segments)
                let point = catmullRomPoint(p0: p0, p1: p1, p2: p2, p3: p3, t: t_norm)
                path.addLine(to: point)
            }
        }
        
        return path
    }
    
    /// Catmull-Rom spline interpolation formula
    private func catmullRomPoint(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t
        
        let x = 0.5 * (
            (2 * p1.x) +
            (-p0.x + p2.x) * t +
            (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
            (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3
        )
        
        let y = 0.5 * (
            (2 * p1.y) +
            (-p0.y + p2.y) * t +
            (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
            (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3
        )
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Variable Width River
    
    private func createVariableWidthRiver(
        from centerPath: Path,
        size: CGSize,
        widthMultiplier: CGFloat = 1.0
    ) -> Path {
        var riverPath = Path()
        
        // Get all points from the center path
        var centerPoints: [CGPoint] = []
        centerPath.forEach { element in
            switch element {
            case .move(to: let point):
                centerPoints.append(point)
            case .line(to: let point):
                centerPoints.append(point)
            default:
                break
            }
        }
        
        guard centerPoints.count >= 2 else { return riverPath }
        
        // Create left and right edge points with variable width
        // Width: ~40pt at edges, ~80pt in middle (per spec)
        var leftEdge: [CGPoint] = []
        var rightEdge: [CGPoint] = []
        
        for (index, point) in centerPoints.enumerated() {
            // Variable width: wider in middle of screen (60-120pt range for visibility)
            let normalizedY = point.y / size.height
            let widthFactor = 0.5 + 0.5 * sin(normalizedY * .pi) // 0.5 to 1.0
            let baseWidth: CGFloat = 60 + 60 * widthFactor // 60 to 120
            let width = baseWidth * widthMultiplier
            
            // Calculate perpendicular direction
            let tangent: CGPoint
            if index == 0 {
                tangent = CGPoint(
                    x: centerPoints[1].x - point.x,
                    y: centerPoints[1].y - point.y
                )
            } else if index == centerPoints.count - 1 {
                tangent = CGPoint(
                    x: point.x - centerPoints[index - 1].x,
                    y: point.y - centerPoints[index - 1].y
                )
            } else {
                tangent = CGPoint(
                    x: centerPoints[index + 1].x - centerPoints[index - 1].x,
                    y: centerPoints[index + 1].y - centerPoints[index - 1].y
                )
            }
            
            let length = sqrt(tangent.x * tangent.x + tangent.y * tangent.y)
            guard length > 0 else { continue }
            
            let perpendicular = CGPoint(
                x: -tangent.y / length,
                y: tangent.x / length
            )
            
            leftEdge.append(CGPoint(
                x: point.x + perpendicular.x * width / 2,
                y: point.y + perpendicular.y * width / 2
            ))
            
            rightEdge.append(CGPoint(
                x: point.x - perpendicular.x * width / 2,
                y: point.y - perpendicular.y * width / 2
            ))
        }
        
        // Build closed river path
        guard !leftEdge.isEmpty else { return riverPath }
        
        riverPath.move(to: leftEdge[0])
        for point in leftEdge.dropFirst() {
            riverPath.addLine(to: point)
        }
        
        for point in rightEdge.reversed() {
            riverPath.addLine(to: point)
        }
        
        riverPath.closeSubpath()
        
        return riverPath
    }
    
    // MARK: - Mood Gradient
    
    private func createMoodGradient(size: CGSize) -> Gradient {
        // Base: Sage → Periwinkle with mood tinting
        switch mood {
        case .neutral, .digesting:
            // Base gradient (Sage → Periwinkle)
            return Gradient(colors: [
                Color.Monch.sage.opacity(0.6),
                Color.Monch.periwinkle.opacity(0.6)
            ])
        case .spiking:
            // Warmer tint (+15% Coral overlay)
            return Gradient(colors: [
                Color.Monch.sage.opacity(0.5),
                Color.Monch.coral.opacity(0.45),
                Color.Monch.periwinkle.opacity(0.5)
            ])
        case .crashing:
            // Cooler tint (+10% Lavender)
            return Gradient(colors: [
                Color.Monch.lavender.opacity(0.6),
                Color.Monch.periwinkle.opacity(0.65)
            ])
        case .strong:
            // Brighter saturation (+10%)
            return Gradient(colors: [
                Color.Monch.sage.opacity(0.7),
                Color.Monch.periwinkle.opacity(0.65)
            ])
        case .sleepy:
            // Deeper Periwinkle, less Sage
            return Gradient(colors: [
                Color.Monch.periwinkle.opacity(0.65),
                Color.Monch.lavender.opacity(0.6)
            ])
        case .hungry:
            return Gradient(colors: [
                Color.Monch.cream.opacity(0.5),
                Color.Monch.sage.opacity(0.5)
            ])
        }
    }
    
    // MARK: - Sparkles (Sunlight catching water)
    
    private func drawSparkles(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        // Spec: Occasional tiny white circles (2-4pt) with fade in/out
        let sparkleCount = 12
        
        for i in 0..<sparkleCount {
            // Staggered timing for each sparkle
            let sparklePhase = (phase + CGFloat(i) / CGFloat(sparkleCount)).truncatingRemainder(dividingBy: 1.0)
            
            // Fade in (0.3s), hold (0.5s), fade out (0.3s) = 1.1s cycle
            // Normalized: 0-0.27 fade in, 0.27-0.73 hold, 0.73-1.0 fade out
            let opacity: Double
            if sparklePhase < 0.27 {
                opacity = Double(sparklePhase / 0.27) * 0.5
            } else if sparklePhase < 0.73 {
                opacity = 0.5
            } else {
                opacity = Double(1.0 - (sparklePhase - 0.73) / 0.27) * 0.5
            }
            
            guard opacity > 0.05 else { continue }
            
            // Deterministic but varied positions along river
            let seed = Double(i) * 137.5 // Golden angle for distribution
            let x = size.width * 0.5 + CGFloat(sin(seed) * 25)
            let y = size.height * CGFloat(i) / CGFloat(sparkleCount) + CGFloat(cos(seed) * 20)
            
            // Size: 2-4pt per spec
            let sparkleSize: CGFloat = 2 + CGFloat(sin(seed * 2)) * 2
            let sparkleRect = CGRect(
                x: x - sparkleSize / 2,
                y: y - sparkleSize / 2,
                width: sparkleSize,
                height: sparkleSize
            )
            
            context.fill(
                Circle().path(in: sparkleRect),
                with: .color(.white.opacity(opacity))
            )
        }
    }
}

// MARK: - Preview

#Preview("River - Neutral") {
    GeometryReader { geometry in
        ZStack {
            Color.Monch.cream.ignoresSafeArea()
            RiverSplineView(itemCount: 5, mood: .neutral, geometry: geometry)
        }
    }
}

#Preview("River - Spiking") {
    GeometryReader { geometry in
        ZStack {
            Color.Monch.cream.ignoresSafeArea()
            RiverSplineView(itemCount: 5, mood: .spiking, geometry: geometry)
        }
    }
}
