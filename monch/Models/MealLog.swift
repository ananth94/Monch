//
//  MealLog.swift
//  monch
//
//  SwiftData model for food/meal logging.
//  Supports macros, micronutrients, and context tagging.
//

import Foundation
import SwiftData

@Model
final class MealLog {
    var id: UUID
    var timestamp: Date
    var name: String
    
    // MARK: - Macronutrients
    
    /// Total calories (kcal)
    var calories: Double?
    
    /// Carbohydrates (grams)
    var carbs: Double?
    
    /// Protein (grams)
    var protein: Double?
    
    /// Fat (grams)
    var fat: Double?
    
    /// Dietary fiber (grams)
    var fiber: Double?
    
    /// Total sugars (grams) — for Sugar Spike insight
    var sugar: Double?
    
    // MARK: - Micronutrients (for Mineral Gap / Caffeine insights)
    
    /// Caffeine content (mg) — for Caffeine Jitter insight
    var caffeine: Double?
    
    /// Magnesium (mg) — for Mineral Gap insight
    var magnesium: Double?
    
    /// Zinc (mg) — for Mineral Gap insight
    var zinc: Double?
    
    /// Sodium (mg) — for Cardiovascular / Hydration context
    var sodium: Double?
    
    /// Iron (mg) — for Energy / Blood Health context
    var iron: Double?
    
    // MARK: - Context
    
    /// Tags computed by ContextEngine: "refeed", "late_night", "caffeine", "high_sugar"
    var contextTags: [String] = []
    
    /// The quantity or serving size multiplier (e.g., 1.0, 2.0, 0.5)
    var quantity: Double = 1.0
    
    // MARK: - Initialization
    
    init(
        timestamp: Date = Date(),
        name: String,
        quantity: Double = 1.0,
        calories: Double? = nil,
        carbs: Double? = nil,
        protein: Double? = nil,
        fat: Double? = nil,
        fiber: Double? = nil,
        sugar: Double? = nil,
        caffeine: Double? = nil,
        magnesium: Double? = nil,
        zinc: Double? = nil,
        sodium: Double? = nil,
        iron: Double? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.name = name
        self.quantity = quantity
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.caffeine = caffeine
        self.magnesium = magnesium
        self.zinc = zinc
        self.sodium = sodium
        self.iron = iron
        self.contextTags = tags
    }
    
    /// Scales all nutritional values by the given multiplier
    /// - Parameter multiplier: The serving size multiplier (e.g., 0.5, 1.5, 2.0)
    func scaleServingSize(by multiplier: Double) {
        if let cal = calories { calories = cal * multiplier }
        if let c = carbs { carbs = c * multiplier }
        if let p = protein { protein = p * multiplier }
        if let f = fat { fat = f * multiplier }
        if let fb = fiber { fiber = fb * multiplier }
        if let s = sugar { sugar = s * multiplier }
        if let cf = caffeine { caffeine = cf * multiplier }
        if let mg = magnesium { magnesium = mg * multiplier }
        if let zn = zinc { zinc = zn * multiplier }
        if let na = sodium { sodium = na * multiplier }
        if let fe = iron { iron = fe * multiplier }
    }
}

// MARK: - Computed Properties

extension MealLog {
    /// Check if this is a high-carb meal (threshold for Sugar Spike detection)
    var isHighCarb: Bool {
        (carbs ?? 0) > 30
    }
    
    /// Check if this is a high-fat meal (threshold for Lipid Load detection)
    var isHighFat: Bool {
        (fat ?? 0) > 25
    }
    
    /// Check if this is a high-protein meal (threshold for Metabolic Burn detection)
    var isHighProtein: Bool {
        (protein ?? 0) > 35
    }
    
    /// Total macros available (for display purposes)
    var hasMacros: Bool {
        carbs != nil || protein != nil || fat != nil
    }
    
    /// Formatted macro string for display
    var macroSummary: String {
        var parts: [String] = []
        if let c = carbs { parts.append("\(Int(c))g carbs") }
        if let p = protein { parts.append("\(Int(p))g protein") }
        if let f = fat { parts.append("\(Int(f))g fat") }
        return parts.isEmpty ? "No macro data" : parts.joined(separator: " • ")
    }
}
