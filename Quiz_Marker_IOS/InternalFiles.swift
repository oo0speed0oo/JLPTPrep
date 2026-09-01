import Foundation

/// CSV files that exist only for internal app use — never shown in any file picker.
let hiddenQuizFiles: Set<String> = ["grammar_rules.csv", "quiz_scores.csv"]

/// Files that make up a full practice exam, by naming convention (e.g. "Practice Test - N3 2019.csv").
/// Shown only in the Practice Tests section, never in Study/Flashcards/SRS's general file pickers.
func isPracticeTestFile(_ fileName: String) -> Bool {
    fileName.localizedCaseInsensitiveContains("practice test")
}
