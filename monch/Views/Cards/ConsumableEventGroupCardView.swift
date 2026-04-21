//
//  ConsumableEventGroupCardView.swift
//  monch
//
//  Detail card for grouped caffeine/alcohol timeline events.
//

import SwiftUI

struct ConsumableEventGroupCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    let group: ConsumableEventGroup
    let onIncrement: (MealLog) -> MealLog?
    let onRemoveLatest: (MealLog) -> Void
    let onDeleteEvent: (MealLog) -> Void
    
    @State private var events: [MealLog]
    
    init(
        group: ConsumableEventGroup,
        onIncrement: @escaping (MealLog) -> MealLog?,
        onRemoveLatest: @escaping (MealLog) -> Void,
        onDeleteEvent: @escaping (MealLog) -> Void
    ) {
        self.group = group
        self.onIncrement = onIncrement
        self.onRemoveLatest = onRemoveLatest
        self.onDeleteEvent = onDeleteEvent
        self._events = State(initialValue: group.events.sorted(by: { $0.timestamp > $1.timestamp }))
    }
    
    private var latestEvent: MealLog? {
        events.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
    
    var body: some View {
        CardDetailShell(
            title: group.displayTitle,
            icon: group.kind.icon,
            timestamp: latestEvent?.timestamp ?? group.timestamp,
            contextTag: events.count == 1 ? "1 logged" : "\(events.count) logged",
            mood: group.kind.tint
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                countSection
                entryListSection
            }
        }
    }
    
    private var countSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("count")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.md) {
                Button {
                    removeLatestEntry()
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color.Monch.coral.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(events.isEmpty)
                
                VStack(spacing: 4) {
                    Text("\(events.count)")
                        .font(.Monch.title2)
                        .fontWeight(.bold)
                    Text(events.count == 1 ? "event" : "events")
                        .font(.Monch.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    addEntry()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color.Monch.sage.opacity(0.18))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Text("Each tap stays atomic under the hood, but repeated entries can be adjusted here.")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var entryListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("entries")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(events.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { event in
                    HStack {
                        Text(event.name)
                            .font(.Monch.body)
                        
                        Spacer()
                        
                        Text(event.timestamp, style: .time)
                            .font(.Monch.caption)
                            .foregroundStyle(.secondary)
                        
                        Button(role: .destructive) {
                            delete(event)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
    }
    
    private func addEntry() {
        guard let template = latestEvent ?? events.first ?? group.events.first else { return }
        guard let newEvent = onIncrement(template) else { return }
        events.insert(newEvent, at: 0)
        HapticManager.shared.play(.success)
    }
    
    private func removeLatestEntry() {
        guard let latest = latestEvent else { return }
        onRemoveLatest(latest)
        events.removeAll { $0.id == latest.id }
        if events.isEmpty {
            dismiss()
        } else {
            HapticManager.shared.play(.light)
        }
    }
    
    private func delete(_ event: MealLog) {
        onDeleteEvent(event)
        events.removeAll { $0.id == event.id }
        if events.isEmpty {
            dismiss()
        } else {
            HapticManager.shared.play(.light)
        }
    }
}
