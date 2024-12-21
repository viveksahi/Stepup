import SwiftUI

struct About: View {
    var backgroundColor: Color
    
    private let faqs = [
        FAQ(
            question: "What is Stepup?",
            answer: "Stepup is not your typical step counter. It's a fun, slightly offensive app that counts your steps and roasts you based on your activity level. Perfect for those who need motivation with a side of humor."
        ),
        FAQ(
            question: "How does the goal system work?",
            answer: "Your daily step goal is randomly set between 5000-8000 steps. The twist? The goal is masked and each digit is revealed only after you complete 1000 steps. It's like a game where you unlock pieces of your target!"
        ),
        FAQ(
            question: "Why did we make this?",
            answer: "We wanted to make fitness tracking fun and less serious. Sometimes the best motivation comes with a laugh, even if it's at your own expense. Plus, who doesn't love a good roast?"
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Title
                    Text("Stepup")
                        .font(.system(size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // FAQ Section
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(faqs) { faq in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(faq.question)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(faq.answer)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    .padding()
                    
                    // Website Button
                    Button(action: {
                        if let url = URL(string: "https://viveksahi.github.io/Stepup-app/index.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Contact Us")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
        }
    }
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}
