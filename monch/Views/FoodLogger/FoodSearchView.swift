//
//  FoodSearchView.swift
//  monch
//
//  Food search UI with debounced input, results list, and cart integration.
//

import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FoodSearchViewModel()
    
    /// Callback when meal is logged
    var onMealLogged: ((MealLog) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Content
                if viewModel.cart.isEmpty {
                    // Search Results
                    searchResults
                } else {
                    // Cart View
                    cartView
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                if !viewModel.cart.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Log") {
                            if let meal = viewModel.createMealLog() {
                                onMealLogged?(meal)
                                dismiss()
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search foods...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        Group {
            if viewModel.isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.searchQuery.isEmpty {
                emptySearchState
            } else if viewModel.results.isEmpty {
                noResultsState
            } else {
                resultsList
            }
        }
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("Search for a food")
                .font(.Monch.headline)
            
            Text("Or add items manually below")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            // Quick Add Buttons
            quickAddSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("No results found")
                .font(.Monch.headline)
            
            Text("Try a different search term")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        List {
            ForEach(viewModel.results) { item in
                FoodItemRow(item: item) {
                    viewModel.addToCart(item)
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Quick Add Section
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickAddButton(title: "☕ Coffee", subtitle: "with milk") {
                        viewModel.addToCart(FoodItem(name: "Coffee with Milk", calories: 30, caffeine: 95))
                    }
                    
                    QuickAddButton(title: "🥛 Protein Shake", subtitle: "30g protein") {
                        viewModel.addToCart(FoodItem(name: "Protein Shake", calories: 150, carbs: 5, fat: 2, protein: 30))
                    }
                    
                    QuickAddButton(title: "🍌 Banana", subtitle: "medium") {
                        viewModel.addToCart(FoodItem(name: "Banana", calories: 105, carbs: 27, sugar: 14, fiber: 3))
                    }
                    
                    QuickAddButton(title: "🥜 Almonds", subtitle: "handful") {
                        viewModel.addToCart(FoodItem(name: "Almonds (handful)", calories: 160, carbs: 6, fat: 14, protein: 6))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Cart View
    
    private var cartView: some View {
        VStack(spacing: 0) {
            // Cart Items
            List {
                Section {
                    ForEach(viewModel.cart) { item in
                        CartItemRow(item: item) {
                            viewModel.removeFromCart(item)
                        }
                    }
                } header: {
                    Text("Your Meal")
                }
                
                // Totals
                Section {
                    HStack {
                        Text("Total")
                            .font(.Monch.headline)
                        Spacer()
                        Text(viewModel.totalMacroSummary)
                            .font(.Monch.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // Add More Button
            Button {
                // Clear search to show quick add again
                viewModel.searchQuery = ""
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add More Items")
                }
                .font(.Monch.headline)
                .foregroundStyle(Color.Monch.sage)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.Monch.sage.opacity(0.1))
            }
        }
    }
}

// MARK: - Food Item Row

struct FoodItemRow: View {
    let item: FoodItem
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Image or placeholder
            if let url = item.imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.Monch.headline)
                    .lineLimit(2)
                
                Text(item.macroSummary)
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
                
                if let serving = item.servingSize {
                    Text("Serving: \(serving)")
                        .font(.Monch.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Add Button
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.Monch.sage)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let item: FoodItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.Monch.body)
                
                Text(item.macroSummary)
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.Monch.headline)
                Text(subtitle)
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    FoodSearchView()
}
