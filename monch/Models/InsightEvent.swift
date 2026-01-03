//
//  InsightEvent.swift
//  monch
//
//  Created by Opencode Agent on 03/01/2026.
//

import Foundation
import SwiftData

enum InsightType: String, Codable {
    case sugarSpike      // Acute Loop
    case anxietyMimic    // Acute Loop
    case muscleSponge    // Recovery Loop
    case digestionDebt   // Circadian Loop
    case deepSleepRobber // Circadian Loop
    case goodSpike       // Recovery Loop
}

@Model
final class InsightEvent {
    var id: UUID
    var timestamp: Date
    var type: InsightType
    var severity: Double // 0.0 to 1.0
    var message: String // The "Cozy" copy displayed to user
    
    // Link to the meal that caused it (Optional, as some insights might be cumulative)
    var associatedMealID: UUID?
    
    init(timestamp: Date = Date(), type: InsightType, severity: Double, message: String, associatedMealID: UUID? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.type = type
        self.severity = severity
        self.message = message
        self.associatedMealID = associatedMealID
    }
}
