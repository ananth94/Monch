//
//  TimelineView.swift
//  monch
//
//  The main "River UI" timeline showing chronological events (meals, insights).
//  Newest events at top, grouped by day with sticky headers.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.timestamp, order: .reverse) private var meals: [MealLog]
    @Query(sort: \InsightEvent.timestamp, order: .reverse) private var insights: [InsightEvent]
    
    @State private var showingMascotDetail = false
    @State private var showingFoodLogger = false
    @State private var currentMood: MascotMoodState = .neutral
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MeshGradientBackground(mood: currentMood.gradientMood)
                    .opacity(0.3)
                
                VStack(spacing: 0) {
                    // Mascot Header - tappable to expand
                    MascotHeader(mood: currentMood) {
                        showingMascotDetail = true
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Timeline Content
                    if timelineItems.isEmpty {
                        EmptyTimelineView {
                            showingFoodLogger = true
                        }
                    } else {
                        timelineList
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFoodLogger = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.Monch.sage)
                    }
                }
            }
            .sheet(isPresented: $showingMascotDetail) {
                MascotDetailView(mood: currentMood)
            }
            .sheet(isPresented: $showingFoodLogger) {
                FoodLoggerPlaceholder()
            }
        }
    }
    
    // MARK: - Timeline List
    
    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedByDay, id: \.key) { day, items in
                    Section {
                        ForEach(items.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                            TimelineItemRow(item: item)
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                        }
                    } header: {
                        DayHeader(date: day)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    // MARK: - Data Grouping
    
    private var timelineItems: [TimelineItem] {
        let mealItems = meals.map { TimelineItem.meal($0) }
        let insightItems = insights.map { TimelineItem.insight($0) }
        return (mealItems + insightItems).sorted { $0.timestamp > $1.timestamp }
    }
    
    private var groupedByDay: [(key: Date, value: [TimelineItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: timelineItems) { item in
            calendar.startOfDay(for: item.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

// MARK: - Timeline Item Enum

enum TimelineItem: Identifiable {
    case meal(MealLog)
    case insight(InsightEvent)
    
    var id: UUID {
        switch self {
        case .meal(let meal): return meal.id
        case .insight(let insight): return insight.id
        }
    }
    
    var timestamp: Date {
        switch self {
        case .meal(let meal): return meal.timestamp
        case .insight(let insight): return insight.timestamp
        }
    }
}

// MARK: - Timeline Item Row

struct TimelineItemRow: View {
    let item: TimelineItem
    
    var body: some View {
        switch item {
        case .meal(let meal):
            MealCard(meal: meal)
        case .insight(let insight):
            InsightCardPlaceholder(insight: insight)
        }
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: MealLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(meal.timestamp, format: .dateTime.hour().minute())
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.Monch.headline)
                
                if meal.hasMacros {
                    Text(meal.macroSummary)
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Context Tags
                if !meal.contextTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(meal.contextTags, id: \.self) { tag in
                            Text(tag)
                                .font(.Monch.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.Monch.sage.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Insight Card Placeholder

struct InsightCardPlaceholder: View {
    let insight: InsightEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: insightIcon)
                .font(.title2)
                .foregroundStyle(insightColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.type.rawValue.capitalized)
                    .font(.Monch.headline)
                
                Text(insight.message)
                    .font(.Monch.callout)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(insightColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(insightColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var insightIcon: String {
        switch insight.type {
        case .sugarSpike: return "waveform.path.ecg"
        case .digestionDebt: return "moon.zzz"
        case .muscleSponge: return "dumbbell"
        case .anxietyMimic: return "heart.circle"
        case .goodSpike: return "checkmark.circle"
        case .deepSleepRobber: return "bed.double"
        }
    }
    
    private var insightColor: Color {
        switch insight.type {
        case .sugarSpike, .anxietyMimic: return Color.Monch.coral
        case .digestionDebt, .deepSleepRobber: return Color.Monch.periwinkle
        case .muscleSponge, .goodSpike: return Color.Monch.sage
        }
    }
}

// MARK: - Food Logger Placeholder

struct FoodLoggerPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Food Logger",
                systemImage: "magnifyingglass",
                description: Text("Coming in Sprint 3")
            )
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .modelContainer(for: [MealLog.self, InsightEvent.self], inMemory: true)
}
