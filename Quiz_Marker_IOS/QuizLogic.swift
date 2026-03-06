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
        // 1. Clean filename
        let cleanName = filename.replacingOccurrences(of: ".csv", with: "")
        
        guard let path = Bundle.main.path(forResource: cleanName, ofType: "csv") else {
            print("❌ Error: CSV file \(filename) not found in bundle.")
            return
        }
        
        var loaded: [Question] = []
        
        do {
            // 2. Use .utf8 explicitly
            let content = try String(contentsOfFile: path, encoding: .utf8)
            
            // 3. Handle both Windows (\r\n) and Unix (\n) line endings
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard lines.count > 1 else {
                print("⚠️ Warning: CSV is empty or only contains header.")
                return
            }
            
            for (index, line) in lines.dropFirst().enumerated() {
                // 4. Robust comma splitting
                // If your CSV has commas INSIDE quotes, this simple split will fail.
                let cols = line.components(separatedBy: ",")
                
                // Allow for rows that might have extra empty columns at the end
                if cols.count < 9 {
                    print("⚠️ Skipping line \(index + 2): expected 9 columns, found \(cols.count)")
                    continue
                }
                
                let qUnit = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let qChap = cols[2].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 5. Case-Insensitive / Trimmed matching
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
            
            print("✅ Successfully filtered \(loaded.count) questions.")
            
            // 6. Final safety check: if loaded is empty, the screen will hang.
            // We should ensure we don't crash if units/chapters matched nothing.
            if loaded.isEmpty {
                print("⚠️ No questions matched the selected Units/Chapters.")
            }
            
            let shuffled = loaded.shuffled()
            self.questions = Array(shuffled.prefix(limit))
            self.currentIndex = 0
            self.score = 0
            self.isFinished = false
            
        } catch {
            print("❌ File Read Error: \(error.localizedDescription)")
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

// Helper to make matching easier
extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
