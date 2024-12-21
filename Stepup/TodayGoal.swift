import SwiftUI

struct TodayGoal: View {
    // MARK: - Properties
    
    /// Manages HealthKit data and authorization
    @ObservedObject var healthKitManager: HealthKitManager
    
    /// Stores the daily step goal
    @State private var todayGoal: Int
    
    /// Tracks the previous step count for haptic feedback
    @State private var previousStepCount: Int = 0
    
    /// Background color passed from parent view
    var backgroundColor: Color
    
    // MARK: - Initialization
    
    init(healthKitManager: HealthKitManager, backgroundColor: Color) {
        self.healthKitManager = healthKitManager
        self.backgroundColor = backgroundColor
        
        // Load or generate today's goal
        if let savedGoal = UserDefaults.standard.object(forKey: "TodayGoal") as? Int {
            _todayGoal = State(initialValue: savedGoal)
        } else {
            let newGoal = Self.generateDailyGoal()
            UserDefaults.standard.set(newGoal, forKey: "TodayGoal")
            _todayGoal = State(initialValue: newGoal)
        }
    }
    
    // MARK: - View Body
    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Animated goal display
                HStack(spacing: 2) {
                    ForEach(Array(String(todayGoal).enumerated()), id: \.offset) { index, digit in
                        AnimatedDigitView(
                            digit: digit,
                            isRevealed: shouldRevealDigit(at: index)
                        )
                    }
                }
                
                Text(goalMessage())
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
        .onAppear {
            // Refresh data when view appears
            print("TodayGoal appeared, refreshing step count")
            healthKitManager.refreshStepCount()
            previousStepCount = healthKitManager.stepCount
        }
        .onChange(of: healthKitManager.stepCount) { oldStepCount, newStepCount in
            // Handle step count changes and haptic feedback
            print("Step count changed to: \(newStepCount)")
            let oldThousands = oldStepCount / 1000
            let newThousands = newStepCount / 1000
            
            if newThousands > oldThousands {
                print("Crossed 1000-step threshold, triggering haptic")
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
            
            previousStepCount = newStepCount
        }
    }
    
    // MARK: - Helper Functions
    
    /// Generates a random daily step goal
    private static func generateDailyGoal() -> Int {
        let minGoal = 5000
        let maxGoal = 10000
        return Int.random(in: minGoal..<maxGoal)
    }
    
    /// Determines if a digit should be revealed based on current step count
    private func shouldRevealDigit(at index: Int) -> Bool {
        print("Checking digit \(index), steps: \(healthKitManager.stepCount), goal: \(todayGoal)")
        
        // Reveal all digits if goal is met
        if healthKitManager.stepCount >= todayGoal {
            return true
        }
        
        // Reveal digits based on thousands of steps completed
        let stepCount = healthKitManager.stepCount
        let unmaskedDigits = stepCount / 1000
        return index < unmaskedDigits
    }
    
    /// Returns the appropriate message based on goal completion
    private func goalMessage() -> String {
        if healthKitManager.stepCount >= todayGoal {
            return "Today's step goal"
        } else {
            return "Every 1000 steps will unmask a digit of today's step goal"
        }
    }
}

private struct AnimatedDigitView: View {
    let digit: Character
    let isRevealed: Bool
    @State private var hasFlipped = false
    
    var body: some View {
        ZStack {
            // Hidden digit (asterisk)
            Text("*")
                .opacity(isRevealed ? 0 : 1)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            // Actual digit
            Text(String(digit))
                .opacity(isRevealed ? 1 : 0)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(isRevealed ? 1 : 0.5)
        }
        .onChange(of: isRevealed) {
            if isRevealed && !hasFlipped {
                withAnimation(.easeInOut(duration: 0.5)) {
                    hasFlipped = true
                }
            }
        }
        .rotation3DEffect(
            .degrees(isRevealed ? 0 : 180),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isRevealed)
    }
}
