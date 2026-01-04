//
//  HypnogramView.swift
//  monch
//
//  Visual representation of sleep stages over the night.
//  Shows Awake, REM, Light, and Deep sleep as a step chart.
//

import SwiftUI

struct HypnogramView: View {
    let sleepLog: SleepLog
    
    // Sleep stage levels (Y-axis from top to bottom)
    private enum SleepStage: Int, CaseIterable {
        case awake = 0
        case rem = 1
        case light = 2
        case deep = 3
        
        var label: String {
            switch self {
            case .awake: return "Awake"
            case .rem: return "REM"
            case .light: return "Light"
            case .deep: return "Deep"
            }
        }
        
        var color: Color {
            switch self {
            case .awake: return Color.Monch.coral.opacity(0.7)
            case .rem: return Color.Monch.sage.opacity(0.9)
            case .light: return Color.Monch.periwinkle.opacity(0.6)
            case .deep: return Color.Monch.periwinkle
            }
        }
    }
    
    // Mock stage data - in real implementation this would come from HealthKit sleep stages
    private var stageData: [SleepStageSegment] {
        generateMockStages()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Title
            Text("Sleep Architecture")
                .font(.Monch.caption)
                .foregroundStyle(.secondary)
            
            // Chart
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // Background grid
                    gridBackground(in: geo.size)
                    
                    // Stage path
                    stagePath(in: geo.size)
                }
            }
            .frame(height: 100)
            
            // Time axis
            timeAxis
            
            // Legend
            legend
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Grid Background
    
    private func gridBackground(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(SleepStage.allCases, id: \.rawValue) { stage in
                Rectangle()
                    .fill(stage.color.opacity(0.1))
                    .frame(height: size.height / 4)
            }
        }
    }
    
    // MARK: - Stage Path
    
    private func stagePath(in size: CGSize) -> some View {
        Path { path in
            guard !stageData.isEmpty else { return }
            
            let totalDuration = sleepLog.endTime.timeIntervalSince(sleepLog.startTime)
            let stageHeight = size.height / 4
            
            // Start at first stage
            let firstSegment = stageData[0]
            let x = xPosition(for: firstSegment.startTime, totalDuration: totalDuration, width: size.width)
            let y = CGFloat(firstSegment.stage.rawValue) * stageHeight + stageHeight / 2
            path.move(to: CGPoint(x: x, y: y))
            
            // Draw step chart
            for segment in stageData {
                let startX = xPosition(for: segment.startTime, totalDuration: totalDuration, width: size.width)
                let endX = xPosition(for: segment.endTime, totalDuration: totalDuration, width: size.width)
                let segmentY = CGFloat(segment.stage.rawValue) * stageHeight + stageHeight / 2
                
                // Horizontal to stage level
                path.addLine(to: CGPoint(x: startX, y: segmentY))
                // Horizontal across stage
                path.addLine(to: CGPoint(x: endX, y: segmentY))
            }
        }
        .stroke(
            LinearGradient(
                colors: [Color.Monch.sage, Color.Monch.periwinkle],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func xPosition(for time: Date, totalDuration: TimeInterval, width: CGFloat) -> CGFloat {
        let elapsed = time.timeIntervalSince(sleepLog.startTime)
        return (elapsed / totalDuration) * width
    }
    
    // MARK: - Time Axis
    
    private var timeAxis: some View {
        HStack {
            Text(sleepLog.startTime.formatted(date: .omitted, time: .shortened))
                .font(.Monch.caption2)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(sleepLog.endTime.formatted(date: .omitted, time: .shortened))
                .font(.Monch.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Legend
    
    private var legend: some View {
        HStack(spacing: Spacing.md) {
            ForEach(SleepStage.allCases, id: \.rawValue) { stage in
                HStack(spacing: 4) {
                    Circle()
                        .fill(stage.color)
                        .frame(width: 8, height: 8)
                    Text(stage.label)
                        .font(.Monch.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockStages() -> [SleepStageSegment] {
        // Generate realistic-looking sleep stages based on actual sleep log duration
        var segments: [SleepStageSegment] = []
        var currentTime = sleepLog.startTime
        let endTime = sleepLog.endTime
        
        // Typical sleep cycle: Light -> Deep -> Light -> REM, repeating every ~90 min
        var cyclePhase = 0
        
        while currentTime < endTime {
            let stage: SleepStage
            let duration: TimeInterval
            
            switch cyclePhase % 8 {
            case 0: // Falling asleep
                stage = .light
                duration = 600 + Double.random(in: -120...120) // ~10 min
            case 1: // Early deep
                stage = .deep
                duration = 1200 + Double.random(in: -300...300) // ~20 min
            case 2: // Peak deep
                stage = .deep
                duration = 900 + Double.random(in: -180...180) // ~15 min
            case 3: // Rising to light
                stage = .light
                duration = 600 + Double.random(in: -120...120) // ~10 min
            case 4: // First REM
                stage = .rem
                duration = 600 + Double.random(in: -60...180) // ~10-13 min
            case 5: // Brief wake
                stage = .awake
                duration = 60 + Double.random(in: 0...60) // ~1-2 min
            case 6: // Back to light
                stage = .light
                duration = 900 + Double.random(in: -180...180) // ~15 min
            case 7: // Longer REM (later in night)
                stage = .rem
                duration = 1200 + Double.random(in: -180...300) // ~20-25 min
            default:
                stage = .light
                duration = 600
            }
            
            let segmentEnd = min(currentTime.addingTimeInterval(duration), endTime)
            segments.append(SleepStageSegment(stage: stage, startTime: currentTime, endTime: segmentEnd))
            
            currentTime = segmentEnd
            cyclePhase += 1
        }
        
        return segments
    }
    
    // MARK: - Sleep Stage Segment (nested)
    
    private struct SleepStageSegment {
        let stage: SleepStage
        let startTime: Date
        let endTime: Date
    }
}

// MARK: - Preview

#Preview {
    HypnogramView(sleepLog: SleepLog(
        startTime: Date().addingTimeInterval(-8 * 3600),
        endTime: Date(),
        deepSleepMinutes: 90
    ))
    .padding()
}
