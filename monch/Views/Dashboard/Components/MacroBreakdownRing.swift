//
//  MacroBreakdownRing.swift
//  monch
//
//  Donut chart displaying Carbs/Protein/Fat percentages.
//

import SwiftUI

struct MacroBreakdownRing: View {
    let macros: MacroBreakdown
    
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("macro breakdown")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.lg) {
                // Donut chart
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.1)
                    
                    // Carbs segment (Coral)
                    Circle()
                        .trim(from: 0, to: appeared ? macros.carbsPercent : 0)
                        .stroke(
                            Color.Monch.coral,
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    // Protein segment (Sage)
                    Circle()
                        .trim(from: 0, to: appeared ? macros.proteinPercent : 0)
                        .stroke(
                            Color.Monch.sage,
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90 + 360 * macros.carbsPercent))
                    
                    // Fat segment (Periwinkle)
                    Circle()
                        .trim(from: 0, to: appeared ? macros.fatPercent : 0)
                        .stroke(
                            Color.Monch.periwinkle,
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90 + 360 * (macros.carbsPercent + macros.proteinPercent)))
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(macros.totalCalories))")
                            .font(.Monch.title3)
                            .fontWeight(.semibold)
                        Text("kcal")
                            .font(.Monch.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
                .animation(.spring(duration: 0.8), value: appeared)
                
                // Legend
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    MacroLegendRow(
                        color: Color.Monch.coral,
                        name: "Carbs",
                        grams: Int(macros.carbs),
                        percent: Int(macros.carbsPercent * 100)
                    )
                    MacroLegendRow(
                        color: Color.Monch.sage,
                        name: "Protein",
                        grams: Int(macros.protein),
                        percent: Int(macros.proteinPercent * 100)
                    )
                    MacroLegendRow(
                        color: Color.Monch.periwinkle,
                        name: "Fat",
                        grams: Int(macros.fat),
                        percent: Int(macros.fatPercent * 100)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Legend Row

private struct MacroLegendRow: View {
    let color: Color
    let name: String
    let grams: Int
    let percent: Int
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(name)
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(grams)g")
                .font(.Monch.caption)
                .fontWeight(.medium)
            
            Text("(\(percent)%)")
                .font(.Monch.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    MacroBreakdownRing(macros: MacroBreakdown(carbs: 180, protein: 95, fat: 55))
        .padding()
}
