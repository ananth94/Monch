//
//  Typography.swift
//  monch
//
//  Design System Typography - SF Pro Rounded
//

import SwiftUI

/// Typography tokens for the Monch design system.
/// Uses SF Pro Rounded for a friendly, approachable feel.
enum MonchFont {
    /// 34pt Heavy - Hero numbers, primary data values
    static let largeTitle = Font.system(size: 34, weight: .heavy, design: .rounded)
    
    /// 28pt Bold - Screen titles
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    
    /// 22pt Bold - Section headers
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    
    /// 20pt Semibold - Card titles
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    /// 17pt Semibold - Emphasized body text
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    
    /// 17pt Medium - Primary content
    static let body = Font.system(size: 17, weight: .medium, design: .rounded)
    
    /// 16pt Medium - Supporting text
    static let callout = Font.system(size: 16, weight: .medium, design: .rounded)
    
    /// 15pt Regular - Metadata
    static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
    
    /// 13pt Regular - Timestamps, labels
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    
    /// 12pt Regular - Tertiary info
    static let caption1 = Font.system(size: 12, weight: .regular, design: .rounded)
    
    /// 11pt Medium - Badges, tags
    static let caption2 = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - Dynamic Type Support
extension MonchFont {
    /// Large title with Dynamic Type scaling
    static var largeTitleScaled: Font {
        .system(.largeTitle, design: .rounded, weight: .heavy)
    }
    
    /// Title 1 with Dynamic Type scaling
    static var title1Scaled: Font {
        .system(.title, design: .rounded, weight: .bold)
    }
    
    /// Title 2 with Dynamic Type scaling
    static var title2Scaled: Font {
        .system(.title2, design: .rounded, weight: .bold)
    }
    
    /// Title 3 with Dynamic Type scaling
    static var title3Scaled: Font {
        .system(.title3, design: .rounded, weight: .semibold)
    }
    
    /// Headline with Dynamic Type scaling
    static var headlineScaled: Font {
        .system(.headline, design: .rounded, weight: .semibold)
    }
    
    /// Body with Dynamic Type scaling
    static var bodyScaled: Font {
        .system(.body, design: .rounded, weight: .medium)
    }
    
    /// Callout with Dynamic Type scaling
    static var calloutScaled: Font {
        .system(.callout, design: .rounded, weight: .medium)
    }
    
    /// Subheadline with Dynamic Type scaling
    static var subheadlineScaled: Font {
        .system(.subheadline, design: .rounded, weight: .regular)
    }
    
    /// Footnote with Dynamic Type scaling
    static var footnoteScaled: Font {
        .system(.footnote, design: .rounded, weight: .regular)
    }
    
    /// Caption with Dynamic Type scaling
    static var captionScaled: Font {
        .system(.caption, design: .rounded, weight: .regular)
    }
    
    /// Caption 2 with Dynamic Type scaling
    static var caption2Scaled: Font {
        .system(.caption2, design: .rounded, weight: .medium)
    }
}

// MARK: - Text Style Modifier
extension Text {
    /// Apply Monch typography style with consistent lowercase headers
    func monchStyle(_ font: Font, lowercase: Bool = false) -> Text {
        if lowercase {
            return self.font(font).textCase(.lowercase)
        }
        return self.font(font)
    }
}
