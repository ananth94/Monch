//
//  InsightCardView.swift
//  monch
//
//  Detail card for viewing insight events.
//  Shows explanation, linked entries, and quick actions.
//

import SwiftUI
import SwiftData

struct InsightCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let insight: InsightEvent
    
    @State private var linkedMeal: MealLog?
    
    var body: some View {
        CardDetailShell(
            title: insight.type.displayTitle,
            icon: insight.type.icon,
            timestamp: insight.timestamp,
            contextTag: severityTag,
            mood: insight.type.mood,
            onDelete: nil
        ) {
            VStack(spacing: Spacing.lg) {
                // Explanation
                explanationSection
                
                // Linked Entries
                if linkedMeal != nil {
                    linkedEntriesSection
                }
                
                // Quick Actions
                quickActionsSection
                
                // Dismiss
                dismissSection
            }
        }
        .task {
            await loadLinkedMeal()
        }
    }
    
    // MARK: - Severity Tag
    
    private var severityTag: String? {
        // severity is 0.0 to 1.0 in the model
        if insight.severity < 0.33 { return "🟢 Mild" }
        if insight.severity < 0.66 { return "🟡 Moderate" }
        return "🔶 Significant"
    }
    
    // MARK: - Explanation Section
    
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(insight.message)
                .font(.Monch.body)
            
            if let recommendation = insight.type.recommendation {
                Text(recommendation)
                    .font(.Monch.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.xs)
            }
        }
    }
    
    // MARK: - Linked Entries Section
    
    private var linkedEntriesSection: some View {
        MonchCardSection("linked entries", icon: "link") {
            if let meal = linkedMeal {
                LinkedMealRow(meal: meal)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(insight.type.quickActions, id: \.label) { action in
                MonchPrimaryButton(action.label, icon: action.icon) {
                    // TODO: Wire up actions (open food logger, start workout, etc.)
                }
            }
        }
    }
    
    // MARK: - Dismiss Section
    
    private var dismissSection: some View {
        MonchSecondaryButton("Dismiss") {
            // Mark insight as dismissed
            insight.isDismissed = true
            dismiss()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadLinkedMeal() async {
        guard let mealID = insight.associatedMealID else { return }
        
        let predicate = #Predicate<MealLog> { meal in
            meal.id == mealID
        }
        let descriptor = FetchDescriptor<MealLog>(predicate: predicate)
        
        do {
            let meals = try modelContext.fetch(descriptor)
            linkedMeal = meals.first
        } catch {
            print("Failed to load linked meal: \(error)")
        }
    }
}

// MARK: - Linked Meal Row

private struct LinkedMealRow: View {
    let meal: MealLog
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("🍽️")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.Monch.headline)
                    .lineLimit(1)
                
                Text(meal.timestamp, format: .dateTime.hour().minute())
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// MARK: - InsightType Extensions

extension InsightType {
    var displayTitle: String {
        switch self {
        case .sugarSpike: return "Sugar Spike Detected"
        case .digestionDebt: return "Digestion Debt"
        case .muscleSponge: return "Muscle Sponge"
        case .anxietyMimic: return "Anxiety Mimic"
        case .goodSpike: return "Good Spike"
        case .deepSleepRobber: return "Deep Sleep Robber"
        case .caffeineJitter: return "Caffeine Alert"
        case .zone2Drain: return "Glucose Sink"
        // HRV-Powered (Sprint 12)
        case .recoveryGap: return "Recovery Gap"
        case .stressBuffer: return "Stress Buffer"
        case .mineralGap: return "Mineral Check"
        case .brainFogForecast: return "Focus Forecast"
        case .morningReadiness: return "Morning Readiness"
        case .mealImpactScore: return "Meal Impact"
        case .alcoholImpact: return "Alcohol Impact"
        case .fastingBenefit: return "Fasting Benefit"
        }
    }
    
    var icon: String {
        switch self {
        case .sugarSpike: return "💡"
        case .digestionDebt: return "🌙"
        case .muscleSponge: return "💪"
        case .anxietyMimic: return "❤️"
        case .goodSpike: return "✅"
        case .deepSleepRobber: return "😴"
        case .caffeineJitter: return "☕"
        case .zone2Drain: return "🏃"
        // HRV-Powered (Sprint 12)
        case .recoveryGap: return "🔋"
        case .stressBuffer: return "🛡️"
        case .mineralGap: return "💊"
        case .brainFogForecast: return "🧠"
        case .morningReadiness: return "🌅"
        case .mealImpactScore: return "📊"
        case .alcoholImpact: return "🍷"
        case .fastingBenefit: return "🌿"
        }
    }
    
    var mood: GradientMood {
        switch self {
        case .sugarSpike, .anxietyMimic: return .acute
        case .caffeineJitter, .zone2Drain: return .recovery
        case .digestionDebt, .deepSleepRobber: return .sleep
        case .muscleSponge, .goodSpike: return .recovery
        // HRV-Powered (Sprint 12)
        case .recoveryGap, .mealImpactScore, .alcoholImpact: return .acute
        case .stressBuffer, .fastingBenefit, .morningReadiness: return .recovery
        case .mineralGap, .brainFogForecast: return .sleep
        }
    }
    
    var recommendation: String? {
        switch self {
        case .sugarSpike:
            return "A 10-minute walk now could help flatten the curve."
        case .digestionDebt:
            return "Try closing the kitchen earlier tomorrow to support deeper sleep."
        case .muscleSponge:
            return "Your body is primed to absorb protein right now!"
        case .anxietyMimic:
            return "This might feel like anxiety but could be food-related. Check your recent meals."
        case .goodSpike:
            return nil // No action needed
        case .deepSleepRobber:
            return "Late meals may have reduced your deep sleep. Try eating earlier."
        case .caffeineJitter:
            return "Perfect time for focused work! The caffeine is doing its job."
        case .zone2Drain:
            return "You can handle more carbs tonight—your muscles are primed."
        // HRV-Powered (Sprint 12)
        case .recoveryGap:
            return "Fuel up with a protein-rich meal to support HRV recovery."
        case .stressBuffer:
            return nil // Positive insight
        case .mineralGap:
            return "Consider checking your Magnesium or Zinc levels."
        case .brainFogForecast:
            return "Tackle important work early today before focus dips."
        case .morningReadiness:
            return nil // Informational
        case .mealImpactScore:
            return "Consider lighter meals or different food combinations."
        case .alcoholImpact:
            return "Give yourself an extra rest day to recover."
        case .fastingBenefit:
            return nil // Positive insight
        }
    }
    
    struct QuickAction {
        let label: String
        let icon: String
    }
    
    var quickActions: [QuickAction] {
        switch self {
        case .sugarSpike:
            return [
                QuickAction(label: "Start Walk", icon: "figure.walk"),
                QuickAction(label: "Log Snack", icon: "carrot")
            ]
        case .digestionDebt:
            return [
                QuickAction(label: "Set Kitchen Close Reminder", icon: "moon.zzz")
            ]
        case .muscleSponge:
            return [
                QuickAction(label: "Log Protein", icon: "fork.knife")
            ]
        case .anxietyMimic:
            return [
                QuickAction(label: "Log How You Feel", icon: "face.smiling")
            ]
        case .goodSpike:
            return [] // No actions needed
        case .deepSleepRobber:
            return [
                QuickAction(label: "Set Eating Reminder", icon: "clock")
            ]
        case .caffeineJitter:
            return [] // Positive alert, no action needed
        case .zone2Drain:
            return [
                QuickAction(label: "Log Meal", icon: "fork.knife")
            ]
        // HRV-Powered (Sprint 12)
        case .recoveryGap:
            return [
                QuickAction(label: "Log Meal", icon: "fork.knife")
            ]
        case .stressBuffer, .fastingBenefit, .morningReadiness:
            return [] // Positive insights, no action needed
        case .mineralGap:
            return [] // Chronic insight, no immediate action
        case .brainFogForecast:
            return [] // Informational
        case .mealImpactScore:
            return [] // Informational
        case .alcoholImpact:
            return [] // Informational
        }
    }
}

// MARK: - Preview

#Preview {
    let insight = InsightEvent(
        type: .sugarSpike,
        message: "Your heart rate spiked +18bpm 30 minutes after lunch.",
        associatedMealID: nil
    )
    
    return InsightCardView(insight: insight)
        .modelContainer(for: [MealLog.self, InsightEvent.self], inMemory: true)
}
