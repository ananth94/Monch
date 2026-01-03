//
//  MascotStateLog.swift
//  monch
//
//  Created by Opencode Agent on 03/01/2026.
//

import Foundation
import SwiftData

enum MascotMood: String, Codable {
    case neutral
    case hungry
    case full
    case spiking
    case crashing
    case sleepy
    case strong
}

@Model
final class MascotStateLog {
    var id: UUID
    var timestamp: Date
    var mood: MascotMood
    
    init(timestamp: Date = Date(), mood: MascotMood) {
        self.id = UUID()
        self.timestamp = timestamp
        self.mood = mood
    }
}
