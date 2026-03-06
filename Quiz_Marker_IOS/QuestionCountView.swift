import SwiftUI

struct QuestionCountView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    let chapters: [String]

    @State private var totalAvailable: Int = 0
    @State private var selectedAmount: Int = 1

    var body: some View {
        VStack(spacing: 20) {
            Text("How many questions?")
                .font(.headline)
            
            if totalAvailable == 0 {
                Text("Searching for matching questions...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(totalAvailable) questions available")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Stepper("\(selectedAmount) Questions", value: $selectedAmount, in: 1...max(1, totalAvailable))
                .padding()
                .disabled(totalAvailable == 0)

            Button("Start Quiz") {
                // FIXED: Added missing argument labels
                path.append(QuizRoute.activeQuiz(file: file, units: units, chapters: chapters, limit: selectedAmount))
            }
            .buttonStyle(.borderedProminent)
            .disabled(totalAvailable == 0)
        }
        .navigationTitle("Questions")
        .onAppear(perform: countPossibleQuestions)
    }

    func countPossibleQuestions() {
        let resourceName = file.replacingOccurrences(of: ".csv", with: "")
        guard let filepath = Bundle.main.path(forResource: resourceName, ofType: "csv"),
              let content = try? String(contentsOfFile: filepath, encoding: .utf8) else { return }
        
        // Use .newlines to handle different CSV formats
        let lines = content.components(separatedBy: .newlines).dropFirst()
        var count = 0
        
        for line in lines {
            let cols = line.components(separatedBy: ",")
            if cols.count > 2 {
                // Robust trimming including newlines
                let u = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let c = cols[2].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if units.contains(u) && chapters.contains(c) {
                    count += 1
                }
            }
        }
        
        self.totalAvailable = count
        // Default to showing all questions, but at least 1
        self.selectedAmount = max(1, count)
    }
}
