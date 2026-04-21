//
//  MascotDetailView.swift
//  monch
//
//  "The Monch View" - Expanded detail sheet with hero mascot,
//  coaching text, data context, and quick actions.
//

import SwiftUI

struct MascotDetailView: View {
    let mood: MascotMoodState
    var onAction: ((String) -> Void)? = nil
    
    // Real data props
    var lastMealTimestamp: Date? = nil
    var hrDelta: Int? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MeshGradientBackground(mood: mood.gradientMood)
                    .opacity(0.5)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Mascot (200x200, animated)
                        MascotView(mood: mood, size: 200)
                            .padding(.top, 40)
                        
                        // Status Text
                        VStack(spacing: 8) {
                            Text(mood.statusText)
                                .font(.Monch.title)
                            
                            Text(coachingText)
                                .font(.Monch.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        // Data Summary
                        dataSummaryCard
                            .padding(.horizontal)
                        
                        // Quick Actions
                        quickActions
                            .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            // Haptic feedback on open
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }
    
    // MARK: - Coaching Text
    
    private var coachingText: String {
        switch mood {
        case .neutral:
            return "Your metabolism is stable. Great time to check in with how you're feeling."
        case .hungry:
            return "It's been a while since your last meal. Your body might appreciate some fuel."
        case .spiking:
            return "Your heart rate is elevated post-meal. A short walk could help smooth this out."
        case .crashing:
            return "Your energy might be dipping. A small snack could help stabilize things."
        case .sleepy:
            return "Your body is winding down for the day. Consider closing the kitchen soon."
        case .strong:
            return "You're in your anabolic window! Protein now will fuel muscle recovery."
        case .digesting:
            return "Your body is processing your last meal. Give it some time to do its work."
        }
    }
    
    // MARK: - Data Summary
    
    private var dataSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Context")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                DataPill(label: "Last meal", value: lastMealText)
                if let delta = hrDelta {
                    DataPill(label: "HR", value: delta >= 0 ? "+\(delta) bpm" : "\(delta) bpm")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var lastMealText: String {
        guard let timestamp = lastMealTimestamp else {
            return "No meals today"
        }
        let minutes = Int(Date().timeIntervalSince(timestamp) / 60)
        if minutes < 60 {
            return "\(minutes) min ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            if let primary = primaryAction {
                Button(action: { 
                    onAction?(primary.label)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: primary.icon)
                        Text(primary.label)
                    }
                    .font(.Monch.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.Monch.sage)
                    )
                }
            }
            
            if let secondary = secondaryAction {
                Button(action: { dismiss() }) {
                    Text(secondary)
                        .font(.Monch.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var primaryAction: (label: String, icon: String)? {
        switch mood {
        case .neutral, .hungry: return ("Log Meal Event", "fork.knife")
        case .spiking: return ("Add Walk", "figure.walk")
        case .crashing: return ("Quick Snack", "carrot")
        case .sleepy: return ("Close Kitchen", "moon.zzz")
        case .strong: return ("Log Protein", "dumbbell")
        case .digesting: return nil
        }
    }
    
    private var secondaryAction: String? {
        switch mood {
        case .spiking, .crashing: return "Dismiss"
        case .hungry: return "Set Reminder"
        default: return nil
        }
    }
}

// MARK: - Data Pill

struct DataPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.Monch.headline)
        }
    }
}

// MARK: - Previews

#Preview("Spiking") {
    MascotDetailView(mood: .spiking)
}

#Preview("Hungry") {
    MascotDetailView(mood: .hungry)
}

#Preview("Neutral") {
    MascotDetailView(mood: .neutral)
}
