import SwiftUI

/// Lists full practice exams (files named like "Practice Test - N3 2019.csv") and lets the
/// user jump straight into taking one — no unit/chapter picking, the whole file at once.
struct PracticeTestListView: View {
    @Binding var path: NavigationPath

    @State private var files:          [String]       = []
    @State private var questionCounts: [String: Int]   = [:]
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Looking for tests…")
            } else if files.isEmpty {
                emptyState
            } else {
                List(files, id: \.self) { file in
                    Button {
                        path.append(QuizRoute.activeQuiz(file: file, units: [], chapters: [], limit: 0))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayName(for: file))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let count = questionCounts[file] {
                                    Text("\(count) question\(count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Practice Tests")
        .onAppear(perform: loadFiles)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No practice tests yet")
                .font(.title3.bold())
            Text("Ask to have an old test added — it'll show up here as its own full exam you can take in one sitting.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Data

    private func loadFiles() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) else {
            isLoading = false
            return
        }
        let found = urls.map { $0.lastPathComponent }
            .filter { isPracticeTestFile($0) }
            .sorted()

        DispatchQueue.global(qos: .userInitiated).async {
            var counts: [String: Int] = [:]
            for f in found {
                counts[f] = QuizDataService(file: f)?.questionCount(units: [], chapters: []) ?? 0
            }
            DispatchQueue.main.async {
                files          = found
                questionCounts = counts
                isLoading      = false
            }
        }
    }

    private func displayName(for file: String) -> String {
        file.replacingOccurrences(of: ".csv", with: "")
    }
}
