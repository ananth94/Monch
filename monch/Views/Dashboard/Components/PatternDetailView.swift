//
//  PatternDetailView.swift
//  monch
//
//  Modal showing entries that contributed to a detected pattern.
//  Displays pattern summary, mini-timeline of affected entries, and action buttons.
//

import SwiftUI
import SwiftData

struct PatternDetailView: View {
    let pattern: Pattern
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \MealLog.timestamp, order: .reverse) private var allMeals: [MealLog]
    @Query(sort: \InsightEvent.timestamp, order: .reverse) private var allInsights: [InsightEvent]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Pattern Header
                    patternHeader
                    
                    Divider()
                    
                    // Impact Section
                    impactSection
                    
                    // Linked Entries
                    if !linkedMeals.isEmpty || !linkedInsights.isEmpty {
                        linkedEntriesSection
                    }
                    
                    // Suggestion Section
                    suggestionSection
                    
                    Spacer(minLength: Spacing.lg)
                }
                .padding()
            }
            .background(Color.Monch.cream.opacity(0.5).ignoresSafeArea())
            .navigationTitle("Pattern Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Pattern Header
    
    private var patternHeader: some View {
        HStack(spacing: Spacing.md) {
            MonchIconView(token: pattern.icon, size: 40, tint: patternBackgroundColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.name)
                    .font(.Monch.title3)
                    .fontWeight(.semibold)
                
                Text(pattern.description)
                    .font(.Monch.body)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(patternBackgroundColor.opacity(0.15))
        )
    }
    
    // MARK: - Impact Section
    
    private var impactSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Impact")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.sm) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.body)
                    .foregroundStyle(Color.Monch.coral)
                
                Text(pattern.impact)
                    .font(.Monch.callout)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.Monch.coral.opacity(0.1))
            )
        }
    }
    
    // MARK: - Linked Entries Section
    
    private var linkedEntriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Linked Entries")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: Spacing.xs) {
                ForEach(linkedMeals) { meal in
                    LinkedMealRow(meal: meal)
                }
                
                ForEach(linkedInsights) { insight in
                    LinkedInsightRow(insight: insight)
                }
            }
        }
    }
    
    // MARK: - Suggestion Section
    
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Suggestion")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.body)
                    .foregroundStyle(Color.Monch.sage)
                
                Text(pattern.suggestion)
                    .font(.Monch.callout)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.Monch.sage.opacity(0.1))
            )
            
            // Set Goal Button (deferred action)
            Button {
                // TODO: Deep link to goal/reminder creation
            } label: {
                HStack {
                    Image(systemName: "bell.badge")
                    Text("Set Reminder")
                }
                .font(.Monch.callout)
                .fontWeight(.medium)
                .foregroundStyle(Color.Monch.sage)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(Color.Monch.sage, lineWidth: 1)
                )
            }
            .padding(.top, Spacing.xs)
        }
    }
    
    // MARK: - Data Filtering
    
    private var linkedMeals: [MealLog] {
        allMeals.filter { pattern.linkedEntryIDs.contains($0.id) }
    }
    
    private var linkedInsights: [InsightEvent] {
        allInsights.filter { pattern.linkedEntryIDs.contains($0.id) }
    }
    
    // MARK: - Colors
    
    private var patternBackgroundColor: Color {
        switch pattern.loopColor {
        case .acute: return Color.Monch.coral
        case .recovery: return Color.Monch.sage
        case .sleep: return Color.Monch.periwinkle
        case .neutral: return .secondary
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
                    .font(.Monch.callout)
                    .fontWeight(.medium)
                
                Text(meal.timestamp, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if meal.hasMacros {
                Text(meal.macroSummary)
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Linked Insight Row

private struct LinkedInsightRow: View {
    let insight: InsightEvent
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            MonchIconView(token: insight.type.iconToken, size: 24, tint: insightColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.type.displayTitle)
                    .font(.Monch.callout)
                    .fontWeight(.medium)
                
                Text(insight.timestamp, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(insightColor.opacity(0.1))
        )
    }
    
    private var insightColor: Color {
        switch insight.type {
        case .sugarSpike, .anxietyMimic: return Color.Monch.coral
        case .caffeineJitter: return Color.Monch.sage
        case .digestionDebt, .deepSleepRobber: return Color.Monch.periwinkle
        case .muscleSponge, .goodSpike, .zone2Drain: return Color.Monch.sage
        case .recoveryGap, .mealImpactScore, .alcoholImpact: return Color.Monch.coral
        case .stressBuffer, .fastingBenefit, .morningReadiness: return Color.Monch.sage
        case .mineralGap, .brainFogForecast: return Color.Monch.periwinkle
        }
    }
}

// MARK: - Preview

#Preview("Pattern Detail") {
    PatternDetailView(pattern: Pattern(
        name: "Weekend Wind-Down",
        icon: .asset("sleep_kawaii"),
        description: "Late meals detected on Fri & Sat",
        impact: "~12% less Deep Sleep on those nights",
        suggestion: "Try closing the kitchen by 8pm on weekends",
        linkedEntryIDs: [],
        loopColor: .sleep
    ))
}
