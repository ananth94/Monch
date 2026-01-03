//
//  HealthKitManager.swift
//  monch
//
//  Created by Opencode Agent on 03/01/2026.
//

import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var error: Error?
    
    private init() {}
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device.")
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            self.isAuthorized = true
            print("HealthKit authorization request complete.")
        } catch {
            self.error = error
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
}
