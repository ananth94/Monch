//
//  OpenFoodFactsClientTests.swift
//  monchTests
//
//  Unit tests for OpenFoodFacts API client with mock URLSession.
//

import XCTest
@testable import monch

final class OpenFoodFactsClientTests: XCTestCase {
    
    // MARK: - Search Tests
    
    func testSearchReturnsResults() async throws {
        // Given a search query
        let client = OpenFoodFactsClient.shared
        
        // When searching for a common food
        let results = try await client.search(query: "oatmeal", pageSize: 5)
        
        // Then we should get results
        XCTAssertFalse(results.isEmpty, "Search should return results for 'oatmeal'")
    }
    
    func testSearchEmptyQueryReturnsEmpty() async throws {
        // Given an empty query
        let client = OpenFoodFactsClient.shared
        
        // When searching with empty string
        let results = try await client.search(query: "")
        
        // Then we should get empty results
        XCTAssertTrue(results.isEmpty, "Empty query should return empty results")
    }
    
    func testSearchResultsHaveNutrition() async throws {
        // Given a search query
        let client = OpenFoodFactsClient.shared
        
        // When searching for a packaged food
        let results = try await client.search(query: "coca cola", pageSize: 5)
        
        // Then at least one result should have nutritional data
        let hasNutrition = results.contains { $0.calories != nil }
        XCTAssertTrue(hasNutrition, "At least one result should have calorie data")
    }
    
    // MARK: - Barcode Tests
    
    func testBarcodeValidProductReturnsItem() async throws {
        // Given a known barcode (Nutella 750g)
        let client = OpenFoodFactsClient.shared
        let barcode = "3017620422003"
        
        // When looking up by barcode
        let item = try await client.lookupBarcode(barcode)
        
        // Then we should get a valid item
        XCTAssertNotNil(item, "Known barcode should return a product")
        XCTAssertTrue(item?.name.lowercased().contains("nutella") ?? false, "Product name should contain 'nutella'")
    }
    
    func testBarcodeInvalidReturnsNil() async throws {
        // Given an invalid barcode
        let client = OpenFoodFactsClient.shared
        let barcode = "0000000000000"
        
        // When looking up by barcode
        let item = try await client.lookupBarcode(barcode)
        
        // Then we should get nil
        XCTAssertNil(item, "Invalid barcode should return nil")
    }
    
    // MARK: - FoodItem Model Tests
    
    func testFoodItemMacroSummary() {
        // Given a food item with macros
        let item = FoodItem(
            name: "Test Food",
            calories: 200,
            carbs: 25,
            fat: 10,
            protein: 8
        )
        
        // When getting macro summary
        let summary = item.macroSummary
        
        // Then it should contain all values
        XCTAssertTrue(summary.contains("200 kcal"), "Summary should contain calories")
        XCTAssertTrue(summary.contains("25g C"), "Summary should contain carbs")
        XCTAssertTrue(summary.contains("10g F"), "Summary should contain fat")
        XCTAssertTrue(summary.contains("8g P"), "Summary should contain protein")
    }
    
    func testFoodItemNoNutritionData() {
        // Given a food item without macros
        let item = FoodItem(name: "Unknown Food")
        
        // When getting macro summary
        let summary = item.macroSummary
        
        // Then it should show no data message
        XCTAssertEqual(summary, "No nutrition data")
    }
    
    func testFoodItemDisplayNameWithBrand() {
        // Given a food item with brand
        let item = FoodItem(name: "Cereal", brand: "Kellogg's")
        
        // When getting display name
        let name = item.displayName
        
        // Then it should include brand
        XCTAssertEqual(name, "Cereal (Kellogg's)")
    }
    
    func testFoodItemDisplayNameWithoutBrand() {
        // Given a food item without brand
        let item = FoodItem(name: "Banana")
        
        // When getting display name
        let name = item.displayName
        
        // Then it should just be the name
        XCTAssertEqual(name, "Banana")
    }
}

// MARK: - ViewModel Tests

final class FoodSearchViewModelTests: XCTestCase {
    
    @MainActor
    func testAddToCart() async {
        // Given a view model
        let viewModel = FoodSearchViewModel()
        let item = FoodItem(name: "Test Item", calories: 100)
        
        // When adding to cart
        viewModel.addToCart(item)
        
        // Then cart should contain item
        XCTAssertEqual(viewModel.cart.count, 1)
        XCTAssertEqual(viewModel.cart.first?.name, "Test Item")
    }
    
    @MainActor
    func testRemoveFromCart() async {
        // Given a view model with items
        let viewModel = FoodSearchViewModel()
        let item = FoodItem(name: "Test Item", calories: 100)
        viewModel.addToCart(item)
        
        // When removing from cart
        viewModel.removeFromCart(item)
        
        // Then cart should be empty
        XCTAssertTrue(viewModel.cart.isEmpty)
    }
    
    @MainActor
    func testTotalMacroSummary() async {
        // Given a view model with multiple items
        let viewModel = FoodSearchViewModel()
        viewModel.addToCart(FoodItem(name: "Item 1", calories: 100, carbs: 20, protein: 5, fat: 3))
        viewModel.addToCart(FoodItem(name: "Item 2", calories: 150, carbs: 30, protein: 10, fat: 5))
        
        // When getting total summary
        let summary = viewModel.totalMacroSummary
        
        // Then it should sum correctly
        XCTAssertTrue(summary.contains("250 kcal"), "Should sum to 250 kcal")
        XCTAssertTrue(summary.contains("50g C"), "Should sum to 50g carbs")
        XCTAssertTrue(summary.contains("15g P"), "Should sum to 15g protein")
        XCTAssertTrue(summary.contains("8g F"), "Should sum to 8g fat")
    }
    
    @MainActor
    func testCreateMealLog() async {
        // Given a view model with items
        let viewModel = FoodSearchViewModel()
        viewModel.addToCart(FoodItem(name: "Oatmeal", calories: 150, carbs: 27, protein: 5, fat: 3, fiber: 4))
        viewModel.addToCart(FoodItem(name: "Banana", calories: 105, carbs: 27, sugar: 14))
        
        // When creating meal log
        let meal = viewModel.createMealLog()
        
        // Then meal should have aggregated data
        XCTAssertNotNil(meal)
        XCTAssertEqual(meal?.calories, 255)
        XCTAssertEqual(meal?.carbs, 54)
        XCTAssertEqual(meal?.protein, 5)
        XCTAssertEqual(meal?.fat, 3)
        XCTAssertEqual(meal?.fiber, 4)
        XCTAssertEqual(meal?.sugar, 14)
    }
    
    @MainActor
    func testCreateMealLogEmptyCart() async {
        // Given an empty view model
        let viewModel = FoodSearchViewModel()
        
        // When creating meal log
        let meal = viewModel.createMealLog()
        
        // Then should return nil
        XCTAssertNil(meal)
    }
}
