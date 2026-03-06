import SwiftUI

struct QuizView: View {
    @Binding var path: NavigationPath
    
    // Use @State for @Observable class
    @State var manager = QuizManager()
    
    @State private var showingAnswer = false
    @State private var isCorrect = false
    
    let file: String
    let units: [String]
    let chapters: [String]
    let limit: Int

    var body: some View {
        VStack(spacing: 20) {
            if manager.questions.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading Questions...")
                        .foregroundColor(.secondary)
                }
            } else if let q = manager.currentQuestion {
                // 1. Progress
                VStack(spacing: 5) {
                    Text("Question \(manager.currentIndex + 1) / \(manager.questions.count)")
                        .font(.caption)
                    
                    Text("Unit \(q.unit) • Chapter \(q.chapter)")
                        .font(.caption2)
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                }

                // 2. Question Text
                ScrollView {
                    Text(q.text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                // 3. Choices
                VStack(spacing: 12) {
                    // We use sorted keys to ensure we match exactly what is in the dictionary
                    ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                        Button(action: {
                            withAnimation {
                                isCorrect = manager.checkAnswer(letter)
                                showingAnswer = true
                            }
                        }) {
                            HStack {
                                Text("\(letter))")
                                    .fontWeight(.bold)
                                // Use a fallback string if the dictionary key is missing
                                Text(q.choices[letter] ?? "Choice not found")
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(buttonColor(for: letter))
                            .foregroundColor(buttonTextColor(for: letter))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(buttonBorderColor(for: letter), lineWidth: 2)
                            )
                        }
                        .disabled(showingAnswer)
                    }
                }
                .padding(.horizontal)

                // 4. Feedback
                if showingAnswer {
                    VStack(spacing: 15) {
                        Text(isCorrect ? "✅ Correct!" : "❌ Wrong! Correct: \(q.answer)")
                            .font(.headline)
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        Button(action: {
                            showingAnswer = false
                            manager.nextQuestion()
                        }) {
                            Text(manager.currentIndex + 1 < manager.questions.count ? "Next Question" : "See Results")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.loadQuestions(filename: file, units: units, chapters: chapters, limit: limit)
        }
        .alert("Quiz Finished", isPresented: $manager.isFinished) {
            Button("Back to Menu") {
                path = NavigationPath()
            }
        } message: {
            Text("Your final score is \(manager.score) out of \(manager.questions.count).")
        }
    }

    // Improved UI Feedback Colors
    func buttonColor(for letter: String) -> Color {
        guard showingAnswer, let q = manager.currentQuestion else {
            return Color.blue.opacity(0.05)
        }
        if letter == q.answer { return .green.opacity(0.1) }
        return Color.gray.opacity(0.05)
    }
    
    func buttonTextColor(for letter: String) -> Color {
        guard showingAnswer, let q = manager.currentQuestion else { return .primary }
        if letter == q.answer { return .green }
        return .secondary
    }

    func buttonBorderColor(for letter: String) -> Color {
        guard showingAnswer, let q = manager.currentQuestion else { return Color.clear }
        if letter == q.answer { return .green }
        return .clear
    }
}
