//
//  TimeFormatting.swift
//  monch
//
//  Shared time formatting utilities for consistent display across the app.
//

import Foundation

extension Int {
    /// Formats minutes into "Xh Ym" or "Ym" format
    /// - Returns: Formatted string like "2h 15m" or "45m"
    var formattedAsMinutes: String {
        let hours = self / 60
        let mins = self % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

extension TimeInterval {
    /// Formats seconds into "Xh Ym" or "Ym" format
    /// - Returns: Formatted string like "2h 15m" or "45m"
    var formattedAsMinutes: String {
        let totalMinutes = Int(self / 60)
        return totalMinutes.formattedAsMinutes
    }
}
