//
//  TodayView.swift
//  monch
//
//  Today's metabolic status: vibe indicator, quick stats, insights, and macros.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    let summary: TodaySummary
    var selectedDate: Date = Date()
    
    @ObservedObject private var insightEngine = InsightEngine.shared
    @State private var selectedInsight: InsightEvent?
    @State private var showingMealLogger = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Mascot Header
                MascotHeader(mood: insightEngine.currentMood) { }
                    .padding(.horizontal)
                
                if summary.hasData {
                    // Metabolic Vibe Indicator
                    MetabolicVibeIndicator(tier: summary.vibe)
                        .padding(.horizontal)
                    
                    // Quick Stats Row
                    quickStatsSection
                    
                    // Today's Insights
                    if !summary.insights.isEmpty {
                        insightsSection
                    }
                    
                    // Macro Breakdown
                    if summary.macros.totalCalories > 0 {
                        MacroBreakdownRing(macros: summary.macros)
                            .padding(.horizontal)
                    }
                } else {
                    // Empty State
                    emptyState
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedInsight) { insight in
            InsightCardView(insight: insight)
        }
        .sheet(isPresented: $showingMealLogger) {
            MealEventLogView { meal in
                modelContext.insert(meal)
                Task { @MainActor in
                    await InsightEngine.shared.analyzeMeal(meal, in: modelContext)
                }
            }
        }
    }
    
    // MARK: - Quick Stats
    
    private var quickStatsSection: some View {
        HStack(spacing: Spacing.md) {
            QuickStatPill(
                icon: .asset("meal_kawaii"),
                value: "\(summary.mealCount)",
                label: summary.mealCount == 1 ? "meal" : "meals"
            )
            
            if let sleep = summary.sleepDuration {
                QuickStatPill(
                    icon: .asset("sleep_kawaii"),
                    value: formatDuration(sleep),
                    label: "sleep"
                )
            }
            
            if summary.zone2Minutes > 0 {
                QuickStatPill(
                    icon: .asset("workout_kawaii"),
                    value: "\(summary.zone2Minutes)m",
                    label: "zone 2"
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(selectedDate.isToday ? "today's insights" : "day insights")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ForEach(summary.insights) { insight in
                InsightRowCard(insight: insight)
                    .onTapGesture {
                        selectedInsight = insight
                    }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            MonchIconView(token: .asset("meal_kawaii"), size: 60)
            
            Text(emptyStateCopy)
                .font(.Monch.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button {
                showingMealLogger = true
            } label: {
                Label("Log a Meal", systemImage: "plus")
                    .font(.Monch.callout)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.Monch.sage)
        }
        .padding(.vertical, Spacing.xl)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private var emptyStateCopy: String {
        if selectedDate.isToday {
            return "Your metabolic story starts\nwith your first meal event."
        }
        return "No day data yet for \(selectedDate.formatted(date: .abbreviated, time: .omitted))."
    }
}

// MARK: - Quick Stat Pill

private struct QuickStatPill: View {
    let icon: MonchIconToken
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            MonchIconView(token: icon, size: 30)
            Text(value)
                .font(.Monch.callout)
                .fontWeight(.semibold)
            Text(label)
                .font(.Monch.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Insight Row Card

private struct InsightRowCard: View {
    let insight: InsightEvent
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            MonchIconView(token: insight.type.iconToken, size: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.type.displayTitle)
                    .font(.Monch.callout)
                    .fontWeight(.medium)
                Text(insight.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.Monch.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Preview

#Preview {
    TodayView(summary: TodaySummary(
        vibe: .balanced,
        calories: 1420,
        sleepDuration: 7 * 3600 + 12 * 60,
        zone2Minutes: 35,
        insights: [],
        macros: MacroBreakdown(carbs: 180, protein: 95, fat: 55),
        mealCount: 3
    ))
}
