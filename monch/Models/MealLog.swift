//
//  MealLog.swift
//  monch
//
//  Created by Opencode Agent on 03/01/2026.
//

import Foundation
import SwiftData

@Model
final class MealLog {
    var id: UUID
    var timestamp: Date
    var name: String
    
    // Macros (Optional because quick-adds might not have full data)
    var calories: Double?
    var carbs: Double?
    var protein: Double?
    var fat: Double?
    
    // Context Tags (Computed by ContextEngine)
    // "refeed", "late_night", "caffeine", "high_sugar"
    var contextTags: [String] = []
    
    init(timestamp: Date = Date(), name: String, calories: Double? = nil, carbs: Double? = nil, protein: Double? = nil, fat: Double? = nil, tags: [String] = []) {
        self.id = UUID()
        self.timestamp = timestamp
        self.name = name
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.contextTags = tags
    }
}
