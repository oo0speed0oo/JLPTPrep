import SwiftUI

struct MainMenuView: View {
    @State private var path = NavigationPath()
    @State private var quizFiles: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            List(quizFiles, id: \.self) { file in
                Button(file.replacingOccurrences(of: ".csv", with: "").capitalized) {
                    processSelection(file)
                }
            }
            .navigationTitle("Select a Quiz")
            .navigationDestination(for: QuizRoute.self) { route in
                // FIXED: Updated switch cases to match the labeled enum parameters
                switch route {
                case .unitSelection(let f):
                    UnitSelectionView(path: $path, file: f)
                    
                case .chapterSelection(let f, let u):
                    ChapterSelectionView(path: $path, file: f, units: u)
                    
                case .questionCount(let f, let u, let c):
                    QuestionCountView(path: $path, file: f, units: u, chapters: c)
                    
                case .activeQuiz(let f, let u, let c, let l):
                    QuizView(path: $path, file: f, units: u, chapters: c, limit: l)
                }
            }
        }
        .onAppear { loadFiles() }
    }
    
    func loadFiles() {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) {
            quizFiles = urls.map { $0.lastPathComponent }.sorted()
        }
    }
    
    func processSelection(_ file: String) {
        // FIXED: Added argument label 'file:'
        path.append(QuizRoute.unitSelection(file: file))
    }
}
