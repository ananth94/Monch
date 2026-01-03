//
//  Color+Monch.swift
//  monch
//
//  Design System Colors - "Watercolor Mode"
//

import SwiftUI

// MARK: - Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Monch Design System Colors
extension Color {
    struct Monch {
        // MARK: - Mood: Acute / Spike (Warmth)
        /// Soft Coral - Primary spike color
        static let coral = Color(hex: "#FFA07A")
        /// Warm Peach - Secondary spike color
        static let peach = Color(hex: "#FFB7B2")
        
        // MARK: - Mood: Anabolic / Fuel (Growth)
        /// Sage Green - Primary fuel color
        static let sage = Color(hex: "#88B04B")
        /// Mint Cream - Secondary fuel color
        static let mint = Color(hex: "#F5FFFA")
        
        // MARK: - Mood: Sleep / Circadian (Dream)
        /// Periwinkle - Primary sleep color
        static let periwinkle = Color(hex: "#CCCCFF")
        /// Soft Lavender - Secondary sleep color
        static let lavender = Color(hex: "#E6E6FA")
        
        // MARK: - Backgrounds (The Canvas)
        /// Midnight Navy - Primary dark mode background
        static let midnightNavy = Color(hex: "#1A1B26")
        /// Warm Charcoal - Elevated dark surfaces
        static let warmCharcoal = Color(hex: "#2E2E2E")
        /// Cream / Paper - Primary light mode background
        static let cream = Color(hex: "#FDFBF7")
        
        // MARK: - Semantic Colors
        /// Success - Completed goals, positive feedback
        static let success = Color(hex: "#4CAF50")
        /// Warning - Gentle alerts (not alarm)
        static let warning = Color(hex: "#FFB74D")
        /// Error - Soft error states (not harsh red)
        static let error = Color(hex: "#E57373")
        
        // MARK: - Text Colors (Light Mode)
        /// Primary label - Main text color
        static let labelPrimary = Color(hex: "#1A1B26")
        /// Secondary label - Supporting text
        static let labelSecondary = Color(hex: "#5A5A6E")
        /// Tertiary label - Metadata, timestamps
        static let labelTertiary = Color(hex: "#8A8A9E")
        /// Disabled label - Inactive elements
        static let labelDisabled = Color(hex: "#C0C0C8")
        
        // MARK: - Dividers & Borders (Light Mode)
        /// Divider - Subtle separators
        static let divider = Color(hex: "#E8E8EC")
        /// Border - Card and input borders
        static let border = Color(hex: "#D0D0D8")
        /// Border Focused - Active input focus ring
        static let borderFocused = Color(hex: "#88B04B")
    }
}

// MARK: - Dark Mode Adaptive Colors
extension Color.Monch {
    /// Adaptive primary label that switches based on color scheme
    static func adaptiveLabelPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cream : labelPrimary
    }
    
    /// Adaptive secondary label
    static func adaptiveLabelSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#A0A0B0") : labelSecondary
    }
    
    /// Adaptive tertiary label
    static func adaptiveLabelTertiary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#707080") : labelTertiary
    }
    
    /// Adaptive background
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? midnightNavy : cream
    }
    
    /// Adaptive elevated surface
    static func adaptiveElevatedSurface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? warmCharcoal : .white
    }
    
    /// Adaptive divider
    static func adaptiveDivider(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#3A3A42") : divider
    }
    
    /// Adaptive border
    static func adaptiveBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#4A4A52") : border
    }
}
