import HealthKit
import Foundation
import Combine

class HealthKitManager: ObservableObject {
    // Core properties
    private var healthStore = HKHealthStore()
    @Published var stepCount: Int = 0
    @Published var motivationalMessage: String?
    private var query: HKStatisticsCollectionQuery?
    private let openAIService = OpenAIService()
    @Published var isAuthorized: Bool = false
    
    init() {
        // Check authorization status immediately on init
        checkAuthorization()
    }
    
    private func checkAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Check current authorization status
        let authStatus = healthStore.authorizationStatus(for: stepType)
        
        // Update our published isAuthorized property
        DispatchQueue.main.async {
            self.isAuthorized = authStatus == .sharingAuthorized
            
            // If we're already authorized, start updates immediately
            if self.isAuthorized {
                print("Already authorized, starting updates")
                self.startStepCountUpdates()
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            completion(false)
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { [weak self] success, error in
            DispatchQueue.main.async {
                print("Authorization result: \(success)")
                self?.isAuthorized = success
                if success {
                    print("Starting updates after new authorization")
                    self?.startStepCountUpdates()
                }
                if let error = error {
                    print("Authorization error: \(error.localizedDescription)")
                }
                completion(success)
            }
        }
    }
    
    func refreshStepCount() {
        print("Refreshing step count...")
        if isAuthorized {
            startStepCountUpdates()
        } else {
            print("Not authorized to refresh steps")
            // Try to reauthorize
            requestAuthorization()
        }
    }
    
    private func startStepCountUpdates() {
        // Stop existing query if any
        if let existingQuery = query {
            healthStore.stop(existingQuery)
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        print("Setting up new step count query")
        
        query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startOfDay,
            intervalComponents: DateComponents(day: 1)
        )
        
        // Handle initial results
        query?.initialResultsHandler = { [weak self] query, statisticsCollection, error in
            print("Got initial results")
            if let error = error {
                print("Error getting statistics: \(error.localizedDescription)")
                return
            }
            
            self?.processStatistics(statisticsCollection)
        }
        
        // Handle ongoing updates
        query?.statisticsUpdateHandler = { [weak self] query, statistics, statisticsCollection, error in
            print("Got statistics update")
            if let error = error {
                print("Error updating statistics: \(error.localizedDescription)")
                return
            }
            
            self?.processStatistics(statisticsCollection)
        }
        
        if let query = query {
            print("Executing query")
            healthStore.execute(query)
        }
    }
    
    private func processStatistics(_ statisticsCollection: HKStatisticsCollection?) {
        guard let statisticsCollection = statisticsCollection else {
            print("No statistics collection available")
            return
        }
        
        let endDate = Date()
        let startDate = Calendar.current.startOfDay(for: endDate)
        
        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { [weak self] statistics, stop in
            if let quantity = statistics.sumQuantity() {
                let steps = Int(quantity.doubleValue(for: .count()))
                print("Processing steps: \(steps)")
                
                DispatchQueue.main.async {
                    self?.stepCount = steps
                    self?.updateMotivationalMessageAsync(steps: steps)
                }
            }
        }
    }
    
    // This is the missing function that generates motivational messages
    private func updateMotivationalMessageAsync(steps: Int) {
        Task { [weak self] in
            do {
                guard let self = self else { return }  // Safely unwrap weak self
                let message = try await self.openAIService.generateMotivationalSentence(steps: steps)
                print("Got motivational message")
                
                // Capture self once at the Task level
                await MainActor.run {
                    self.motivationalMessage = message
                }
            } catch {
                print("Error generating motivational message: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        if let query = query {
            healthStore.stop(query)
        }
    }
}
