//
//  DayHeader.swift
//  monch
//
//  River UI "Island" sticky header separating days in the Timeline.
//  Styled as sandbar in stream with time-based decorations.
//

import SwiftUI

struct DayHeader: View {
    let date: Date
    
    /// Optional: entries for this day to determine dominant time
    var entries: [Date] = []
    
    @State private var isSticky = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Time-based decoration
            decorationImage
                .frame(width: 20, height: 20)
            
            Text(formattedDate)
                .font(.Monch.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Optional: Day summary indicator
            if isToday {
                Text("Now")
                    .font(.Monch.caption)
                    .foregroundStyle(Color.Monch.sage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.Monch.sage.opacity(0.15))
                    )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(islandBackground)
        // Sticky effect: shadow appears when stuck
        .shadow(
            color: isSticky ? Color.black.opacity(0.08) : .clear,
            radius: isSticky ? 8 : 0,
            y: isSticky ? 4 : 0
        )
        .scaleEffect(isSticky ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isSticky)
    }
    
    // MARK: - Island Background (Sandbar styling)
    
    private var islandBackground: some View {
        ZStack {
            // Base island shape (flattened oval)
            Capsule()
                .fill(Color.Monch.sand)
            
            // Sand texture overlay
            Image("sand_texture")
                .resizable(resizingMode: .tile)
                .opacity(0.15)
                .clipShape(Capsule())
            
            // Subtle border
            Capsule()
                .strokeBorder(Color.Monch.cream, lineWidth: 1)
        }
    }
    
    // MARK: - Time-Based Decoration
    
    @ViewBuilder
    private var decorationImage: some View {
        let timeOfDay = dominantTimeOfDay
        
        switch timeOfDay {
        case .morning:
            Image("decoration_sun")
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .afternoon:
            Image("decoration_flower")
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .evening:
            Image("decoration_moon")
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .mixed:
            Image("decoration_pebbles")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
    
    // MARK: - Dominant Time Calculation
    
    private enum TimeOfDay {
        case morning   // 6am-12pm
        case afternoon // 12pm-6pm
        case evening   // 6pm-12am
        case mixed
    }
    
    private var dominantTimeOfDay: TimeOfDay {
        guard !entries.isEmpty else {
            // Default based on current time if no entries
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 6 && hour < 12 { return .morning }
            else if hour >= 12 && hour < 18 { return .afternoon }
            else if hour >= 18 { return .evening }
            else { return .mixed }
        }
        
        var morningCount = 0
        var afternoonCount = 0
        var eveningCount = 0
        
        for entryDate in entries {
            let hour = Calendar.current.component(.hour, from: entryDate)
            if hour >= 6 && hour < 12 {
                morningCount += 1
            } else if hour >= 12 && hour < 18 {
                afternoonCount += 1
            } else if hour >= 18 || hour < 6 {
                eveningCount += 1
            }
        }
        
        // Return dominant or mixed if no clear winner
        let max = Swift.max(morningCount, afternoonCount, eveningCount)
        if max == 0 { return .mixed }
        
        if morningCount == max { return .morning }
        if afternoonCount == max { return .afternoon }
        if eveningCount == max { return .evening }
        
        return .mixed
    }
    
    // MARK: - Date Formatting
    
    private var formattedDate: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isWithinWeek {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    private var isWithinWeek: Bool {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return date > weekAgo
    }
}

// MARK: - Sand Color Extension

extension Color.Monch {
    /// Warm sand color for island headers: #F5DEB3
    static let sand = Color(red: 245/255, green: 222/255, blue: 179/255)
}

// MARK: - Previews

#Preview("Today - Morning") {
    VStack {
        DayHeader(date: Date())
    }
    .padding()
    .background(Color.Monch.cream)
}

#Preview("Yesterday - Evening") {
    VStack {
        DayHeader(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            entries: [
                Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!,
                Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
            ]
        )
    }
    .padding()
    .background(Color.Monch.cream)
}
