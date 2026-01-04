//
//  InsightEvent.swift
//  monch
//
//  Created by Opencode Agent on 03/01/2026.
//

import Foundation
import SwiftData

enum InsightType: String, Codable, CaseIterable {
    // MARK: - Existing (HR-based)
    case sugarSpike      // Acute Loop
    case anxietyMimic    // Acute Loop
    case caffeineJitter  // Acute Loop - caffeine-induced alertness
    case muscleSponge    // Recovery Loop
    case zone2Drain      // Recovery Loop - glucose sink from exercise
    case digestionDebt   // Circadian Loop
    case deepSleepRobber // Circadian Loop
    case goodSpike       // Recovery Loop
    
    // MARK: - New HRV-Powered (Sprint 12)
    case recoveryGap        // Post-workout under-fueling (slow HRV recovery)
    case stressBuffer       // Protein protected stress response (stable HRV)
    case mineralGap         // Chronic low HRV → deficiency flag
    case brainFogForecast   // Low morning HRV → poor focus day
    case morningReadiness   // Daily readiness score from HRV
    case mealImpactScore    // HRV drop quantifies meal stress
    case alcoholImpact      // Overnight HRV suppression
    case fastingBenefit     // HRV improvement during fast
    
    /// Insight display tier (controls visibility in UI)
    var tier: InsightTier {
        switch self {
        case .sugarSpike, .muscleSponge, .digestionDebt, .morningReadiness:
            return .primary
        case .anxietyMimic, .caffeineJitter, .recoveryGap, .mealImpactScore:
            return .secondary
        case .stressBuffer, .fastingBenefit, .alcoholImpact, .goodSpike, .zone2Drain:
            return .contextual
        case .mineralGap, .brainFogForecast, .deepSleepRobber:
            return .chronic
        }
    }
    
    /// Whether this insight is positive (celebration) vs concerning
    var isPositive: Bool {
        switch self {
        case .muscleSponge, .goodSpike, .zone2Drain, .stressBuffer, .fastingBenefit:
            return true
        case .morningReadiness:
            return true  // Can be negative, but handled by severity
        default:
            return false
        }
    }
}

/// Insight visibility tier for UI hierarchy
enum InsightTier: String, Codable {
    case primary     // Always shown, full card
    case secondary   // Collapsed, expandable
    case contextual  // Modal/celebration
    case chronic     // Weekly digest only
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
    
    // Whether the user has dismissed this insight
    var isDismissed: Bool = false
    
    init(timestamp: Date = Date(), type: InsightType, severity: Double = 0.5, message: String, associatedMealID: UUID? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.type = type
        self.severity = severity
        self.message = message
        self.associatedMealID = associatedMealID
    }
}
