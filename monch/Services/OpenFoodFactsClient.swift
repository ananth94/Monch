//
//  OpenFoodFactsClient.swift
//  monch
//
//  API client for OpenFoodFacts food database.
//  Provides search and barcode lookup with nutritional data parsing.
//

import Foundation

// MARK: - API Client

actor OpenFoodFactsClient {
    static let shared = OpenFoodFactsClient()
    
    private let baseURL = "https://world.openfoodfacts.org"
    private let session: URLSession
    private var searchCache: [String: CachedSearch] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Search
    
    /// Search for food products by name
    /// - Parameters:
    ///   - query: Search term (e.g., "oatmeal")
    ///   - page: Page number for pagination (default 1)
    ///   - pageSize: Results per page (default 20)
    /// - Returns: Array of food items with nutritional data
    func search(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [FoodItem] {
        guard !query.isEmpty else { return [] }
        
        let cacheKey = "\(query)_\(page)_\(pageSize)"
        
        // Check cache
        if let cached = searchCache[cacheKey], !cached.isExpired(after: cacheExpiry) {
            return cached.items
        }
        
        var components = URLComponents(string: "\(baseURL)/cgi/search.pl")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "fields", value: "code,product_name,brands,nutriments,serving_size,image_small_url")
        ]
        
        guard let url = components.url else {
            throw OpenFoodFactsError.invalidURL
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw OpenFoodFactsError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenFoodFactsError.httpError(httpResponse.statusCode)
        }
        
        // Decode off-actor to avoid Sendable issues
        let items = try Self.decodeSearchResponse(data)
        
        // Cache results
        searchCache[cacheKey] = CachedSearch(items: items, timestamp: Date())
        
        return items
    }
    
    // MARK: - Barcode Lookup
    
    /// Look up a product by barcode
    /// - Parameter barcode: UPC/EAN barcode string
    /// - Returns: Food item if found, nil otherwise
    func lookupBarcode(_ barcode: String) async throws -> FoodItem? {
        let url = URL(string: "\(baseURL)/api/v2/product/\(barcode).json")!
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw OpenFoodFactsError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                return nil // Product not found
            }
            throw OpenFoodFactsError.httpError(httpResponse.statusCode)
        }
        
        return try Self.decodeProductResponse(data)
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        searchCache.removeAll()
    }
    
    // MARK: - Static Decoders (Sendable-safe)
    
    private static func decodeSearchResponse(_ data: Data) throws -> [FoodItem] {
        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        return searchResponse.products.compactMap { FoodItem(from: $0) }
    }
    
    private static func decodeProductResponse(_ data: Data) throws -> FoodItem? {
        let productResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
        guard productResponse.status == 1, let product = productResponse.product else {
            return nil
        }
        return FoodItem(from: product)
    }
}

// MARK: - Cache Types

private struct CachedSearch: Sendable {
    let items: [FoodItem]
    let timestamp: Date
    
    func isExpired(after seconds: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > seconds
    }
}

// MARK: - Errors

enum OpenFoodFactsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "Server error: \(code)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError: return "Failed to parse response"
        }
    }
    
    var isNetworkError: Bool {
        if case .networkError = self { return true }
        return false
    }
}

// MARK: - API Response Models (Sendable)

private struct SearchResponse: Decodable, Sendable {
    let count: Int
    let page: Int
    let pageSize: Int
    let products: [ProductDTO]
    
    enum CodingKeys: String, CodingKey {
        case count, page
        case pageSize = "page_size"
        case products
    }
}

private struct ProductResponse: Decodable, Sendable {
    let status: Int
    let product: ProductDTO?
}

private struct ProductDTO: Decodable, Sendable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let imageSmallUrl: String?
    let nutriments: NutrimentsDTO?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case imageSmallUrl = "image_small_url"
        case nutriments
    }
}

private struct NutrimentsDTO: Decodable, Sendable {
    // Per 100g values
    let energyKcal100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fat100g: Double?
    let proteins100g: Double?
    let fiber100g: Double?
    let caffeine100g: Double?
    let sodium100g: Double?
    let magnesium100g: Double?
    let zinc100g: Double?
    let iron100g: Double?
    
    // Per serving values (preferred when available)
    let energyKcalServing: Double?
    let carbohydratesServing: Double?
    let sugarsServing: Double?
    let fatServing: Double?
    let proteinsServing: Double?
    let fiberServing: Double?
    let sodiumServing: Double?
    let magnesiumServing: Double?
    let zincServing: Double?
    let ironServing: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fat100g = "fat_100g"
        case proteins100g = "proteins_100g"
        case fiber100g = "fiber_100g"
        case caffeine100g = "caffeine_100g"
        case sodium100g = "sodium_100g"
        case magnesium100g = "magnesium_100g"
        case zinc100g = "zinc_100g"
        case iron100g = "iron_100g"
        
