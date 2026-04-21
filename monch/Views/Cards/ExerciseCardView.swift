//
//  ExerciseCardView.swift
//  monch
//
//  Detail card for viewing workout data.
//  Adapts layout based on exercise type (cardio vs strength).
//

import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    let workout: WorkoutLog
    
    var body: some View {
        CardDetailShell(
            title: workout.activityName,
            icon: workout.category.iconToken,
            timestamp: workout.startTime,
            contextTag: workout.contextTag,
            mood: .recovery,
            onDelete: nil
        ) {
            VStack(spacing: Spacing.lg) {
                // Metrics Grid (adapts to exercise type)
                metricsSection
                
                // HR Zone Chart (for cardio) or HR Timeline (for strength)
                if let breakdown = workout.hrZoneBreakdown {
                    hrSection(breakdown: breakdown)
                }
                
                // Anabolic Window
                if workout.isInAnabolicWindow {
                    anabolicWindowSection
                }
            }
        }
    }
    
    // MARK: - Metrics Section
    
    @ViewBuilder
    private var metricsSection: some View {
        switch workout.category {
        case .cardio:
            cardioMetrics
        case .strength:
            strengthMetrics
        case .hiit:
            hiitMetrics
        default:
            generalMetrics
        }
    }
    
    private var cardioMetrics: some View {
        MonchCardSection("details", icon: "figure.run") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                MetricCell(label: "Duration", value: workout.formattedDuration)
                
                if let distance = workout.formattedDistance {
                    MetricCell(label: "Distance", value: distance)
                }
                
                if let pace = workout.formattedPace {
                    MetricCell(label: "Pace", value: pace)
                }
                
                if let cal = workout.activeCalories {
                    MetricCell(label: "Calories", value: "\(Int(cal)) kcal")
                }
                
                if let avgHR = workout.avgHeartRate {
                    MetricCell(label: "Avg HR", value: "\(Int(avgHR)) bpm")
                }
                
                if let maxHR = workout.maxHeartRate {
                    MetricCell(label: "Max HR", value: "\(Int(maxHR)) bpm")
                }
            }
        }
    }
    
    private var strengthMetrics: some View {
        MonchCardSection("details", icon: "dumbbell.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                MetricCell(label: "Duration", value: workout.formattedDuration)
                
                if let cal = workout.activeCalories {
                    MetricCell(label: "Calories", value: "\(Int(cal)) kcal")
                }
                
                if let avgHR = workout.avgHeartRate {
                    MetricCell(label: "Avg HR", value: "\(Int(avgHR)) bpm")
                }
                
                if let maxHR = workout.maxHeartRate {
                    MetricCell(label: "Max HR", value: "\(Int(maxHR)) bpm")
                }
            }
        }
    }
    
    private var hiitMetrics: some View {
        MonchCardSection("details", icon: "bolt.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                MetricCell(label: "Duration", value: workout.formattedDuration)
                
                if let cal = workout.activeCalories {
                    MetricCell(label: "Calories", value: "\(Int(cal)) kcal")
                }
                
                if let avgHR = workout.avgHeartRate {
                    MetricCell(label: "Avg HR", value: "\(Int(avgHR)) bpm")
                }
                
                if let maxHR = workout.maxHeartRate {
                    MetricCell(label: "Max HR", value: "\(Int(maxHR)) bpm")
                }
            }
        }
    }
    
    private var generalMetrics: some View {
        MonchCardSection("details", icon: "heart.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                MetricCell(label: "Duration", value: workout.formattedDuration)
                
                if let cal = workout.activeCalories {
                    MetricCell(label: "Calories", value: "\(Int(cal)) kcal")
                }
            }
        }
    }
    
    // MARK: - HR Zone Section
    
    private func hrSection(breakdown: HRZoneBreakdown) -> some View {
        MonchCardSection("hr zones", icon: "heart.fill") {
            VStack(spacing: Spacing.sm) {
                HRZoneRow(zone: 1, label: "Zone 1 (Recovery)", percentage: breakdown.percentage(for: 1), minutes: breakdown.zone1Minutes)
                HRZoneRow(zone: 2, label: "Zone 2 (Endurance)", percentage: breakdown.percentage(for: 2), minutes: breakdown.zone2Minutes)
                HRZoneRow(zone: 3, label: "Zone 3 (Tempo)", percentage: breakdown.percentage(for: 3), minutes: breakdown.zone3Minutes)
                HRZoneRow(zone: 4, label: "Zone 4 (Threshold)", percentage: breakdown.percentage(for: 4), minutes: breakdown.zone4Minutes)
                HRZoneRow(zone: 5, label: "Zone 5 (Max)", percentage: breakdown.percentage(for: 5), minutes: breakdown.zone5Minutes)
            }
        }
    }
    
    // MARK: - Anabolic Window Section
    
    private var anabolicWindowSection: some View {
        MonchCardSection("anabolic window", icon: "bolt.fill") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(Color.Monch.sage)
                    Text(workout.formattedAnabolicWindowRemaining ?? "Active")
                        .font(.Monch.headline)
                        .foregroundStyle(Color.Monch.sage)
                }
                
                Text("Protein now will fuel muscle recovery. This window closes at \(workout.anabolicWindowEnd, format: .dateTime.hour().minute()).")
                    .font(.Monch.body)
                    .foregroundStyle(.secondary)
                
                MonchPrimaryButton("Log Protein", icon: "fork.knife") {
                    // TODO: Open a meal event flow with protein-focused guidance
                }
                .padding(.top, Spacing.xs)
            }
        }
    }
}

// MARK: - Supporting Views

private struct MetricCell: View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HRZoneRow: View {
    let zone: Int
    let label: String
    let percentage: Double
    let minutes: Int
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("Z\(zone)")
                .font(.Monch.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(colorForZone(zone)))
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorForZone(zone))
                    .frame(width: geometry.size.width * min(percentage, 1.0))
            }
            .frame(height: 12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorForZone(zone).opacity(0.2))
            )
            
            Text("\(Int(percentage * 100))%")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
    }
    
    private func colorForZone(_ zone: Int) -> Color {
        switch zone {
        case 1: return Color.Monch.sage.opacity(0.6)
        case 2: return Color.Monch.sage
        case 3: return Color.Monch.peach
        case 4: return Color.Monch.coral.opacity(0.8)
        case 5: return Color.Monch.coral
        default: return Color.Monch.sage
        }
    }
}

// MARK: - Preview

#Preview("Cardio - Running") {
    let workout = WorkoutLog(
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-600),
        duration: 45 * 60, // 45 mins active in a 50 min window
        activityTypeRaw: 37, // running
        activityName: "Morning Run",
        distanceMeters: 5200,
        activeCalories: 320,
        avgHeartRate: 142,
        maxHeartRate: 168,
        dominantHRZone: 2
    )
    
    let breakdown = HRZoneBreakdown(
        zone1Minutes: 3,
        zone2Minutes: 22,
        zone3Minutes: 8,
        zone4Minutes: 2,
        zone5Minutes: 0
    )
    workout.setHRZoneBreakdown(breakdown)
    
    return ExerciseCardView(workout: workout)
}

#Preview("Strength - Weight Training") {
    let workout = WorkoutLog(
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-600),
        duration: 40 * 60, // 40 mins active in a 50 min window
        activityTypeRaw: 50, // traditionalStrengthTraining
        activityName: "Weight Training",
        activeCalories: 280,
        avgHeartRate: 118,
        maxHeartRate: 142
    )
    
    return ExerciseCardView(workout: workout)
}
