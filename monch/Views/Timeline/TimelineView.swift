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
    @Query(sort: \VibeCheck.timestamp, order: .reverse) private var vibeChecks: [VibeCheck]
    @ObservedObject private var healthKit = HealthKitManager.shared
    @ObservedObject private var insightEngine = InsightEngine.shared
    
    @State private var showingMascotDetail = false
    @State private var showingFoodLogger = false
    @State private var showingExerciseLogger = false
    @State private var showingSleepLogger = false
    @State private var showingCaffeineLogger = false
    @State private var showingSupplementLogger = false
    @State private var showingVibeCheck = false
    @State private var selectedMeal: MealLog?
    @State private var selectedInsight: InsightEvent?
    @State private var selectedWorkout: WorkoutLog?
    @State private var selectedSleep: SleepLog?
    @State private var selectedVibe: VibeCheck?
    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker = false
    
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
            .navigationTitle(selectedDate.isToday ? "Timeline" : selectedDate.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(selectedDate.isToday ? .secondary : Color.Monch.sage)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingFoodLogger = true
                        } label: {
                            Label("Log Meal", systemImage: "fork.knife")
                        }
                        
                        Button {
                            showingCaffeineLogger = true
                        } label: {
                            Label("Quick Caffeine", systemImage: "cup.and.saucer.fill")
                        }
                        
                        Button {
                            showingSupplementLogger = true
                        } label: {
                            Label("Supplement Stack", systemImage: "pills.fill")
                        }
                        
                        Divider()
                        
                        Button {
                            showingExerciseLogger = true
                        } label: {
                            Label("Log Exercise", systemImage: "figure.run")
                        }
                        
                        Button {
                            showingSleepLogger = true
                        } label: {
                            Label("Log Sleep", systemImage: "moon.zzz")
                        }
                        
                        Divider()
                        
                        Button {
                            showingVibeCheck = true
                        } label: {
                            Label("Vibe Check", systemImage: "face.smiling")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.Monch.sage)
                    }
                }
            }
            .sheet(isPresented: $showingMascotDetail) {
                MascotDetailView(mood: insightEngine.currentMood) { action in
                    handleMascotAction(action)
                }
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
            .sheet(isPresented: $showingExerciseLogger) {
                ExerciseLogView { workout in
                    // Trigger muscle sponge check via insight engine
                    insightEngine.refreshMood(meals: meals, insights: insights)
                }
            }
            .sheet(isPresented: $showingSleepLogger) {
                SleepLogView { _ in
                    // Sleep logged, refresh timeline
                    insightEngine.refreshMood(meals: meals, insights: insights)
                }
            }
            .sheet(isPresented: $showingCaffeineLogger) {
                CaffeineQuickAddView { meal in
                    Task {
                        await insightEngine.analyzeMeal(meal, in: modelContext)
                    }
                }
            }
            .sheet(isPresented: $showingSupplementLogger) {
                SupplementStackView { meal in
                    Task {
                        await insightEngine.analyzeMeal(meal, in: modelContext)
                    }
                }
            }
            .sheet(isPresented: $showingVibeCheck) {
                VibeCheckView()
            }
            .onAppear {
                insightEngine.refreshMood(meals: meals, insights: insights)
            }
            .onChange(of: meals.count) { _, _ in
                insightEngine.refreshMood(meals: meals, insights: insights)
            }
            .sheet(item: $selectedMeal) { meal in
                FoodCardView(meal: meal) {
                    let mealID = meal.id
                    modelContext.delete(meal)
                    
                    // Cleanup associated insights
                    let predicate = #Predicate<InsightEvent> { insight in
                        insight.associatedMealID == mealID
                    }
                    try? modelContext.delete(model: InsightEvent.self, where: predicate)
                    
                    selectedMeal = nil
                    
                    // Refresh mascot mood immediately
                    insightEngine.refreshMood(meals: meals, insights: insights)
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
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
        }
    }
    
    // MARK: - Mascot Actions
    
    private func handleMascotAction(_ action: String) {
        switch action {
        case "Log Meal", "Log Protein", "Quick Snack":
            showingFoodLogger = true
        case "Add Walk":
            // TODO: Deep link to workout/activity flow
            break
        case "Close Kitchen":
            // TODO: Log a 'Last Call' event or start fasting timer
            break
        default:
            break
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
                                onSleepTap: { selectedSleep = $0 },
                                onVibeTap: { selectedVibe = $0 }
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
        let calendar = Calendar.current
        let startOfSelectedDay = calendar.startOfDay(for: selectedDate)
        let endOfSelectedDay = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDay)!
        
        // Filter items to selected day (or show all if today for real-time feel)
        let mealItems = meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
            .map { TimelineItem.meal($0) }
        let insightItems = insights
            .filter { !$0.isDismissed && calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
            .map { TimelineItem.insight($0) }
        let workoutItems = workouts
            .filter { calendar.isDate($0.startTime, inSameDayAs: selectedDate) }
            .map { TimelineItem.workout($0) }
        let sleepItems = sleepLogs
            .filter { calendar.isDate($0.endTime, inSameDayAs: selectedDate) } // Wake time = selected day
            .map { TimelineItem.sleep($0) }
        let vibeItems = vibeChecks
            .filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
            .map { TimelineItem.vibe($0) }
        return (mealItems + insightItems + workoutItems + sleepItems + vibeItems).sorted { $0.timestamp > $1.timestamp }
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
    case vibe(VibeCheck)
    
    var id: UUID {
        switch self {
        case .meal(let meal): return meal.id
        case .insight(let insight): return insight.id
        case .workout(let workout): return workout.id
        case .sleep(let sleep): return sleep.id
        case .vibe(let vibe): return vibe.id
        }
    }
    
    var timestamp: Date {
        switch self {
        case .meal(let meal): return meal.timestamp
        case .insight(let insight): return insight.timestamp
        case .workout(let workout): return workout.startTime
        case .sleep(let sleep): return sleep.startTime
        case .vibe(let vibe): return vibe.timestamp
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
    var onVibeTap: ((VibeCheck) -> Void)?
    
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
        case .vibe(let vibe):
            VibeTimelineCard(vibe: vibe)
                .onTapGesture { onVibeTap?(vibe) }
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
                HStack(spacing: 6) {
                    Text(meal.name)
                        .font(.Monch.headline)
                    
                    // Auto-tags as emojis
                    if !meal.autoTags.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(meal.autoTags, id: \.self) { tag in
                                Text(tagEmoji(tag))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                
                if meal.hasMacros {
                    Text(meal.macroSummary)
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                }
                
                // User Context Tags (text pills)
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
    
    /// Convert tag name to emoji for compact display
    private func tagEmoji(_ tag: String) -> String {
        switch tag {
        case "refeed": return "💪"
        case "late-night": return "🌙"
        case "breakfast": return "☀️"
        case "lunch": return "🍽️"
        case "dinner": return "🍴"
        case "high-carb": return "🍞"
        default: return "🏷️"
        }
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
        case .caffeineJitter: return Color.Monch.sage // Positive/alert state
        case .digestionDebt, .deepSleepRobber: return Color.Monch.periwinkle
        case .muscleSponge, .goodSpike, .zone2Drain: return Color.Monch.sage
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

// MARK: - Vibe Timeline Card

struct VibeTimelineCard: View {
    let vibe: VibeCheck
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(vibe.timestamp, format: .dateTime.hour().minute())
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Emoji
            Text(vibe.emoji)
                .font(.title2)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Vibe Check: \(vibe.label)")
                    .font(.Monch.headline)
                
                HStack(spacing: 8) {
                    VibeScalePill(label: "Energy", score: vibe.energy, color: .orange)
                    VibeScalePill(label: "Focus", score: vibe.focus, color: Color.Monch.sage)
                    VibeScalePill(label: "Mood", score: vibe.mood, color: Color.Monch.periwinkle)
                }
                
                if let note = vibe.note {
                    Text(note)
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Monch.periwinkle.opacity(0.1))
        )
        .contentShape(Rectangle())
    }
}

private struct VibeScalePill: View {
    let label: String
    let score: Int
    let color: Color
    
    var body: some View {
        Text("\(label) \(score)/5")
            .font(.Monch.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
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

// MARK: - Date Extension

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Button("Go to Today") {
                    selectedDate = Date()
                    dismiss()
                }
                .font(.Monch.callout)
                .foregroundStyle(Color.Monch.sage)
                .padding(.bottom)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .modelContainer(for: [MealLog.self, InsightEvent.self, WorkoutLog.self, SleepLog.self, VibeCheck.self], inMemory: true)
}
