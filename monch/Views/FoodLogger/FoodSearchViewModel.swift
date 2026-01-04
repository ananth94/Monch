//
//  FoodSearchViewModel.swift
//  monch
//
//  ViewModel for food search with debounced API calls and cart management.
//

import SwiftUI
import Combine

@MainActor
class FoodSearchViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var searchQuery = ""
    @Published var results: [FoodItem] = []
    @Published var isSearching = false
    @Published var error: Error?
    @Published var cart: [CartItem] = []
    @Published var selectedMealType: MealLog.MealType = .breakfast
    
    // MARK: - Private
    
    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000 // 300ms in nanoseconds
    
    init() {
        // Set up debounced search
        setupSearchObserver()
        self.selectedMealType = guessMealType()
    }
    
    private func guessMealType() -> MealLog.MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return .breakfast
        case 10..<12: return .morningSnack
        case 12..<14: return .lunch
        case 14..<17: return .afternoonSnack
        case 17..<21: return .dinner
        default: return .eveningSnack
        }
    }
    
    private func setupSearchObserver() {
        // Using Task-based debounce pattern
        $searchQuery
            .removeDuplicates()
            .sink { [weak self] query in
                self?.debounceSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func debounceSearch(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        // Clear results immediately if query is empty
        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }
        
        // Start new debounced search
        searchTask = Task {
            // Wait for debounce delay
            try? await Task.sleep(nanoseconds: debounceDelay)
            
            // Check if cancelled
            guard !Task.isCancelled else { return }
            
            await performSearch(query: query)
        }
    }
    
    private func performSearch(query: String) async {
        isSearching = true
        error = nil
        
        do {
            let items = try await OpenFoodFactsClient.shared.search(query: query)
            
            // Only update if not cancelled and query still matches
            guard searchQuery == query else { return }
            
            results = items
        } catch {
            self.error = error
            results = []
        }
        
        isSearching = false
    }
    
    /// Retry the last search (called from error state)
    func retry() {
        let query = searchQuery
        error = nil
        debounceSearch(query: query)
    }
    
    // MARK: - Cart Management
    
    func addToCart(_ item: FoodItem) {
        // Check if item already in cart - increase quantity instead
        if let index = cart.firstIndex(where: { $0.foodItem.id == item.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(foodItem: item))
        }
    }
    
    func removeFromCart(_ item: CartItem) {
        cart.removeAll { $0.id == item.id }
    }
    
    func incrementQuantity(for item: CartItem) {
        if let index = cart.firstIndex(where: { $0.id == item.id }) {
            cart[index].quantity += 1
        }
    }
    
    func decrementQuantity(for item: CartItem) {
        if let index = cart.firstIndex(where: { $0.id == item.id }) {
            if cart[index].quantity > 1 {
                cart[index].quantity -= 1
            } else {
                cart.remove(at: index)
            }
        }
    }
    
    var totalMacroSummary: String {
        let totalCal = cart.compactMap(\.scaledCalories).reduce(0, +)
        let totalCarbs = cart.compactMap(\.scaledCarbs).reduce(0, +)
        let totalProtein = cart.compactMap(\.scaledProtein).reduce(0, +)
        let totalFat = cart.compactMap(\.scaledFat).reduce(0, +)
        
        return "\(Int(totalCal)) kcal • \(Int(totalCarbs))g C • \(Int(totalProtein))g P • \(Int(totalFat))g F"
    }
    
    // MARK: - Create MealLog
    
    func createMealLog() -> MealLog? {
        guard !cart.isEmpty else { return nil }
        
        // Aggregate nutritional data (using scaled values)
        let name = cart.count == 1 && cart.first!.quantity == 1
            ? cart.first!.name 
            : cart.map { $0.quantity > 1 ? "\($0.quantity)x \($0.name)" : $0.name }.joined(separator: ", ")
        
        let totalCalories = cart.compactMap(\.scaledCalories).reduce(0, +)
        let totalCarbs = cart.compactMap(\.scaledCarbs).reduce(0, +)
        let totalProtein = cart.compactMap(\.scaledProtein).reduce(0, +)
        let totalFat = cart.compactMap(\.scaledFat).reduce(0, +)
        let totalFiber = cart.compactMap(\.scaledFiber).reduce(0, +)
        let totalSugar = cart.compactMap(\.scaledSugar).reduce(0, +)
        let totalCaffeine = cart.compactMap(\.scaledCaffeine).reduce(0, +)
        let totalSodium = cart.compactMap(\.scaledSodium).reduce(0, +)
        let totalMagnesium = cart.compactMap(\.scaledMagnesium).reduce(0, +)
        let totalZinc = cart.compactMap(\.scaledZinc).reduce(0, +)
        let totalIron = cart.compactMap(\.scaledIron).reduce(0, +)
        
        // For quantity tracking in detail view:
        // If it's a single type of item, use its quantity.
        // Otherwise use 1.0 (as the aggregated log is its own new "baseline").
        let finalQuantity = cart.count == 1 ? Double(cart.first!.quantity) : 1.0
        
        return MealLog(
            name: name,
            quantity: finalQuantity,
            mealType: selectedMealType,
            calories: totalCalories > 0 ? totalCalories : nil,
            carbs: totalCarbs > 0 ? totalCarbs : nil,
            protein: totalProtein > 0 ? totalProtein : nil,
            fat: totalFat > 0 ? totalFat : nil,
            fiber: totalFiber > 0 ? totalFiber : nil,
            sugar: totalSugar > 0 ? totalSugar : nil,
            caffeine: totalCaffeine > 0 ? totalCaffeine : nil,
            magnesium: totalMagnesium > 0 ? totalMagnesium : nil,
            zinc: totalZinc > 0 ? totalZinc : nil,
            sodium: totalSodium > 0 ? totalSodium : nil,
            iron: totalIron > 0 ? totalIron : nil
        )
    }
}
