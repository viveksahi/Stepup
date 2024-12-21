import SwiftUI
import HealthKit

@main
struct StepCounterApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView(healthKitManager: healthKitManager)
            } else {
                OnboardingView(
                    onDismiss: { hasSeenOnboarding = true },
                    healthKitManager: healthKitManager
                )
            }
        }
    }
}
