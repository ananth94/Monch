//
//  MetabolicCalendar.swift
//  monch
//
//  Monthly heat map calendar with vibe-tier colors for each day.
//

import SwiftUI

struct MetabolicCalendar: View {
    let calendar: [Date: MetabolicTier]
    var onTapDay: ((Date) -> Void)?
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("metabolic calendar")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: Spacing.sm) {
                // Weekday headers
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.Monch.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                tier: calendar[Calendar.current.startOfDay(for: date)],
                                isToday: Calendar.current.isDateInToday(date)
                            )
                            .onTapGesture {
                                onTapDay?(date)
                            }
                        } else {
                            // Empty cell for padding
                            Color.clear
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.ultraThinMaterial)
            )
            
            // Legend
            HStack(spacing: Spacing.lg) {
                LegendItem(tier: .thriving)
                LegendItem(tier: .balanced)
                LegendItem(tier: .steady)
                LegendItem(tier: .learning)
            }
        }
    }
    
    // MARK: - Days in Month
    
    private var daysInMonth: [Date?] {
        let cal = Calendar.current
        let now = Date()
        
        guard let monthInterval = cal.dateInterval(of: .month, for: now),
              let firstWeek = cal.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        
        // Add leading empty cells for days before the month starts
        let leadingDays = cal.dateComponents([.weekday], from: monthInterval.start).weekday! - 1
        for _ in 0..<leadingDays {
            days.append(nil)
        }
        
        // Add days of the month
        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        
        return days
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let tier: MetabolicTier?
    let isToday: Bool
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(backgroundColor)
                .frame(width: 28, height: 28)
            
            // Today indicator
            if isToday {
                Circle()
                    .stroke(Color.Monch.sage, lineWidth: 2)
                    .frame(width: 28, height: 28)
            }
            
            // Day number
            Text("\(dayNumber)")
                .font(.Monch.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(tier != nil ? .primary : .secondary)
        }
    }
    
    private var backgroundColor: Color {
        guard let tier = tier else {
            return .secondary.opacity(0.1)
        }
        
        switch tier {
        case .thriving: return Color.Monch.sage.opacity(0.6)
        case .balanced: return Color.Monch.sage.opacity(0.3)
        case .steady: return .secondary.opacity(0.2)
        case .learning: return Color.Monch.coral.opacity(0.3)
        case .resetting: return Color.Monch.periwinkle.opacity(0.3)
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let tier: MetabolicTier
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tierColor)
                .frame(width: 8, height: 8)
            Text(tier.name)
                .font(.Monch.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var tierColor: Color {
        switch tier {
        case .thriving: return Color.Monch.sage.opacity(0.6)
        case .balanced: return Color.Monch.sage.opacity(0.3)
        case .steady: return .secondary.opacity(0.3)
        case .learning: return Color.Monch.coral.opacity(0.3)
        case .resetting: return Color.Monch.periwinkle.opacity(0.3)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockCalendar: [Date: MetabolicTier] = {
        var cal: [Date: MetabolicTier] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for offset in -20..<0 {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                let tiers: [MetabolicTier] = [.thriving, .balanced, .steady, .learning, .resetting]
                cal[date] = tiers.randomElement()!
            }
        }
        return cal
    }()
    
    return MetabolicCalendar(calendar: mockCalendar)
        .padding()
}
