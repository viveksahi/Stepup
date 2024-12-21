import SwiftUI

// First, let's define the PermissionCard view at the top of the file
private struct PermissionCard: View {
    let icon: String           // SF Symbol name for the icon
    let title: String         // Title of the permission
    let description: String   // Description text
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon on the left
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 44)
            
            // Title and description on the right
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
}

// Then, the main OnboardingView remains the same
struct OnboardingView: View {
    var onDismiss: () -> Void
    @ObservedObject var healthKitManager: HealthKitManager
    @State private var showingSecondScreen = false
    @State private var hasCompletedHealthKitPermission = false
    @State private var hasCompletedNotificationPermission = false
    
    var body: some View {
        ZStack {
            Color(red: 0.2, green: 0.2, blue: 0.3)
                .edgesIgnoringSafeArea(.all)
            
            if !showingSecondScreen {
                // First screen (Welcome)
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "figure.walk")
                        .font(.system(size: 120))
                        .foregroundColor(.white)
                    
                    Text("A step counter that loves to roast you")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Button(action: { showingSecondScreen = true }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            } else {
                // Second screen (Permissions)
                VStack(spacing: 24) {
                    Text("Before we begin we need")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    PermissionCard(
                        icon: "figure.walk.circle.fill",
                        title: "Step Counter Access",
                        description: "We need to know how lazy you are."
                    )
                    
                    PermissionCard(
                        icon: "bell.fill",
                        title: "Notifications access",
                        description: "Get notified of your step count, only once a day."
                    )
                    
                    Spacer()
                    
                    Button(action: startPermissionFlow) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func startPermissionFlow() {
        print("Starting permission flow")
        // First request HealthKit permission
        healthKitManager.requestAuthorization { success in
            if success {
                hasCompletedHealthKitPermission = true
                print("HealthKit permission granted, waiting before notification request")
                
                // Add delay before notification request
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let notificationManager = NotificationManager()
                    notificationManager.requestNotificationPermissions(stepCount: 0) { granted in
                        hasCompletedNotificationPermission = true
                        print("Notification permission completed with result: \(granted)")
                        
                        // Proceed regardless of notification permission result
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("Permission flow complete, dismissing onboarding")
                            onDismiss()
                        }
                    }
                }
            } else {
                print("HealthKit permission denied")
                // You might want to show an alert here explaining that the app needs HealthKit access
            }
        }
    }
}
