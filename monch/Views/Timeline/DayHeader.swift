//
//  DayHeader.swift
//  monch
//
//  Sticky header separating days in the Timeline.
//  Shows "Today", "Yesterday", or formatted date.
//

import SwiftUI

struct DayHeader: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.Monch.title3)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Optional: Day summary indicator
            if isToday {
                Text("Now")
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }
    
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

#Preview("Today") {
    DayHeader(date: Date())
}

#Preview("Yesterday") {
    DayHeader(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
}

#Preview("Last Week") {
    DayHeader(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
}
