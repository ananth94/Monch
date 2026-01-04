//
//  CartItem.swift
//  monch
//
//  Wrapper for FoodItem with quantity support in the meal logging cart.
//

import Foundation

/// A cart item wrapping a FoodItem with quantity
struct CartItem: Identifiable {
    let id = UUID()
    let foodItem: FoodItem
    var quantity: Int
    
    init(foodItem: FoodItem, quantity: Int = 1) {
        self.foodItem = foodItem
        self.quantity = quantity
    }
    
    // MARK: - Computed Nutrition (scaled by quantity)
    
    var name: String { foodItem.name }
    
    var scaledCalories: Double? {
        guard let cal = foodItem.calories else { return nil }
        return cal * Double(quantity)
    }
    
    var scaledCarbs: Double? {
        guard let v = foodItem.carbs else { return nil }
        return v * Double(quantity)
    }
    
    var scaledProtein: Double? {
        guard let v = foodItem.protein else { return nil }
        return v * Double(quantity)
    }
    
    var scaledFat: Double? {
        guard let v = foodItem.fat else { return nil }
        return v * Double(quantity)
    }
    
    var scaledFiber: Double? {
        guard let v = foodItem.fiber else { return nil }
        return v * Double(quantity)
    }
    
    var scaledSugar: Double? {
        guard let v = foodItem.sugar else { return nil }
        return v * Double(quantity)
    }
    
    var scaledCaffeine: Double? {
        guard let v = foodItem.caffeine else { return nil }
        return v * Double(quantity)
    }
}
