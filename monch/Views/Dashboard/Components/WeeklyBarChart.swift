//
//  WeeklyBarChart.swift
//  monch
//
//  7-day stacked bar chart showing daily calorie/macro distribution.
//

import SwiftUI

struct WeeklyBarChart: View {
    let dailyData: [DailySummary]
    
    @State private var appeared = false
    @State private var selectedDay: DailySummary?
    
    private var dataHash: Int {
        var hasher = Hasher()
        for day in dailyData {
            hasher.combine(day.calories)
            hasher.combine(day.date)
        }
        return hasher.finalize()
    }
    
    private let maxCalories: Double = 2500 // Reference for bar height
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("weekly overview")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(dailyData) { day in
                    DayBar(
                        day: day,
                        maxCalories: maxCalories,
                        isSelected: selectedDay?.id == day.id,
                        appeared: appeared
                    )
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.3)) {
                            if selectedDay?.id == day.id {
                                selectedDay = nil
                            } else {
                                selectedDay = day
                            }
                        }
                    }
                }
            }
            .frame(height: 140)
            
            // Selected day detail
            if let selected = selectedDay {
                selectedDayDetail(for: selected)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
        .task(id: dataHash) {
            // Only reset animation if data actually changes
            appeared = false
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
            withAnimation(.spring(duration: 0.8)) {
                appeared = true
            }
        }
    }
    
    private func selectedDayDetail(for day: DailySummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.Monch.callout)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(day.vibe.emoji)
                Text(day.vibe.name)
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: Spacing.lg) {
                MacroStat(color: Color.Monch.coral, label: "Carbs", value: "\(Int(day.macros.carbs))g")
                MacroStat(color: Color.Monch.sage, label: "Protein", value: "\(Int(day.macros.protein))g")
                MacroStat(color: Color.Monch.periwinkle, label: "Fat", value: "\(Int(day.macros.fat))g")
            }
        }
        .padding(.top, Spacing.sm)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Day Bar

private struct DayBar: View {
    let day: DailySummary
    let maxCalories: Double
    let isSelected: Bool
    let appeared: Bool
    
    private var barHeight: CGFloat {
        guard maxCalories > 0 else { return 0 }
        let ratio = min(day.calories / maxCalories, 1.0)
        return CGFloat(ratio) * 100
    }
    
    private var hasData: Bool {
        day.calories > 0
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Bar
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(.secondary.opacity(0.1))
                    .frame(height: 100)
                
                if hasData {
                    // Stacked macro bar
                    VStack(spacing: 0) {
                        // Fat (top)
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.Monch.periwinkle.opacity(0.8))
                            .frame(height: appeared ? barHeight * day.macros.fatPercent : 0)
                        
                        // Protein (middle)
                        Rectangle()
                            .fill(Color.Monch.sage.opacity(0.8))
                            .frame(height: appeared ? barHeight * day.macros.proteinPercent : 0)
                        
                        // Carbs (bottom)
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.Monch.coral.opacity(0.8))
                            .frame(height: appeared ? barHeight * day.macros.carbsPercent : 0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
            }
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.Monch.sage, lineWidth: isSelected ? 2 : 0)
            )
            
            // Day label
            Text(day.shortDayLetter)
                .font(.Monch.caption2)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.Monch.sage : .secondary)
        }
    }
}

// MARK: - Macro Stat

private struct MacroStat: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(value)
                .font(.Monch.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    WeeklyBarChart(dailyData: [
        DailySummary(date: Date().addingTimeInterval(-6*86400), calories: 1800, vibe: .balanced, macros: MacroBreakdown(carbs: 200, protein: 100, fat: 60)),
        DailySummary(date: Date().addingTimeInterval(-5*86400), calories: 2100, vibe: .thriving, macros: MacroBreakdown(carbs: 220, protein: 120, fat: 70)),
        DailySummary(date: Date().addingTimeInterval(-4*86400), calories: 1600, vibe: .steady, macros: MacroBreakdown(carbs: 180, protein: 80, fat: 55)),
        DailySummary(date: Date().addingTimeInterval(-3*86400), calories: 1900, vibe: .balanced, macros: MacroBreakdown(carbs: 200, protein: 110, fat: 65)),
        DailySummary(date: Date().addingTimeInterval(-2*86400), calories: 2200, vibe: .learning, macros: MacroBreakdown(carbs: 280, protein: 90, fat: 75)),
        DailySummary(date: Date().addingTimeInterval(-1*86400), calories: 1700, vibe: .steady, macros: MacroBreakdown(carbs: 190, protein: 95, fat: 50)),
        DailySummary(date: Date(), calories: 1400, vibe: .balanced, macros: MacroBreakdown(carbs: 150, protein: 80, fat: 45))
    ])
    .padding()
}
