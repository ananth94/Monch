//
//  OnboardingView.swift
//  monch
//
//  First-time user onboarding flow with mascot-driven value proposition.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case healthKit = 1
    case firstMeal = 2
}

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentStep: OnboardingStep = .welcome
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Background gradient based on step
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 20)
                
                Spacer()
                
                // Step content
                stepContent
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                
                Spacer()
                
                // Action button
                actionButton
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6).delay(0.2)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Group {
            switch currentStep {
            case .welcome:
                MeshGradientBackground(mood: .neutral)
            case .healthKit:
                MeshGradientBackground(mood: .recovery)
            case .firstMeal:
                MeshGradientBackground(mood: .acute)
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.Monch.coral : Color.white.opacity(0.3))
                    .frame(width: step == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            welcomeContent
        case .healthKit:
            healthKitContent
        case .firstMeal:
            firstMealContent
        }
    }
    
    private var welcomeContent: some View {
        VStack(spacing: Spacing.lg) {
            // Mascot
            Image("monch_neutral")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(animateIn ? 1 : 0.8)
                .animation(.spring(duration: 0.8).delay(0.3), value: animateIn)
            
            Text("Welcome to Monch!")
                .font(.Monch.largeTitle)
                .foregroundStyle(.primary)
            
            Text("I'm your metabolic companion. I'll help you understand how food affects your energy.")
                .font(.Monch.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
    }
    
    private var healthKitContent: some View {
        VStack(spacing: Spacing.lg) {
            // Mascot with stethoscope
            ZStack {
                Image("monch_strong")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                // Heart rate icon overlay
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.Monch.coral)
                    .offset(x: 60, y: -60)
                    .scaleEffect(animateIn ? 1 : 0)
                    .animation(.spring(duration: 0.5).delay(0.5), value: animateIn)
            }
            
            Text("Let's Connect to Health")
                .font(.Monch.largeTitle)
                .foregroundStyle(.primary)
            
            Text("I need access to your heart rate to detect sugar spikes and help you feel your best.")
                .font(.Monch.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            // What we access
            VStack(alignment: .leading, spacing: Spacing.sm) {
                accessRow(icon: "heart.fill", text: "Heart Rate & HRV")
                accessRow(icon: "bed.double.fill", text: "Sleep Data")
                accessRow(icon: "figure.run", text: "Workouts")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, Spacing.xl)
        }
    }
    
    private func accessRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.Monch.sage)
                .frame(width: 24)
            
            Text(text)
                .font(.Monch.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.Monch.sage)
        }
    }
    
    private var firstMealContent: some View {
        VStack(spacing: Spacing.lg) {
            // Hungry mascot
            Image("monch_hungry")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(animateIn ? 1 : 0.8)
                .animation(.spring(duration: 0.8).delay(0.3), value: animateIn)
            
            Text("Your First Meal")
                .font(.Monch.largeTitle)
                .foregroundStyle(.primary)
            
            Text("What did you have for breakfast today? I'll start learning your patterns.")
                .font(.Monch.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            // Popular first meals
            VStack(spacing: Spacing.sm) {
                Text("Popular first meals:")
                    .font(.Monch.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: Spacing.sm) {
                    quickMealChip("☕️ Coffee")
                    quickMealChip("🥣 Oatmeal")
                    quickMealChip("🍳 Eggs")
                }
            }
            .padding(.top, Spacing.md)
        }
    }
    
    private func quickMealChip(_ text: String) -> some View {
        Text(text)
            .font(.Monch.caption)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            advanceStep()
        } label: {
            HStack {
                Text(buttonTitle)
                    .font(.Monch.headline)
                
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.Monch.coral)
            )
        }
    }
    
    private var buttonTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .healthKit:
            return "Connect Health"
        case .firstMeal:
            return "Log Breakfast"
        }
    }
    
    // MARK: - Actions
    
    private func advanceStep() {
        switch currentStep {
        case .welcome:
            withAnimation(.spring(duration: 0.4)) {
                animateIn = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentStep = .healthKit
                withAnimation(.spring(duration: 0.6)) {
                    animateIn = true
                }
            }
            
        case .healthKit:
            // Request HealthKit permissions
            Task {
                await HealthKitManager.shared.requestAuthorization()
                await MainActor.run {
                    withAnimation(.spring(duration: 0.4)) {
                        animateIn = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        currentStep = .firstMeal
                        withAnimation(.spring(duration: 0.6)) {
                            animateIn = true
                        }
                    }
                }
            }
            
        case .firstMeal:
            // Complete onboarding
            withAnimation(.spring(duration: 0.4)) {
                isOnboardingComplete = true
            }
            // Store completion in UserDefaults
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
