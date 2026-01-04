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
    @Published var cart: [FoodItem] = []
    
    // MARK: - Private
    
    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000 // 300ms in nanoseconds
    
    init() {
        // Set up debounced search
        setupSearchObserver()
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
        cart.append(item)
    }
    
    func removeFromCart(_ item: FoodItem) {
        cart.removeAll { $0.id == item.id }
    }
    
    var totalMacroSummary: String {
        let totalCal = cart.compactMap(\.calories).reduce(0, +)
        let totalCarbs = cart.compactMap(\.carbs).reduce(0, +)
        let totalProtein = cart.compactMap(\.protein).reduce(0, +)
        let totalFat = cart.compactMap(\.fat).reduce(0, +)
        
        return "\(Int(totalCal)) kcal • \(Int(totalCarbs))g C • \(Int(totalProtein))g P • \(Int(totalFat))g F"
    }
    
    // MARK: - Create MealLog
    
    func createMealLog() -> MealLog? {
        guard !cart.isEmpty else { return nil }
        
        // Aggregate nutritional data
        let name = cart.count == 1 
            ? cart.first!.name 
            : "\(cart.first!.name) + \(cart.count - 1) more"
        
        let totalCalories = cart.compactMap(\.calories).reduce(0, +)
        let totalCarbs = cart.compactMap(\.carbs).reduce(0, +)
        let totalProtein = cart.compactMap(\.protein).reduce(0, +)
        let totalFat = cart.compactMap(\.fat).reduce(0, +)
        let totalFiber = cart.compactMap(\.fiber).reduce(0, +)
        let totalSugar = cart.compactMap(\.sugar).reduce(0, +)
        let totalCaffeine = cart.compactMap(\.caffeine).reduce(0, +)
        
        return MealLog(
            name: name,
            calories: totalCalories > 0 ? totalCalories : nil,
            carbs: totalCarbs > 0 ? totalCarbs : nil,
            protein: totalProtein > 0 ? totalProtein : nil,
            fat: totalFat > 0 ? totalFat : nil,
            fiber: totalFiber > 0 ? totalFiber : nil,
            sugar: totalSugar > 0 ? totalSugar : nil,
            caffeine: totalCaffeine > 0 ? totalCaffeine : nil
        )
    }
}
