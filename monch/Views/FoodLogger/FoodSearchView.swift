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
                
                // Meal Type Selector
                mealTypeSelector
                
                // Cart summary (if items exist)
                if !viewModel.cart.isEmpty {
                    cartSummaryBar
                }
                
                // Search Results (always visible)
                searchResults
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
    
    private var mealTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MealLog.MealType.allCases, id: \.self) { type in
                    Button {
                        viewModel.selectedMealType = type
                    } label: {
                        HStack(spacing: 6) {
                            Text(type.icon)
                            Text(type.rawValue)
                                .font(.Monch.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedMealType == type ? Color.Monch.sage : Color.primary.opacity(0.05))
                        )
                        .foregroundStyle(viewModel.selectedMealType == type ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.primary.opacity(0.02))
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        Group {
            if viewModel.isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                errorState(error: error)
            } else if viewModel.searchQuery.isEmpty {
                emptySearchState
            } else if viewModel.results.isEmpty {
                noResultsState
            } else {
                resultsList
            }
        }
    }
    
    private func errorState(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("Connection Error")
                .font(.Monch.headline)
            
            Text(error.localizedDescription)
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                viewModel.retry()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.Monch.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.Monch.sage))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - Cart Summary Bar
    
    @State private var isCartExpanded = false
    
    private var cartSummaryBar: some View {
        VStack(spacing: 0) {
            // Expandable header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isCartExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundStyle(Color.Monch.sage)
                    
                    Text("\(viewModel.cart.count) item\(viewModel.cart.count == 1 ? "" : "s")")
                        .font(.Monch.headline)
                    
                    Text("• \(viewModel.totalMacroSummary)")
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: isCartExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.Monch.sage.opacity(0.1))
            }
            .buttonStyle(.plain)
            
            // Expanded cart items
            if isCartExpanded {
                VStack(spacing: 0) {
                    ForEach(viewModel.cart) { item in
                        CartItemRow(
                            item: item,
                            onIncrement: { viewModel.incrementQuantity(for: item) },
                            onDecrement: { viewModel.decrementQuantity(for: item) }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        Divider()
                    }
                }
                .background(Color.primary.opacity(0.02))
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
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.Monch.body)
                
                if let cal = item.scaledCalories {
                    Text("\(Int(cal)) kcal")
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Quantity Stepper
            HStack(spacing: 12) {
                Button(action: onDecrement) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(item.quantity == 1 ? .red : Color.Monch.sage)
                }
                
                Text("\(item.quantity)")
                    .font(.Monch.headline)
                    .frame(minWidth: 24)
                
                Button(action: onIncrement) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.Monch.sage)
                }
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
