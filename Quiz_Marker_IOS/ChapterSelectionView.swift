import SwiftUI

struct ChapterSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    let store: QuizStore

    @State private var chapters:         [String]      = []
    @State private var selectedChapters: Set<String>   = []
    @State private var totalPerChapter:  [String: Int] = [:]
    @State private var isLoading = true

    var allSelected: Bool { selectedChapters.count == chapters.count }

    private var quizName: String {
        file.replacingOccurrences(of: ".csv", with: "").capitalized
    }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                Spacer()
                ProgressView("Searching for chapters…")
                Spacer()
            } else {
                selectAllButton
                chapterList
            }
            continueButton
        }
        .navigationTitle("Select Chapters")
        .onAppear(perform: loadChapters)
    }

    // MARK: - Subviews

    private var selectAllButton: some View {
        HStack {
            Spacer()
            Button(allSelected ? "Deselect All" : "Select All") {
                selectedChapters = allSelected ? [] : Set(chapters)
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
    }

    private var chapterList: some View {
        List(chapters, id: \.self) { chapter in
            Button {
                if selectedChapters.contains(chapter) {
                    selectedChapters.remove(chapter)
                } else {
                    selectedChapters.insert(chapter)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: selectedChapters.contains(chapter)
                          ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedChapters.contains(chapter) ? .blue : .secondary)
                        .font(.system(size: 20))

                    Text("Chapter \(chapter)")
                        .foregroundColor(.primary)

                    Spacer()

                    chapterBadge(for: chapter)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Badge
    // Left pill:  "5 / 15"  in blue
    // Right pill: "Weak" / "OK" / "Good" / "Strong"  in grade colour

    @ViewBuilder
    private func chapterBadge(for chapter: String) -> some View {
        let csvTotal = totalPerChapter[chapter] ?? 0   // total questions in CSV for this chapter
        let attempt  = store.chapterAttempt(chapter: chapter, quizName: quizName)

        if let attempt {
            // attempted = how many questions the user has actually answered (right or wrong)
            // correct   = how many of those they got right
            // grade     = correct / attempted  (quality of answers so far)
            let attempted = attempt.total                          // e.g. 8
            let correct   = min(attempt.correct, attempted)        // e.g. 5
            let gradePct  = attempted > 0
                ? Double(correct) / Double(attempted)
                : 0.0
            let (label, labelColor) = gradeInfo(gradePct)

            HStack(spacing: 4) {
                // "8 / 15" — how many you've done out of how many exist
                Text("\(attempted) / \(csvTotal)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(10)

                // "Strong" — how well you did on what you attempted
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(labelColor)
                    .cornerRadius(10)
            }

        } else {
            // Never studied
            HStack(spacing: 4) {
                Text("0 / \(csvTotal)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(10)

                Text("New")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Grade Helpers

    /// Returns (label, color) based on fraction 0.0–1.0
    private func gradeInfo(_ pct: Double) -> (String, Color) {
        switch pct {
        case 0.85...: return ("Strong",     .green)
        case 0.65...: return ("Good",       .teal)
        case 0.40...: return ("OK",         .orange)
        default:      return ("Weak",       .red)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            let sorted = Array(selectedChapters).sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
            path.append(QuizRoute.questionCount(file: file, units: units, chapters: sorted))
        } label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedChapters.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(selectedChapters.isEmpty)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Data

    private func loadChapters() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let service = QuizDataService(file: file) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            let found  = service.chapters(inUnits: units)
            let counts = service.questionCountPerChapter(inUnits: units)
            DispatchQueue.main.async {
                isLoading = false
                if found.isEmpty {
                    path.append(QuizRoute.questionCount(file: file, units: units, chapters: []))
                } else {
                    chapters        = found
                    totalPerChapter = counts
                }
            }
        }
    }
}
