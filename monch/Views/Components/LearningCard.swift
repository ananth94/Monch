//
//  LearningCard.swift
//  monch
//
//  Card shown when user has meals but no insights yet,
//  explaining that Monch is learning their patterns.
//

import SwiftUI

struct LearningCard: View {
    @State private var animatePulse = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Animated watching eye
            ZStack {
                Circle()
                    .fill(Color.Monch.sage.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)
                
                Image(systemName: "eye")
                    .font(.title2)
                    .foregroundStyle(Color.Monch.sage)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Monch is Watching")
                    .font(.Monch.headline)
                
                Text("I'm learning your patterns. Keep logging and I'll start noticing things.")
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

#Preview {
    LearningCard()
        .padding()
}
