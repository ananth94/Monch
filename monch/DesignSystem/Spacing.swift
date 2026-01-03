//
//  Spacing.swift
//  monch
//
//  Design System Spacing - 8pt Base Grid
//

import SwiftUI

/// Spacing tokens based on an 8pt grid system.
/// All spacing should be multiples of 4pt, preferring 8pt increments.
enum Spacing {
    /// 2pt - Hairline gaps
    static let xxs: CGFloat = 2
    
    /// 4pt - Icon-to-label gaps, tight padding
    static let xs: CGFloat = 4
    
    /// 8pt - Default padding, inline spacing
    static let sm: CGFloat = 8
    
    /// 16pt - Card padding, section gaps
    static let md: CGFloat = 16
    
    /// 24pt - Section separators
    static let lg: CGFloat = 24
    
    /// 32pt - Screen margins
    static let xl: CGFloat = 32
    
    /// 48pt - Hero spacing
    static let xxl: CGFloat = 48
}

// MARK: - View Extension for Padding
extension View {
    /// Apply Monch spacing as padding
    func monchPadding(_ spacing: CGFloat) -> some View {
        self.padding(spacing)
    }
    
    /// Apply Monch spacing as horizontal padding
    func monchHPadding(_ spacing: CGFloat) -> some View {
        self.padding(.horizontal, spacing)
    }
    
    /// Apply Monch spacing as vertical padding
    func monchVPadding(_ spacing: CGFloat) -> some View {
        self.padding(.vertical, spacing)
    }
}
