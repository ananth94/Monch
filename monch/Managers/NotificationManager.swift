//
//  NotificationManager.swift
//  monch
//
//  Manages local notification permissions and scheduling.
//  Supports Kitchen Closing nudge and Sugar Spike alerts.
//

import Foundation
import UserNotifications
import Combine

/// Centralized manager for local notifications
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Notification Identifiers
    
    enum NotificationID {
        static let kitchenClosing = "monch.kitchenClosing"
        static let sugarSpike = "monch.sugarSpike"
        static let muscleSponge = "monch.muscleSponge"
        static let digestionDebt = "monch.digestionDebt"
    }
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("NotificationManager: Failed to request authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Kitchen Closing Nudge
    
    /// Schedule the daily Kitchen Closing nudge
    /// - Parameter hour: Hour to trigger (24h format), default 20:30 (8:30 PM)
    func scheduleKitchenClosingNudge(hour: Int = 20, minute: Int = 30) {
        // Remove existing
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.kitchenClosing]
        )
        
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Kitchen's Closing! 🌙"
        content.body = "Eating now may affect your sleep. Consider winding down."
        content.sound = .default
        content.categoryIdentifier = "KITCHEN_CLOSING"
        
        // Daily trigger at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: NotificationID.kitchenClosing,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: Failed to schedule Kitchen Closing: \(error)")
            }
        }
    }
    
    /// Cancel the Kitchen Closing nudge
    func cancelKitchenClosingNudge() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.kitchenClosing]
        )
    }
    
    // MARK: - Insight Notifications
    
    /// Send immediate notification for a Sugar Spike insight
    func notifySugarSpike(mealName: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Sugar Spike Detected ⚡"
        content.body = "Your heart rate spiked after \(mealName). Tap to learn more."
        content.sound = .default
        content.categoryIdentifier = "INSIGHT_ALERT"
        content.userInfo = ["insightType": "sugarSpike"]
        
        // Immediate delivery (slight delay for UX)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 2,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.sugarSpike).\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    /// Send notification for Muscle Sponge (positive reinforcement)
    func notifyMuscleSponge() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Anabolic Window Open! 💪"
        content.body = "Great workout! Your muscles are ready for fuel."
        content.sound = .default
        content.categoryIdentifier = "INSIGHT_ALERT"
        content.userInfo = ["insightType": "muscleSponge"]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 2,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.muscleSponge).\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    /// Send notification for Digestion Debt
    func notifyDigestionDebt() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Digestion Debt 😴"
        content.body = "Last night's late meal may have affected your sleep."
        content.sound = .default
        content.categoryIdentifier = "INSIGHT_ALERT"
        content.userInfo = ["insightType": "digestionDebt"]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 2,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.digestionDebt).\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Clear All
    
    /// Remove all pending and delivered notifications
    func clearAll() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
}
