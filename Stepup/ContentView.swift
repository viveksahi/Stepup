import SwiftUI

struct ContentView: View {
    @ObservedObject var healthKitManager: HealthKitManager // Changed to @ObservedObject
     @State private var backgroundColor = Color.white

    init(healthKitManager: HealthKitManager) { // Add this initializer
        self.healthKitManager = healthKitManager
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
    }

    var body: some View {
        TabView {
            MySteps(healthKitManager: healthKitManager, backgroundColor: backgroundColor)
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("My Steps")
                }

            TodayGoal(healthKitManager: healthKitManager, backgroundColor: backgroundColor)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today's Goal")
                }
            
            About(backgroundColor: backgroundColor)
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                    
        }
        .accentColor(.white) // This sets the color of the selected tab item
        .onAppear {
            setRandomBackgroundColor()
        }
    }

    private func setRandomBackgroundColor() {
        backgroundColor = Color(
            red: .random(in: 0...0.5),
            green: .random(in: 0...0.5),
            blue: .random(in: 0...0.5)
        )
    }
}
