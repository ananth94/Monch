//
//  SleepCardView.swift
//  monch
//
//  Detail card for viewing last night's sleep data.
//  Shows hypnogram timeline, stage breakdown, and linked insights.
//

import SwiftUI
import SwiftData

struct SleepCardView: View {
    let sleepLog: SleepLog
    
    @State private var selectedSegment: SleepSegment?
    
    var body: some View {
        CardDetailShell(
            title: "Last Night's Sleep",
            icon: "😴",
            timestamp: sleepLog.startTime,
            contextTag: qualityTag,
            mood: .sleep,
            onDelete: nil
        ) {
            VStack(spacing: Spacing.lg) {
                // Summary Stats
                summarySection
                
                // Hypnogram Timeline
                hypnogramSection
                
                // Stage Breakdown
                stageBreakdownSection
                
                // Context / Linked Insights
                if let insight = linkedInsight {
                    contextSection(insight: insight)
                }
                
                // Scoring formula explanation
                formulaExplanationSection
            }
        }
    }
    
    // MARK: - Quality Tag
    
    private var qualityTag: String? {
        let score = sleepLog.computedQualityScore
        let efficiency = Int(sleepLog.sleepEfficiency * 100)
        let status: String
        if score >= 0.8 { status = "✨ Great" }
        else if score >= 0.6 { status = "👍 Good" }
        else if score >= 0.4 { status = "😐 Fair" }
        else { status = "😴 Poor" }
        
        return "\(status) • \(efficiency)% Eff."
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        HStack(spacing: Spacing.lg) {
            SleepStatPill(
                label: "Duration",
                value: sleepLog.formattedDuration
            )
            
            SleepStatPill(
                label: "Quality",
                value: "\(Int(sleepLog.computedQualityScore * 100))%"
            )
            
            SleepStatPill(
                label: "Efficiency",
                value: "\(Int(sleepLog.sleepEfficiency * 100))%"
            )
        }
    }
    
    // MARK: - Hypnogram Section
    
