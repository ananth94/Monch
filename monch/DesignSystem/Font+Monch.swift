//
//  Font+Monch.swift
//  monch
//
//  Typography tokens for the "Cozy Science" design system.
//  SF Pro Rounded with chunky weights for a friendly feel.
//

import SwiftUI

extension Font {
    struct Monch {
        // MARK: - Headers (lowercase, chunky)
        
        /// Large title for major screens - SF Pro Rounded Heavy
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.heavy)
        
        /// Primary title - SF Pro Rounded Bold
        static let title = Font.system(.title, design: .rounded).weight(.bold)
        
        /// Secondary title - SF Pro Rounded Bold
        static let title2 = Font.system(.title2, design: .rounded).weight(.bold)
        
        /// Tertiary title - SF Pro Rounded Semibold
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        
        // MARK: - Body Text
        
        /// Emphasized body text - SF Pro Rounded Semibold
        static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
        
        /// Standard body text - SF Pro Rounded Regular
        static let body = Font.system(.body, design: .rounded)
        
        /// Callout text for secondary info - SF Pro Rounded Regular
        static let callout = Font.system(.callout, design: .rounded)
        
        /// Subheadline for labels - SF Pro Rounded Regular
        static let subheadline = Font.system(.subheadline, design: .rounded)
        
        /// Footnote for metadata - SF Pro Rounded Regular
        static let footnote = Font.system(.footnote, design: .rounded)
        
        /// Caption for timestamps - SF Pro Rounded Regular
        static let caption = Font.system(.caption, design: .rounded)
        
        /// Smaller caption - SF Pro Rounded Regular
        static let caption2 = Font.system(.caption2, design: .rounded)
        
        // MARK: - Special Purpose
        
        /// Large numeric display (e.g., macro grams) - SF Pro Rounded Heavy
        static let numericLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
        
        /// Medium numeric display - SF Pro Rounded Bold
        static let numericMedium = Font.system(size: 32, weight: .bold, design: .rounded)
        
        /// Small numeric display - SF Pro Rounded Semibold
        static let numericSmall = Font.system(size: 20, weight: .semibold, design: .rounded)
    }
}

// MARK: - View Modifier Convenience

extension View {
    /// Apply Monch headline styling
    func monchHeadline() -> some View {
        self.font(.Monch.headline)
    }
    
    /// Apply Monch body styling
    func monchBody() -> some View {
        self.font(.Monch.body)
    }
    
    /// Apply Monch caption styling with secondary color
    func monchCaption() -> some View {
        self
            .font(.Monch.caption)
            .foregroundStyle(.secondary)
    }
}
