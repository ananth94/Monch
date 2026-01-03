//
//  EmptyTimelineView.swift
//  monch
//
//  Ghost Timeline empty state prompting user to log first meal.
//  Features animated Monch and call-to-action.
//

import SwiftUI

struct EmptyTimelineView: View {
    var onLogMeal: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated Ghost Monch
            Image("monch_hungry")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .opacity(0.6)
                .scaleEffect(isAnimating ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            
            // Copy
            VStack(spacing: 8) {
                Text("Your metabolic story starts here")
                    .font(.Monch.title2)
                    .multilineTextAlignment(.center)
                
                Text("Log your first meal to wake up Monch")
                    .font(.Monch.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // CTA Button
            Button(action: onLogMeal) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Meal")
                }
                .font(.Monch.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.Monch.sage)
                )
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    EmptyTimelineView {
        print("Log meal tapped")
    }
}
