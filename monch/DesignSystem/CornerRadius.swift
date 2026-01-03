//
//  CornerRadius.swift
//  monch
//
//  Design System Corner Radius Scale
//

import SwiftUI

/// Corner radius tokens for the "Cozy" UI.
/// Soft, rounded corners are a key part of the Monch aesthetic.
enum CornerRadius {
    /// 4pt - Badges, tags
    static let xs: CGFloat = 4
    
    /// 8pt - Buttons, small cards
    static let sm: CGFloat = 8
    
    /// 12pt - Input fields
    static let md: CGFloat = 12
    
    /// 16pt - Modals, sheets
    static let lg: CGFloat = 16
    
    /// 24pt - Timeline bubbles, insight cards
    static let xl: CGFloat = 24
    
    /// 9999pt - Pills, circular avatars
    static let full: CGFloat = 9999
}

// MARK: - View Extension for Corner Radius
extension View {
    /// Apply Monch corner radius with continuous curves
    func monchCornerRadius(_ radius: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
    
    /// Apply Monch corner radius with a background
    func monchCard(
        radius: CGFloat = CornerRadius.xl,
        backgroundColor: Color = .white
    ) -> some View {
        self
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
