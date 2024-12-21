import SwiftUI

struct MySteps: View {
    // MARK: - Properties
    
    /// Manages HealthKit data and authorization
    @ObservedObject var healthKitManager: HealthKitManager
    
    /// Background color passed from parent view
    var backgroundColor: Color
    
    /// Controls the loading state visibility
    @State private var isLoading: Bool = true
    
    /// Controls the screenshot confirmation toast visibility
    @State private var showToast = false
    
    // MARK: - View Body
    var body: some View {
        ZStack {
            // Background layer
            backgroundColor
                .edgesIgnoringSafeArea(.all)

            // Main content layer
            VStack {
                if isLoading {
                    // Loading indicator with custom styling
                    ProgressView(" {-_-} Counting your steps ")
                        .foregroundColor(.white)
                        .opacity(0.5)
                        .scaleEffect(1.5)
                } else {
                    // Step count and motivational message display
                    VStack(spacing: 20) {
                        Text("\(healthKitManager.stepCount)")
                            .font(.system(size: 48))
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(healthKitManager.motivationalMessage ?? "")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Screenshot button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: captureScreenshot) {
                        Image(systemName: "photo.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                            .foregroundColor(.white)
                            .opacity(0.5)
                    }
                }
                .padding([.top, .trailing], 16)
                Spacer()
            }
            
            // Toast notification overlay
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: "Screenshot captured. Check it out in your photos app.")
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            print("MySteps appeared, authorized: \(healthKitManager.isAuthorized)")
            loadData()
            
            // Set a maximum timeout for loading state
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if isLoading {
                    print("Loading timeout reached, forcing loading state to end")
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Manages the data loading state and refreshes step count
    private func loadData() {
        print("Loading data, current step count: \(healthKitManager.stepCount)")
        
        // Always request a fresh step count
        healthKitManager.refreshStepCount()
        
        // If we already have step data, hide the loader immediately
        if healthKitManager.stepCount > 0 {
            print("Steps already available, hiding loader")
            isLoading = false
        } else {
            // Add a short delay to allow data to load
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("Checking steps after delay: \(healthKitManager.stepCount)")
                isLoading = false
            }
        }
    }
    
    /// Captures and saves a screenshot of the current view
    private func captureScreenshot() {
        // Modern way to get the key window using UIWindowScene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("Could not capture window for screenshot")
            return
        }
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, window.isOpaque, scale)
        defer { UIGraphicsEndImageContext() }

        if let context = UIGraphicsGetCurrentContext() {
            window.layer.render(in: context)
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                
                // Show and automatically hide the toast
                withAnimation {
                    showToast = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
    }}
