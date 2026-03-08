import Foundation
import Observation

@Observable
class QuizManager {
    var questions: [Question] = []
    var currentIndex = 0
    var score = 0
    var isFinished = false
    
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    func loadQuestions(filename: String, units: [String], chapters: [String], limit: Int) {
        let cleanName = filename.replacingOccurrences(of: ".csv", with: "")
        
        guard let path = Bundle.main.path(forResource: cleanName, ofType: "csv") else {
            print("❌ Error: CSV file \(filename) not found.")
            return
        }
        
        var loaded: [Question] = []
        
        do {
            // Use the encoding that was working for you previously
            let content = try String(contentsOfFile: path, encoding: .utf8)
            
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for line in lines.dropFirst() {
                // Use safeSplit to handle commas inside Japanese text correctly
                let cols = CSVParser.safeSplit(line: line)
                
                // Ensure there are enough columns to prevent index out of range
                if cols.count < 9 { continue }
                
                let qUnit = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let qChap = cols[2].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Filtering logic
                let unitMatch = units.isEmpty || units.contains { $0.trimmed == qUnit }
                let chapMatch = chapters.isEmpty || chapters.contains { $0.trimmed == qChap }
                
                if unitMatch && chapMatch {
                    let q = Question(
                        number: cols[0].trimmingCharacters(in: .whitespacesAndNewlines),
                        unit: qUnit,
                        chapter: qChap,
                        text: cols[3].trimmingCharacters(in: .whitespacesAndNewlines),
                        choices: [
                            "A": cols[4].trimmingCharacters(in: .whitespacesAndNewlines),
                            "B": cols[5].trimmingCharacters(in: .whitespacesAndNewlines),
                            "C": cols[6].trimmingCharacters(in: .whitespacesAndNewlines),
                            "D": cols[7].trimmingCharacters(in: .whitespacesAndNewlines)
                        ],
                        answer: cols[8].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    )
                    loaded.append(q)
                }
            }
            
            print("✅ Loaded \(loaded.count) questions.")
            
            DispatchQueue.main.async {
                let shuffled = loaded.shuffled()
                // Safely handle the limit
                let actualLimit = limit > 0 ? min(limit, shuffled.count) : shuffled.count
                self.questions = Array(shuffled.prefix(actualLimit))
                self.currentIndex = 0
                self.score = 0
                self.isFinished = false
            }
            
        } catch {
            print("❌ Read Error: \(error.localizedDescription)")
        }
    }
    
    func checkAnswer(_ letter: String) -> Bool {
        guard let current = currentQuestion else { return false }
        let correct = current.answer == letter.uppercased()
        if correct { score += 1 }
        return correct
    }
    
    func nextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }
}

extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
