//
//  RiverCardStyle.swift
//  monch
//
//  Styling modifiers for timeline cards to match River UI aesthetic.
//  Creates organic "stepping stone" appearance with:
//  - Asymmetric corner radii (organic hand-drawn feel)
//  - Alternating left/right positioning with slight rotation
//  - Dual watercolor bleeding shadows
//

import SwiftUI

// MARK: - Asymmetric Corner Shape

/// A rounded rectangle with different corner radii for organic feel
struct AsymmetricRoundedRectangle: Shape {
    var topLeading: CGFloat
    var topTrailing: CGFloat
    var bottomLeading: CGFloat
    var bottomTrailing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top-left, going clockwise
        path.move(to: CGPoint(x: rect.minX + topLeading, y: rect.minY))
        
        // Top edge to top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - topTrailing, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + topTrailing),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        
        // Right edge to bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailing))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - bottomTrailing, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        
        // Bottom edge to bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + bottomLeading, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeading),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        
        // Left edge to top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeading))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topLeading, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - River Card Style Modifier

struct RiverCardStyleModifier: ViewModifier {
    /// Index of card in timeline (affects position/rotation)
    let index: Int
    
    /// Card type for accent coloring
    let cardType: RiverCardType
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// Spec: Odd items -8pt left, Even items +8pt right
    private var horizontalOffset: CGFloat {
        reduceMotion ? 0 : (index.isMultiple(of: 2) ? 8 : -8)
    }
    
    /// Spec: Odd -1° to -2°, Even +1° to +2°
    private var rotation: Angle {
        guard !reduceMotion else { return .zero }
        let baseAngle = index.isMultiple(of: 2) ? 1.0 : -1.0
        let variance = Double((index * 7) % 10) / 10.0 // 0.0 to 0.9
        return .degrees(baseAngle * (1.0 + variance))
    }
    
    /// Asymmetric corners per spec: 24/22/20/26
    private var cornerShape: AsymmetricRoundedRectangle {
        AsymmetricRoundedRectangle(
            topLeading: 24,
            topTrailing: 22,
            bottomLeading: 20,
            bottomTrailing: 26
        )
    }
    
    func body(content: Content) -> some View {
        content
            // Apply background FIRST, before clipping
            .background(cardBackgroundColor)
            .clipShape(cornerShape)
            // Dual watercolor bleeding shadows per spec
            .shadow(color: Color.Monch.sage.opacity(0.2), radius: 16, x: 0, y: 8)
            .shadow(color: Color.Monch.periwinkle.opacity(0.15), radius: 24, x: 0, y: 12)
            // Alternating position and rotation
            .offset(x: horizontalOffset)
            .rotationEffect(rotation)
            // Note: Ripple effect removed - was breaking tap gestures
    }
    
    private var cardBackgroundColor: Color {
        switch cardType {
        case .meal:
            // Solid cream for dark text readability
            return Color.Monch.cream
        case .insight:
            return Color.white
        case .workout:
            // Light sage tint
            return Color(red: 0.92, green: 0.96, blue: 0.93)
        case .sleep:
            // Light periwinkle tint
            return Color(red: 0.93, green: 0.93, blue: 0.98)
        case .vibe:
            return Color.white.opacity(0.95)
        }
    }
}

// MARK: - Card Types

enum RiverCardType {
    case meal
    case insight
    case workout
    case sleep
    case vibe
}

// MARK: - View Extension

extension View {
    /// Applies River UI card styling with organic corners, shadows, and positioning
    func riverCardStyle(index: Int, type: RiverCardType) -> some View {
        modifier(RiverCardStyleModifier(index: index, cardType: type))
    }
}

// MARK: - Preview

#Preview("River Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { index in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Card \(index)")
                            .font(.headline)
                        Text("This is a sample card")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .riverCardStyle(index: index, type: index % 2 == 0 ? .meal : .workout)
            }
        }
        .padding()
    }
    .background(Color.Monch.cream)
}
