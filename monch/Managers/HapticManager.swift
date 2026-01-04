//
//  HapticManager.swift
//  monch
//
//  Centralized haptic feedback management for premium feel.
//

import SwiftUI
import UIKit

enum HapticType {
    case success
    case warning
    case error
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
}

@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func play(_ type: HapticType) {
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
        case .soft:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            
        case .rigid:
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
            
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    func hapticOnTap(_ type: HapticType = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                Task { @MainActor in
                    HapticManager.shared.play(type)
                }
            }
        )
    }
}
