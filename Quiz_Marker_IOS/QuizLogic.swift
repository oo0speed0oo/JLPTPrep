import Foundation
import Observation

// Represents one wrong answer during a session
struct WrongAnswer: Identifiable {
    let id        = UUID()
    let question:  Question
    let chosen:    String   // letter the user picked, e.g. "B"
}

// Represents one correct answer during a session
struct CorrectAnswer: Identifiable {
    let id       = UUID()
    let question: Question
}

@Observable
class QuizManager {
    var questions:      [Question]      = []
    var wrongAnswers:   [WrongAnswer]   = []
    var correctAnswers: [CorrectAnswer] = []   // ← tracks correct per question for chapter scoring
    var currentIndex = 0
    var score        = 0
    var isFinished   = false
    var isLoading    = false

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    func load(file: String, units: [String], chapters: [String], limit: Int) {
        guard !isLoading else { return }
        isLoading      = true
        questions      = []
        wrongAnswers   = []
        correctAnswers = []
        currentIndex   = 0
        score          = 0
        isFinished     = false

        DispatchQueue.global(qos: .userInitiated).async {
            guard let service = QuizDataService(file: file) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            let loaded = service.questions(units: units, chapters: chapters, limit: limit)
            DispatchQueue.main.async {
                self.questions = loaded
                self.isLoading = false
            }
        }
    }

    func reset() {
        questions      = []
        wrongAnswers   = []
        correctAnswers = []
        currentIndex   = 0
        score          = 0
        isFinished     = false
        isLoading      = false
    }

    @discardableResult
    func checkAnswer(_ letter: String) -> Bool {
        guard let current = currentQuestion else { return false }
        let upper   = letter.uppercased()
        let correct = current.answer == upper
        if correct {
            score += 1
            correctAnswers.append(CorrectAnswer(question: current))
        } else {
            wrongAnswers.append(WrongAnswer(question: current, chosen: upper))
        }
        return correct
    }

    func nextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }

    /// Returns per-chapter breakdown: chapter → (correct, total)
    func chapterBreakdown() -> [String: (correct: Int, total: Int)] {
        var result: [String: (correct: Int, total: Int)] = [:]
        for a in correctAnswers {
            let ch = a.question.chapter
            let cur = result[ch] ?? (correct: 0, total: 0)
            result[ch] = (correct: cur.correct + 1, total: cur.total + 1)
        }
        for w in wrongAnswers {
            let ch = w.question.chapter
            let cur = result[ch] ?? (correct: 0, total: 0)
            result[ch] = (correct: cur.correct, total: cur.total + 1)
        }
        return result
    }
}
