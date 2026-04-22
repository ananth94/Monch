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
    @State private var showingMealLogger = false
    @State private var showingExerciseLogger = false
    @State private var showingSleepLogger = false
    @State private var showingCaffeineLogger = false
    @State private var showingAlcoholLogger = false
    @State private var showingVibeCheck = false
    @State private var healthKitMealEvents: [ImportedMealEvent] = []
    @State private var selectedMeal: MealLog?
    @State private var selectedEventGroup: ConsumableEventGroup?
    @State private var selectedInsight: InsightEvent?
    @State private var selectedWorkout: WorkoutLog?
    @State private var selectedSleep: SleepLog?
    @State private var selectedVibe: VibeCheck?
    @Binding private var selectedDate: Date
    @State private var showingDatePicker = false
    @State private var scrollOffset: CGFloat = 0
    
    init(selectedDate: Binding<Date> = .constant(Date())) {
        self._selectedDate = selectedDate
    }
    
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
                    GeometryReader { geometry in
                        ZStack {
                            // River background with parallax
                            RiverSplineView(
                                itemCount: timelineItems.count,
                                mood: insightEngine.currentMood,
                                geometry: geometry,
                                scrollOffset: scrollOffset
                            )
                            
                            // Timeline items
                            if timelineItems.isEmpty {
                                EmptyTimelineView {
                                    showingMealLogger = true
                                }
                            } else {
                                timelineList
                            }
                        }
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
                            showingMealLogger = true
                        } label: {
                            Label("Log Meal Event", systemImage: "fork.knife")
                        }
                        
                        Button {
                            showingCaffeineLogger = true
                        } label: {
                            Label("Quick Caffeine", systemImage: "cup.and.saucer.fill")
                        }
                        
                        Button {
                            showingAlcoholLogger = true
                        } label: {
                            Label("Log Alcohol", systemImage: "wineglass.fill")
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
            .sheet(isPresented: $showingMealLogger) {
                MealEventLogView { meal in
                    modelContext.insert(meal)
                    // Trigger insight analysis
                    Task {
                        await insightEngine.analyzeMeal(meal, in: modelContext)
                    }
                }
            }
            .sheet(isPresented: $showingExerciseLogger) {
                ExerciseLogView { workout in
                    Task { @MainActor in
                        await insightEngine.analyzeWorkout(workout, in: modelContext)
                        insightEngine.refreshMood(meals: meals, insights: insights)
                    }
                }
            }
            .sheet(isPresented: $showingSleepLogger) {
                SleepLogView { _ in
                    Task { @MainActor in
                        await insightEngine.runMorningChecksIfNeeded(in: modelContext)
                        insightEngine.refreshMood(meals: meals, insights: insights)
                    }
                }
            }
            .sheet(isPresented: $showingCaffeineLogger) {
                CaffeineQuickAddView { meal in
                    Task { @MainActor in
                        await insightEngine.analyzeMeal(meal, in: modelContext)
                    }
                }
            }
            .sheet(isPresented: $showingAlcoholLogger) {
                AlcoholQuickAddView()
            }
            .sheet(isPresented: $showingVibeCheck) {
                VibeCheckView { vibe in
                    Task { @MainActor in
                        await insightEngine.analyzeVibeCheck(vibe, in: modelContext)
                        insightEngine.refreshMood(meals: meals, insights: insights)
                    }
                }
            }
            .onAppear {
                insightEngine.refreshMood(meals: meals, insights: insights)
            }
            .onChange(of: meals.count) { _, _ in
                insightEngine.refreshMood(meals: meals, insights: insights)
            }
            .onChange(of: healthKit.isAuthorized) { _, isAuthorized in
                Task {
                    await loadHealthKitMealEvents(isAuthorized: isAuthorized)
                }
            }
            .task(id: selectedDate) {
                await loadHealthKitMealEvents(isAuthorized: healthKit.isAuthorized)
            }
            .sheet(item: $selectedMeal) { meal in
                FoodCardView(meal: meal) {
                    deleteMealAndAssociatedInsights(meal)
                    selectedMeal = nil
                    
                    // Refresh mascot mood immediately
                    insightEngine.refreshMood(meals: meals, insights: insights)
                }
            }
            .sheet(item: $selectedEventGroup) { group in
                ConsumableEventGroupCardView(
                    group: group,
                    onIncrement: { template in
                        let newEvent = incrementConsumableEvent(from: template)
                        insightEngine.refreshMood(meals: meals, insights: insights)
                        return newEvent
                    },
                    onRemoveLatest: { event in
                        deleteMealAndAssociatedInsights(event)
                        insightEngine.refreshMood(meals: meals, insights: insights)
                    },
                    onDeleteEvent: { event in
                        deleteMealAndAssociatedInsights(event)
                        insightEngine.refreshMood(meals: meals, insights: insights)
                    }
                )
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
        case "Log Meal Event", "Log Protein", "Quick Snack":
            showingMealLogger = true
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
                        ForEach(Array(items.sorted(by: { $0.timestamp > $1.timestamp }).enumerated()), id: \.element.id) { index, item in
                            TimelineItemRow(
                                item: item,
                                cardIndex: index,
                                onMealTap: { selectedMeal = $0 },
                                onEventGroupTap: { selectedEventGroup = $0 },
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
        
        // Filter items to selected day (or show all if today for real-time feel)
        let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
        let (groupedEvents, standaloneMeals) = groupConsumableEvents(from: dayMeals)
        let mealItems = standaloneMeals.map { TimelineItem.meal($0) }
        let healthKitMealItems = dedupedHealthKitMealEvents(against: standaloneMeals)
            .map { TimelineItem.healthKitMeal($0) }
        let groupedEventItems = groupedEvents.map { TimelineItem.eventGroup($0) }
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
        return (mealItems + healthKitMealItems + groupedEventItems + insightItems + workoutItems + sleepItems + vibeItems).sorted { $0.timestamp > $1.timestamp }
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
    
    private func groupConsumableEvents(from meals: [MealLog]) -> ([ConsumableEventGroup], [MealLog]) {
        let timeWindow: TimeInterval = 15 * 60
        var groupedEvents: [ConsumableEventGroup] = []
        var standaloneMeals: [MealLog] = []
        
        struct GroupingKey: Hashable {
            let kind: ConsumableEventKind?
            let name: String
        }
        
        let groupedByKindAndName = Dictionary(grouping: meals) { meal in
            GroupingKey(kind: meal.consumableEventKind, name: meal.name)
        }
        
        for (key, groupedMeals) in groupedByKindAndName {
            guard let kind = key.kind else {
                standaloneMeals.append(contentsOf: groupedMeals)
                continue
            }
            
            let sortedMeals = groupedMeals.sorted { $0.timestamp < $1.timestamp }
            var currentCluster: [MealLog] = []
            
            for meal in sortedMeals {
                if let previous = currentCluster.last,
                   meal.timestamp.timeIntervalSince(previous.timestamp) <= timeWindow {
                    currentCluster.append(meal)
                } else {
                    flushConsumableCluster(&currentCluster, kind: kind, name: key.name, into: &groupedEvents)
                    currentCluster = [meal]
                }
            }
            
            flushConsumableCluster(&currentCluster, kind: kind, name: key.name, into: &groupedEvents)
        }
        
        return (groupedEvents.sorted { $0.timestamp > $1.timestamp }, standaloneMeals.sorted { $0.timestamp > $1.timestamp })
    }
    
    private func flushConsumableCluster(
        _ cluster: inout [MealLog],
        kind: ConsumableEventKind,
        name: String,
        into groups: inout [ConsumableEventGroup]
    ) {
        guard !cluster.isEmpty else { return }
        
        groups.append(ConsumableEventGroup(kind: kind, name: name, events: cluster))
        
        cluster.removeAll()
    }
    
    private func deleteMealAndAssociatedInsights(_ meal: MealLog) {
        let mealID = meal.id
        modelContext.delete(meal)
        
        let predicate = #Predicate<InsightEvent> { insight in
            insight.associatedMealID == mealID
        }
        try? modelContext.delete(model: InsightEvent.self, where: predicate)
    }
    
    private func incrementConsumableEvent(from template: MealLog) -> MealLog {
        let timestamp = template.timestamp.addingTimeInterval(60)
        let newEvent = MealLog(
            timestamp: timestamp,
            name: template.name,
            quantity: 1.0,
            mealType: template.mealType,
            calories: template.calories,
            carbs: template.carbs,
            protein: template.protein,
            fat: template.fat,
            fiber: template.fiber,
            sugar: template.sugar,
            caffeine: template.caffeine,
            magnesium: template.magnesium,
            zinc: template.zinc,
            sodium: template.sodium,
            iron: template.iron,
            tags: template.contextTags
        )
        
        modelContext.insert(newEvent)
        
        if newEvent.consumableEventKind == .caffeine {
            Task { @MainActor in
                await insightEngine.analyzeMeal(newEvent, in: modelContext)
            }
        }
        
        return newEvent
    }
    
    private func loadHealthKitMealEvents(isAuthorized: Bool) async {
        guard isAuthorized else {
            await MainActor.run {
                healthKitMealEvents = []
            }
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
            await MainActor.run {
                healthKitMealEvents = []
            }
            return
        }
        
        do {
            let eventDates = try await healthKit.fetchImportedMealEvents(for: startOfDay...endOfDay)
            await MainActor.run {
                healthKitMealEvents = eventDates.sorted { $0.timestamp > $1.timestamp }
            }
        } catch {
            await MainActor.run {
                healthKitMealEvents = []
            }
        }
    }
    
    private func dedupedHealthKitMealEvents(against localMeals: [MealLog]) -> [ImportedMealEvent] {
        let localMealTimestamps = localMeals
            .filter { !$0.isConsumableEvent }
            .map(\.timestamp)
        let dedupeWindow: TimeInterval = 20 * 60
        
        return healthKitMealEvents.filter { event in
            !localMealTimestamps.contains { localTimestamp in
                abs(localTimestamp.timeIntervalSince(event.timestamp)) <= dedupeWindow
            }
        }
    }
}

// MARK: - Timeline Item Enum

enum TimelineItem: Identifiable {
    case meal(MealLog)
    case healthKitMeal(ImportedMealEvent)
    case eventGroup(ConsumableEventGroup)
    case insight(InsightEvent)
    case workout(WorkoutLog)
    case sleep(SleepLog)
    case vibe(VibeCheck)
    
    var id: String {
        switch self {
        case .meal(let meal): return meal.id.uuidString
        case .healthKitMeal(let meal): return meal.id.uuidString
        case .eventGroup(let group): return group.id
        case .insight(let insight): return insight.id.uuidString
        case .workout(let workout): return workout.id.uuidString
        case .sleep(let sleep): return sleep.id.uuidString
        case .vibe(let vibe): return vibe.id.uuidString
        }
    }
    
    var timestamp: Date {
        switch self {
        case .meal(let meal): return meal.timestamp
        case .healthKitMeal(let meal): return meal.timestamp
        case .eventGroup(let group): return group.timestamp
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
    var cardIndex: Int = 0
    var onMealTap: ((MealLog) -> Void)?
    var onEventGroupTap: ((ConsumableEventGroup) -> Void)?
    var onInsightTap: ((InsightEvent) -> Void)?
    var onWorkoutTap: ((WorkoutLog) -> Void)?
    var onSleepTap: ((SleepLog) -> Void)?
    var onVibeTap: ((VibeCheck) -> Void)?
    
    var body: some View {
        switch item {
        case .meal(let meal):
            MealCard(meal: meal)
                .riverCardStyle(index: cardIndex, type: .meal)
                .onTapGesture { onMealTap?(meal) }
        case .healthKitMeal(let meal):
            HealthKitMealTimelineCard(meal: meal)
        case .eventGroup(let group):
            ConsumableEventTimelineCard(group: group)
                .onTapGesture { onEventGroupTap?(group) }
        case .insight(let insight):
            InsightTimelineCard(insight: insight)
                .riverCardStyle(index: cardIndex, type: .insight)
                .onTapGesture { onInsightTap?(insight) }
        case .workout(let workout):
            WorkoutTimelineCard(workout: workout)
                .riverCardStyle(index: cardIndex, type: .workout)
                .onTapGesture { onWorkoutTap?(workout) }
        case .sleep(let sleep):
            SleepTimelineCard(sleep: sleep)
                .riverCardStyle(index: cardIndex, type: .sleep)
                .onTapGesture { onSleepTap?(sleep) }
        case .vibe(let vibe):
            VibeTimelineCard(vibe: vibe)
                .riverCardStyle(index: cardIndex, type: .vibe)
                .onTapGesture { onVibeTap?(vibe) }
        }
    }
}

// MARK: - Consumable Event Timeline Card

struct ConsumableEventTimelineCard: View {
    let group: ConsumableEventGroup
    
    var body: some View {
        HStack(spacing: 12) {
            MonchIconView(token: group.kind.icon, size: 32)
            
            Text(group.timestamp, format: .dateTime.hour().minute())
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.displayTitle)
                    .font(.Monch.headline)
                
                Text(group.count > 1 ? "Repeated entries grouped together" : "Atomic event")
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
                
                Text(group.detailContextTag)
                    .font(.Monch.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.14))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accentColor.opacity(0.18), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
    
    private var accentColor: Color {
        switch group.kind {
        case .caffeine: return Color.Monch.sage
        case .alcohol: return Color.Monch.coral
        }
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: MealLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Kawaii meal icon
            Image("meal_kawaii")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .accessibilityLabel("Meal")
            
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
                        .foregroundStyle(.primary)  // Ensure dark text
                    
                    // Auto-tags as emojis
                    if !meal.autoTags.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(meal.autoTags, id: \.self) { tag in
                                Image(systemName: tagSymbol(tag))
                                    .font(.caption2)
                                    .foregroundStyle(Color.Monch.sage)
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
        .contentShape(Rectangle())
    }
    
    /// Convert tag name to SF Symbol for compact display
    private func tagSymbol(_ tag: String) -> String {
        switch tag {
        case "refeed": return "figure.strengthtraining.traditional"
        case "late-night": return "moon.stars.fill"
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "high-carb": return "bolt.fill"
        case "alcohol-event": return "wineglass.fill"
        default: return "tag.fill"
        }
    }
}

struct HealthKitMealTimelineCard: View {
    let meal: ImportedMealEvent
    
    var body: some View {
        HStack(spacing: 12) {
            MonchIconView(token: .asset("meal_kawaii"), size: 32)
                .opacity(0.9)
            
            Text(meal.timestamp, format: .dateTime.hour().minute())
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.title)
                    .font(.Monch.headline)
                
                if meal.hasNutritionDetails {
                    Text(importedSummary)
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(sourceLabel)
                    .font(.Monch.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.Monch.periwinkle.opacity(0.18))
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.Monch.periwinkle.opacity(0.18), lineWidth: 1)
                )
        )
    }
    
    private var sourceLabel: String {
        if let sourceName = meal.sourceName, !sourceName.isEmpty {
            return "from \(sourceName)"
        }
        return "imported from Health"
    }
    
    private var importedSummary: String {
        var parts: [String] = []
        
        if meal.calories > 0 {
            parts.append("\(Int(meal.calories.rounded())) kcal")
        }
        if meal.carbs > 0 {
            parts.append("\(Int(meal.carbs.rounded()))g carbs")
        }
        if meal.protein > 0 {
            parts.append("\(Int(meal.protein.rounded()))g protein")
        }
        if meal.fat > 0 {
            parts.append("\(Int(meal.fat.rounded()))g fat")
        }
        
        return parts.isEmpty ? "Imported meal event" : parts.joined(separator: " • ")
    }
}

// MARK: - Insight Timeline Card

struct InsightTimelineCard: View {
    let insight: InsightEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Kawaii insight icon based on type
            insightKawaiiIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .accessibilityLabel(insight.type.displayTitle)
            
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
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .strokeBorder(insightColor.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
    
    private var insightColor: Color {
        switch insight.type {
        case .sugarSpike, .anxietyMimic: return Color.Monch.coral
        case .caffeineJitter: return Color.Monch.sage
        case .digestionDebt, .deepSleepRobber: return Color.Monch.periwinkle
        case .muscleSponge, .goodSpike, .zone2Drain: return Color.Monch.sage
        // HRV-Powered insights
        case .recoveryGap, .mealImpactScore, .alcoholImpact: return Color.Monch.coral
        case .stressBuffer, .fastingBenefit, .morningReadiness: return Color.Monch.sage
        case .mineralGap, .brainFogForecast: return Color.Monch.periwinkle
        }
    }
    
    private var insightKawaiiIcon: Image {
        switch insight.type {
        case .sugarSpike, .anxietyMimic:
            return Image("insight_spike_kawaii")
        case .muscleSponge, .goodSpike, .zone2Drain:
            return Image("insight_recovery_kawaii")
        case .caffeineJitter:
            return Image("coffee_kawaii")
        case .digestionDebt, .deepSleepRobber:
            return Image("sleep_kawaii")
        // HRV-Powered insights - use dedicated kawaii icons
        case .morningReadiness:
            return Image("hrv_high_kawaii")
        case .recoveryGap, .mealImpactScore:
            return Image("hrv_low_kawaii")
        case .brainFogForecast:
            return Image("brain_fog_kawaii")
        case .stressBuffer, .fastingBenefit:
            return Image("fasting_kawaii")
        case .alcoholImpact:
            return Image("alcohol_kawaii")
        case .mineralGap:
            return Image("mineral_kawaii")
        }
    }
}

// MARK: - Workout Timeline Card

struct WorkoutTimelineCard: View {
    let workout: WorkoutLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Kawaii workout icon
            MonchIconView(token: workout.category.iconToken, size: 32)
            
            // Time
            Text(workout.startTime, format: .dateTime.hour().minute())
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
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
        .contentShape(Rectangle())
    }
}

// MARK: - Sleep Timeline Card

struct SleepTimelineCard: View {
    let sleep: SleepLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Kawaii sleep icon
            Image("sleep_kawaii")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .accessibilityLabel("Sleep")
            
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
            
            MonchIconView(token: .symbol(vibe.symbolName), size: 24, tint: Color.Monch.sage)
            
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
            
        }
        .padding()
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

// MARK: - Meal Event Placeholder

struct FoodLoggerPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Meal Events",
                systemImage: "fork.knife",
                description: Text("Use the meal event flow instead.")
            )
            .navigationTitle("Log Meal Event")
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

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
