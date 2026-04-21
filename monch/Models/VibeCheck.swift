//
//  VibeCheck.swift
//  monch
//
//  SwiftData model for user-reported subjective state (energy, focus, mood).
//

import Foundation
import SwiftData

@Model
final class VibeCheck {
    var id: UUID
    var timestamp: Date
    
    /// Energy level 1-5
    var energy: Int
    
    /// Focus level 1-5
    var focus: Int
    
    /// Mood level 1-5
    var mood: Int
    
    /// Optional freeform note
    var note: String?
    
    init(
        timestamp: Date = Date(),
        energy: Int,
        focus: Int,
        mood: Int,
        note: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.energy = energy
        self.focus = focus
        self.mood = mood
        self.note = note
    }
}

// MARK: - Computed Properties

extension VibeCheck {
    /// Overall vibe score (average of energy, focus, mood)
    var average: Double {
        Double(energy + focus + mood) / 3.0
    }
    
    /// Symbol representation of overall vibe
    var symbolName: String {
        switch average {
        case 0..<1.5: return "cloud.rain.fill"
        case 1.5..<2.5: return "cloud.fill"
        case 2.5..<3.5: return "circle.fill"
        case 3.5..<4.5: return "sun.max.fill"
        default: return "sparkles"
        }
    }
    
    /// Qualitative label
    var label: String {
        switch average {
        case 0..<1.5: return "Rough"
        case 1.5..<2.5: return "Low"
        case 2.5..<3.5: return "Okay"
        case 3.5..<4.5: return "Good"
        default: return "Great"
        }
    }
    
    static func symbolName(for level: Int) -> String {
        switch level {
        case 1: return "battery.25"
        case 2: return "battery.50"
        case 3: return "circle.fill"
        case 4: return "sun.max.fill"
        case 5: return "sparkles"
        default: return "circle.fill"
        }
    }
}