    private var hypnogramSection: some View {
        MonchCardSection("timeline", icon: "waveform.path") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Time labels
                HStack {
                    Text(sleepLog.startTime, format: .dateTime.hour().minute())
                        .font(.Monch.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(sleepLog.endTime, format: .dateTime.hour().minute())
                        .font(.Monch.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Hypnogram chart
                SleepHypnogramChart(
                    segments: sleepLog.stageSegments,
                    totalDuration: sleepLog.totalDuration,
                    selectedSegment: $selectedSegment
                )
                .frame(height: 80)
                
                // Selected segment detail
                if let segment = selectedSegment {
                    HStack {
                        Circle()
                            .fill(colorForStage(segment.stage))
                            .frame(width: 8, height: 8)
                        Text("\(segment.startTime, format: .dateTime.hour().minute()) - \(segment.endTime, format: .dateTime.hour().minute())")
                            .font(.Monch.caption)
                        Text(segment.stage.displayName)
                            .font(.Monch.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
    }
    
    // MARK: - Stage Breakdown Section
    
    private var stageBreakdownSection: some View {
        MonchCardSection("breakdown", icon: "chart.bar.fill") {
            VStack(spacing: Spacing.sm) {
                SleepStageRow(
                    stage: .deep,
                    minutes: sleepLog.deepSleepMinutes,
                    percentage: sleepLog.deepSleepPercentage,
                    color: Color.Monch.periwinkle
                )
                
                SleepStageRow(
                    stage: .rem,
                    minutes: sleepLog.remSleepMinutes,
                    percentage: sleepLog.remSleepPercentage,
                    color: Color.Monch.lavender
                )
                
                SleepStageRow(
                    stage: .light,
                    minutes: sleepLog.lightSleepMinutes,
                    percentage: Double(sleepLog.lightSleepMinutes) / Double(max(sleepLog.actualSleepMinutes, 1)),
                    color: Color.Monch.sage.opacity(0.6)
                )
                
                if sleepLog.awakeMinutes > 0 {
                    SleepStageRow(
                        stage: .awake,
                        minutes: sleepLog.awakeMinutes,
                        percentage: Double(sleepLog.awakeMinutes) / Double(max(sleepLog.actualSleepMinutes + sleepLog.awakeMinutes, 1)),
                        color: Color.Monch.coral.opacity(0.6)
                    )
                }
            }
        }
    }
    
    // MARK: - Context Section
    
    private func contextSection(insight: String) -> some View {
        MonchCardSection("context", icon: "lightbulb.fill") {
            Text(insight)
                .font(.Monch.body)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Scoring Explanation
    
    private var formulaExplanationSection: some View {
        MonchCardSection("how we score", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Sleep Quality is a weighted average of three key pillars:")
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
                
                ScoreRuleRow(label: "Sleep Efficiency (>85%)", weight: 35)
                ScoreRuleRow(label: "Deep Sleep (15–25%)", weight: 35)
                ScoreRuleRow(label: "Total Duration (7–9 hrs)", weight: 30)
            }
        }
    }
    
    private struct ScoreRuleRow: View {
        let label: String
        let weight: Int
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.Monch.caption2)
                Spacer()
                Text("\(weight)% weight")
                    .font(.Monch.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // TODO: Query InsightEvent for digestion debt matching this sleep date
    private var linkedInsight: String? {
        // Placeholder - would query InsightEvent model
        if sleepLog.deepSleepPercentage < 0.15 {
            return "Your deep sleep was lower than usual. Late meals or caffeine may have affected sleep quality."
        }
        return nil
    }
    
    private func colorForStage(_ stage: SleepStage) -> Color {
        switch stage {
        case .deep: return Color.Monch.periwinkle
        case .rem: return Color.Monch.lavender
        case .light: return Color.Monch.sage.opacity(0.6)
        case .awake: return Color.Monch.coral.opacity(0.6)
        case .inBed: return Color.Monch.cream
        }
    }
}

// MARK: - Supporting Views

private struct SleepStatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.Monch.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.Monch.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SleepStageRow: View {
    let stage: SleepStage
    let minutes: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(stage.displayName)
                .font(.Monch.body)
                .frame(width: 50, alignment: .leading)
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * min(percentage, 1.0))
            }
            .frame(height: 12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
            )
            
            Text("\(Int(percentage * 100))%")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 35, alignment: .trailing)
            
            Text(minutes.formattedAsMinutes)
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .trailing)
        }
    }
}

// MARK: - Hypnogram Chart

struct SleepHypnogramChart: View {
    let segments: [SleepSegment]
    let totalDuration: TimeInterval
    @Binding var selectedSegment: SleepSegment?
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard !segments.isEmpty, totalDuration > 0 else { return }
                
                let startTime = segments.first?.startTime ?? Date()
                
                for segment in segments {
                    let xStart = xPosition(for: segment.startTime, startTime: startTime, width: size.width)
                    let xEnd = xPosition(for: segment.endTime, startTime: startTime, width: size.width)
                    let yCenter = yPosition(for: segment.stage, height: size.height)
                    
                    let rect = CGRect(
                        x: xStart,
                        y: yCenter - 6,
                        width: max(xEnd - xStart, 2),
                        height: 12
                    )
                    
                    let path = RoundedRectangle(cornerRadius: 4).path(in: rect)
                    context.fill(path, with: .color(colorForStage(segment.stage)))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        selectSegment(at: value.location.x, width: geometry.size.width)
                    }
            )
            
            // Y-axis labels
            VStack {
                Text("Awake").font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                Text("Light").font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                Text("REM").font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                Text("Deep").font(.system(size: 8)).foregroundStyle(.tertiary)
            }
            .frame(width: 30)
            .offset(x: -35)
        }
        .padding(.leading, 40)
    }
    
    private func xPosition(for date: Date, startTime: Date, width: CGFloat) -> CGFloat {
        let elapsed = date.timeIntervalSince(startTime)
        return CGFloat(elapsed / totalDuration) * width
    }
    
    private func yPosition(for stage: SleepStage, height: CGFloat) -> CGFloat {
        let normalizedDepth = CGFloat(3 - stage.depthValue) / 3.0
        return normalizedDepth * height
    }
    
    private func colorForStage(_ stage: SleepStage) -> Color {
        switch stage {
        case .deep: return Color.Monch.periwinkle
        case .rem: return Color.Monch.lavender
        case .light: return Color.Monch.sage.opacity(0.6)
        case .awake: return Color.Monch.coral.opacity(0.6)
        case .inBed: return Color.Monch.cream
        }
    }
    
    private func selectSegment(at x: CGFloat, width: CGFloat) {
        guard !segments.isEmpty, totalDuration > 0 else { return }
        let startTime = segments.first?.startTime ?? Date()
        let tappedTime = startTime.addingTimeInterval(Double(x / width) * totalDuration)
        
        selectedSegment = segments.first { segment in
            tappedTime >= segment.startTime && tappedTime < segment.endTime
        }
    }
}

// MARK: - Preview

#Preview {
    let sleepLog = SleepLog(
        startTime: Calendar.current.date(bySettingHour: 23, minute: 15, second: 0, of: Date().addingTimeInterval(-86400))!,
        endTime: Calendar.current.date(bySettingHour: 6, minute: 47, second: 0, of: Date())!,
        deepSleepMinutes: 81,
        remSleepMinutes: 108,
        lightSleepMinutes: 190,
        awakeMinutes: 33
    )
    
    // Add sample hypnogram segments
    let segments = [
        SleepSegment(startTime: sleepLog.startTime, endTime: sleepLog.startTime.addingTimeInterval(1800), stage: .light),
        SleepSegment(startTime: sleepLog.startTime.addingTimeInterval(1800), endTime: sleepLog.startTime.addingTimeInterval(5400), stage: .deep),
        SleepSegment(startTime: sleepLog.startTime.addingTimeInterval(5400), endTime: sleepLog.startTime.addingTimeInterval(9000), stage: .rem),
        SleepSegment(startTime: sleepLog.startTime.addingTimeInterval(9000), endTime: sleepLog.startTime.addingTimeInterval(14400), stage: .light),
        SleepSegment(startTime: sleepLog.startTime.addingTimeInterval(14400), endTime: sleepLog.startTime.addingTimeInterval(18000), stage: .deep),
        SleepSegment(startTime: sleepLog.startTime.addingTimeInterval(18000), endTime: sleepLog.endTime, stage: .light)
    ]
    sleepLog.setStageSegments(segments)
    
    return SleepCardView(sleepLog: sleepLog)
}
