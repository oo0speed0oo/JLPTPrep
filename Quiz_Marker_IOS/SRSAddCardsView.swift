import SwiftUI

private let srsHiddenFiles: Set<String> = ["grammar_rules.csv", "quiz_scores.csv"]

// MARK: - File Select

struct SRSFileSelectView: View {
    @Binding var path: NavigationPath
    @State private var files: [String] = []

    var body: some View {
        List(files, id: \.self) { file in
            Button(displayName(for: file)) {
                path.append(QuizRoute.srsUnitSelection(file: file))
            }
            .foregroundColor(.primary)
        }
        .navigationTitle("Choose a Deck")
        .onAppear(perform: loadFiles)
    }

    private func loadFiles() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) else { return }
        files = urls.map { $0.lastPathComponent }
            .filter { !srsHiddenFiles.contains($0) }
            .sorted()
    }

    private func displayName(for file: String) -> String {
        file.replacingOccurrences(of: ".csv", with: "").capitalized
    }
}

// MARK: - Unit Select

struct SRSUnitSelectionView: View {
    @Binding var path: NavigationPath
    let file: String

    @State private var units:         [String]    = []
    @State private var selectedUnits: Set<String> = []
    @State private var isLoading = true

    var allSelected: Bool { selectedUnits.count == units.count }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                Spacer()
                ProgressView("Searching for units…")
                Spacer()
            } else if units.isEmpty {
                Spacer()
                Text("This file has no unit structure.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Button(allSelected ? "Deselect All" : "Select All") {
                        selectedUnits = allSelected ? [] : Set(units)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }

                List(units, id: \.self) { unit in
                    Button {
                        if selectedUnits.contains(unit) { selectedUnits.remove(unit) }
                        else { selectedUnits.insert(unit) }
                    } label: {
                        HStack {
                            Image(systemName: selectedUnits.contains(unit)
                                  ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedUnits.contains(unit) ? .purple : .secondary)
                                .font(.system(size: 20))
                            Text("Unit \(unit)").foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                let sorted = Array(selectedUnits).sorted()
                path.append(QuizRoute.srsChapterSelection(file: file, units: sorted))
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedUnits.isEmpty && !units.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedUnits.isEmpty && !units.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Select Units")
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let found = QuizDataService(file: file)?.allUnits ?? []
                DispatchQueue.main.async {
                    isLoading = false
                    units     = found
                }
            }
        }
    }
}

// MARK: - Chapter Select

struct SRSChapterSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    let store: QuizStore

    @State private var chapters:         [String]    = []
    @State private var totalPerChapter:  [String: Int] = [:]
    @State private var selectedChapters: Set<String> = []
    @State private var isLoading = true

    /// Chapters where every matching question is already in the SRS deck.
    private func isChapterFullyAdded(_ chapter: String) -> Bool {
        let total = totalPerChapter[chapter] ?? 0
        guard total > 0 else { return false }
        let added = store.srsCards.filter { $0.file == file && $0.chapter == chapter }.count
        return added >= total
    }

    private func addedCount(for chapter: String) -> Int {
        store.srsCards.filter { $0.file == file && $0.chapter == chapter }.count
    }

    private var selectableChapters: [String] { chapters.filter { !isChapterFullyAdded($0) } }
    var allSelected: Bool { !selectableChapters.isEmpty && selectedChapters.count == selectableChapters.count }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                Spacer()
                ProgressView("Searching for chapters…")
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Button(allSelected ? "Deselect All" : "Select All") {
                        selectedChapters = allSelected ? [] : Set(selectableChapters)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                    .disabled(selectableChapters.isEmpty)
                }

                List(chapters, id: \.self) { chapter in
                    let fullyAdded = isChapterFullyAdded(chapter)
                    let added      = addedCount(for: chapter)
                    let total      = totalPerChapter[chapter] ?? 0

                    Button {
                        guard !fullyAdded else { return }
                        if selectedChapters.contains(chapter) { selectedChapters.remove(chapter) }
                        else { selectedChapters.insert(chapter) }
                    } label: {
                        HStack {
                            Image(systemName: selectedChapters.contains(chapter)
                                  ? "checkmark.square.fill" : "square")
                                .foregroundColor(fullyAdded ? .secondary.opacity(0.3)
                                                 : (selectedChapters.contains(chapter) ? .purple : .secondary))
                                .font(.system(size: 20))
                            Text("Chapter \(chapter)")
                                .foregroundColor(fullyAdded ? .secondary : .primary)
                            Spacer()
                            if fullyAdded {
                                Label("Added", systemImage: "checkmark.circle.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(10)
                            } else if added > 0 {
                                Text("\(added) / \(total)")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(fullyAdded)
                }
            }

            Button {
                let sorted = Array(selectedChapters).sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }
                path.append(QuizRoute.srsAddConfirm(file: file, units: units, chapters: sorted))
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedChapters.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedChapters.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Select Chapters")
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let service = QuizDataService(file: file)
                let found   = service?.chapters(inUnits: units) ?? []
                let counts  = service?.questionCountPerChapter(inUnits: units) ?? [:]
                DispatchQueue.main.async {
                    isLoading       = false
                    chapters        = found
                    totalPerChapter = counts
                }
            }
        }
    }
}

// MARK: - Confirm & Add

struct SRSAddConfirmView: View {
    @Binding var path: NavigationPath
    let store: QuizStore
    let file: String
    let units: [String]
    let chapters: [String]

    @State private var matched:    [Question] = []
    @State private var isLoading  = true
    @State private var addedCount: Int? = nil

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                Spacer()
                ProgressView("Counting questions…")
                Spacer()
            } else if let added = addedCount {
                resultView(added: added)
            } else {
                confirmView
            }
        }
        .navigationTitle("Add to Deck")
        .navigationBarBackButtonHidden(addedCount != nil)
        .onAppear(perform: loadMatches)
    }

    private var confirmView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            Text("\(matched.count) question\(matched.count == 1 ? "" : "s") match your selection")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("They'll be added to your SRS deck and reviewed on a spaced schedule.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Spacer()
            Button {
                addedCount = store.addManyToSRS(matched, file: file)
            } label: {
                Text("Add to Deck")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(matched.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(matched.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func resultView(added: Int) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)
            Text(added > 0 ? "Added \(added) card\(added == 1 ? "" : "s")!" : "Already in your deck")
                .font(.title2.bold())
            if added < matched.count {
                Text("\(matched.count - added) were already in your deck.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                path.removeLast(path.count)
            } label: {
                Text("Done")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func loadMatches() {
        DispatchQueue.global(qos: .userInitiated).async {
            let found = QuizDataService(file: file)?.questions(units: units, chapters: chapters, limit: 0) ?? []
            DispatchQueue.main.async {
                matched   = found
                isLoading = false
            }
        }
    }
}
