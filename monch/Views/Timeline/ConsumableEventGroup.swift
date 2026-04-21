//
//  ConsumableEventGroup.swift
//  monch
//
//  Timeline grouping model for repeated caffeine/alcohol events.
//

import Foundation

extension ConsumableEventKind {
    var displayName: String {
        switch self {
        case .caffeine: return "Caffeine"
        case .alcohol: return "Alcohol"
        }
    }
    
    var timelineTitle: String {
        switch self {
        case .caffeine: return "Caffeine Event"
        case .alcohol: return "Alcohol Event"
        }
    }
    
    var icon: MonchIconToken {
        switch self {
        case .caffeine: return .asset("coffee_kawaii")
        case .alcohol: return .asset("alcohol_kawaii")
        }
    }
    
    var tint: GradientMood {
        switch self {
        case .caffeine: return .recovery
        case .alcohol: return .acute
        }
    }
}

struct ConsumableEventGroup: Identifiable {
    let kind: ConsumableEventKind
    let name: String
    let events: [MealLog]
    
    var id: String {
        "\(kind.rawValue)-\(name)-\(latestEvent.id.uuidString)"
    }
    
    var latestEvent: MealLog {
        events.max(by: { $0.timestamp < $1.timestamp }) ?? events[0]
    }
    
    var timestamp: Date {
        latestEvent.timestamp
    }
    
    var count: Int {
        events.count
    }
    
    var displayTitle: String {
        count > 1 ? "\(name) x\(count)" : name
    }
    
    var detailContextTag: String {
        count > 1 ? "\(count) entries" : "1 entry"
    }
}
