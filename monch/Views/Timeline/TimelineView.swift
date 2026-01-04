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
    @Query(sort: \WorkoutLog.startTime, order: .reverse) private var workouts: [WorkoutLog]
    @Query(sort: \SleepLog.startTime, order: .reverse) private var sleepLogs: [SleepLog]
    @ObservedObject private var healthKit = HealthKitManager.shared
    @ObservedObject private var insightEngine = InsightEngine.shared
    
    @State private var showingMascotDetail = false
    @State private var showingFoodLogger = false
    @State private var selectedMeal: MealLog?
    @State private var selectedInsight: InsightEvent?
    @State private var selectedWorkout: WorkoutLog?
    @State private var selectedSleep: SleepLog?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MeshGradientBackground(mood: insightEngine.currentMood.gradientMood)
                    .opacity(0.3)
                
                VStack(spacing: 0) {
                    // HealthKit Access Banner (if denied)
                    if !healthKit.isAuthorized {
                        healthKitBanner
                    }
                    
                    // Mascot Header - tappable to expand
                    MascotHeader(mood: insightEngine.currentMood) {
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
                MascotDetailView(mood: insightEngine.currentMood)
            }
            .sheet(isPresented: $showingFoodLogger) {
                FoodSearchView { meal in
                    modelContext.insert(meal)
                    // Trigger insight analysis
                    Task {
                        await insightEngine.analyzeMeal(meal, in: modelContext)
                    }
                }
            }
            .onAppear {
                insightEngine.refreshMood(meals: meals, insights: insights)
            }
            .onChange(of: meals.count) { _, _ in
                insightEngine.refreshMood(meals: meals, insights: insights)
            }
            .sheet(item: $selectedMeal) { meal in
                FoodCardView(meal: meal) {
                    modelContext.delete(meal)
                    selectedMeal = nil
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightCardView(insight: insight)
            }
            .sheet(item: $selectedWorkout) { workout in
                ExerciseCardView(workout: workout)
            }
            .sheet(item: $selectedSleep) { sleep in
                SleepCardView(sleepLog: sleep)
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
                            TimelineItemRow(
                                item: item,
                                onMealTap: { selectedMeal = $0 },
                                onInsightTap: { selectedInsight = $0 },
                                onWorkoutTap: { selectedWorkout = $0 },
                                onSleepTap: { selectedSleep = $0 }
                            )
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
        let insightItems = insights.filter { !$0.isDismissed }.map { TimelineItem.insight($0) }
        let workoutItems = workouts.map { TimelineItem.workout($0) }
        let sleepItems = sleepLogs.map { TimelineItem.sleep($0) }
        return (mealItems + insightItems + workoutItems + sleepItems).sorted { $0.timestamp > $1.timestamp }
    }
    
    private var groupedByDay: [(key: Date, value: [TimelineItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: timelineItems) { item in
            calendar.startOfDay(for: item.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - HealthKit Banner
    
    private var healthKitBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.title2)
                .foregroundStyle(Color.Monch.coral)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Health Access Required")
                    .font(.Monch.headline)
                Text("Enable to correlate meals with heart rate")
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Enable") {
                healthKit.openHealthSettings()
            }
            .font(.Monch.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.Monch.coral))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Monch.coral.opacity(0.1))
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Timeline Item Enum

enum TimelineItem: Identifiable {
    case meal(MealLog)
    case insight(InsightEvent)
    case workout(WorkoutLog)
    case sleep(SleepLog)
    
    var id: UUID {
        switch self {
        case .meal(let meal): return meal.id
        case .insight(let insight): return insight.id
        case .workout(let workout): return workout.id
        case .sleep(let sleep): return sleep.id
        }
    }
    
    var timestamp: Date {
        switch self {
        case .meal(let meal): return meal.timestamp
        case .insight(let insight): return insight.timestamp
        case .workout(let workout): return workout.startTime
        case .sleep(let sleep): return sleep.startTime
        }
    }
}

// MARK: - Timeline Item Row

struct TimelineItemRow: View {
    let item: TimelineItem
    var onMealTap: ((MealLog) -> Void)?
    var onInsightTap: ((InsightEvent) -> Void)?
    var onWorkoutTap: ((WorkoutLog) -> Void)?
    var onSleepTap: ((SleepLog) -> Void)?
    
    var body: some View {
        switch item {
        case .meal(let meal):
            MealCard(meal: meal)
                .onTapGesture { onMealTap?(meal) }
        case .insight(let insight):
            InsightTimelineCard(insight: insight)
                .onTapGesture { onInsightTap?(insight) }
        case .workout(let workout):
            WorkoutTimelineCard(workout: workout)
                .onTapGesture { onWorkoutTap?(workout) }
        case .sleep(let sleep):
            SleepTimelineCard(sleep: sleep)
                .onTapGesture { onSleepTap?(sleep) }
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
            
            // Tap indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Insight Timeline Card

struct InsightTimelineCard: View {
    let insight: InsightEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(insight.type.icon)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.type.displayTitle)
                    .font(.Monch.headline)
                
                Text(insight.message)
                    .font(.Monch.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
        .contentShape(Rectangle())
    }
    
    private var insightColor: Color {
        switch insight.type {
        case .sugarSpike, .anxietyMimic: return Color.Monch.coral
        case .digestionDebt, .deepSleepRobber: return Color.Monch.periwinkle
        case .muscleSponge, .goodSpike: return Color.Monch.sage
        }
    }
}

// MARK: - Workout Timeline Card

struct WorkoutTimelineCard: View {
    let workout: WorkoutLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(workout.startTime, format: .dateTime.hour().minute())
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Icon
            Text(workout.category.icon)
                .font(.title2)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.activityName)
                    .font(.Monch.headline)
                
                HStack(spacing: 8) {
                    Text(workout.formattedDuration)
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                    
                    if let distance = workout.formattedDistance {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(distance)
                            .font(.Monch.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let cal = workout.activeCalories {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("\(Int(cal)) kcal")
                            .font(.Monch.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Anabolic Window Indicator
                if workout.isInAnabolicWindow {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                        Text("Anabolic window: \(workout.formattedAnabolicWindowRemaining ?? "Active")")
                            .font(.Monch.caption2)
                    }
                    .foregroundStyle(Color.Monch.sage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.Monch.sage.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Monch.sage.opacity(0.1))
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Sleep Timeline Card

struct SleepTimelineCard: View {
    let sleep: SleepLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text("😴")
                .font(.title2)
                .frame(width: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Night's Sleep")
                    .font(.Monch.headline)
                
                HStack(spacing: 8) {
                    Text(sleep.formattedDuration)
                        .font(.Monch.callout)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text("\(Int(sleep.computedQualityScore * 100))% quality")
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Stage summary
                HStack(spacing: 4) {
                    SleepStagePill(label: "Deep", minutes: sleep.deepSleepMinutes, color: .Monch.periwinkle)
                    SleepStagePill(label: "REM", minutes: sleep.remSleepMinutes, color: .Monch.lavender)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Monch.periwinkle.opacity(0.1))
        )
        .contentShape(Rectangle())
    }
}

private struct SleepStagePill: View {
    let label: String
    let minutes: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(minutes.formattedAsMinutes)")
                .font(.Monch.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
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
        .modelContainer(for: [MealLog.self, InsightEvent.self, WorkoutLog.self, SleepLog.self], inMemory: true)
}