        case energyKcalServing = "energy-kcal_serving"
        case carbohydratesServing = "carbohydrates_serving"
        case sugarsServing = "sugars_serving"
        case fatServing = "fat_serving"
        case proteinsServing = "proteins_serving"
        case fiberServing = "fiber_serving"
        case sodiumServing = "sodium_serving"
        case magnesiumServing = "magnesium_serving"
        case zincServing = "zinc_serving"
        case ironServing = "iron_serving"
    }
}

// MARK: - App Model

/// Unified food item model used throughout the app
struct FoodItem: Identifiable, Equatable, Sendable {
    let id: String // Barcode or generated UUID
    let name: String
    let brand: String?
    let servingSize: String?
    let imageURL: URL?
    
    // Nutritional data (per serving or per 100g)
    let calories: Double?
    let carbs: Double?
    let sugar: Double?
    let fat: Double?
    let protein: Double?
    let fiber: Double?
    let caffeine: Double?
    let sodium: Double?
    let magnesium: Double?
    let zinc: Double?
    let iron: Double?
    
    /// Whether nutrition data is per serving (true) or per 100g (false)
    let isPerServing: Bool
    
    fileprivate init(from dto: ProductDTO) {
        self.id = dto.code ?? UUID().uuidString
        self.name = dto.productName ?? "Unknown Product"
        self.brand = dto.brands
        self.servingSize = dto.servingSize
        self.imageURL = dto.imageSmallUrl.flatMap { URL(string: $0) }
        
        // Prefer per-serving values when available
        if let nutriments = dto.nutriments {
            if nutriments.energyKcalServing != nil {
                self.calories = nutriments.energyKcalServing
                self.carbs = nutriments.carbohydratesServing
                self.sugar = nutriments.sugarsServing
                self.fat = nutriments.fatServing
                self.protein = nutriments.proteinsServing
                self.fiber = nutriments.fiberServing
                self.sodium = nutriments.sodiumServing
                self.magnesium = nutriments.magnesiumServing
                self.zinc = nutriments.zincServing
                self.iron = nutriments.ironServing
                self.caffeine = nutriments.caffeine100g // Caffeine usually only per 100g
                self.isPerServing = true
            } else {
                self.calories = nutriments.energyKcal100g
                self.carbs = nutriments.carbohydrates100g
                self.sugar = nutriments.sugars100g
                self.fat = nutriments.fat100g
                self.protein = nutriments.proteins100g
                self.fiber = nutriments.fiber100g
                self.sodium = nutriments.sodium100g
                self.magnesium = nutriments.magnesium100g
                self.zinc = nutriments.zinc100g
                self.iron = nutriments.iron100g
                self.caffeine = nutriments.caffeine100g
                self.isPerServing = false
            }
        } else {
            self.calories = nil
            self.carbs = nil
            self.sugar = nil
            self.fat = nil
            self.protein = nil
            self.fiber = nil
            self.sodium = nil
            self.magnesium = nil
            self.zinc = nil
            self.iron = nil
            self.caffeine = nil
            self.isPerServing = false
        }
    }
    
    // Manual initializer for quick-add items
    init(id: String = UUID().uuidString, name: String, brand: String? = nil, servingSize: String? = nil, imageURL: URL? = nil, calories: Double? = nil, carbs: Double? = nil, sugar: Double? = nil, fat: Double? = nil, protein: Double? = nil, fiber: Double? = nil, caffeine: Double? = nil, sodium: Double? = nil, magnesium: Double? = nil, zinc: Double? = nil, iron: Double? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.imageURL = imageURL
        self.calories = calories
        self.carbs = carbs
        self.sugar = sugar
        self.fat = fat
        self.protein = protein
        self.fiber = fiber
        self.caffeine = caffeine
        self.sodium = sodium
        self.magnesium = magnesium
        self.zinc = zinc
        self.iron = iron
        self.isPerServing = true
    }
}

extension FoodItem {
    /// Formatted display name with brand
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(name) (\(brand))"
        }
        return name
    }
    
    /// Macro summary for list display
    var macroSummary: String {
        var parts: [String] = []
        if let cal = calories { parts.append("\(Int(cal)) kcal") }
        if let c = carbs { parts.append("\(Int(c))g C") }
        if let p = protein { parts.append("\(Int(p))g P") }
        if let f = fat { parts.append("\(Int(f))g F") }
        return parts.isEmpty ? "No nutrition data" : parts.joined(separator: " • ")
    }
}
