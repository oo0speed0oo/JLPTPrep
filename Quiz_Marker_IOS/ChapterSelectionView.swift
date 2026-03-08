import SwiftUI

struct ChapterSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    
    @State private var chapters: [String] = []
    @State private var selectedChapters: Set<String> = []

    var body: some View {
        VStack(spacing: 20) {
            if chapters.isEmpty {
                Spacer()
                VStack(spacing: 15) {
                    ProgressView()
                    Text("Searching for chapters...")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Button(selectedChapters.count == chapters.count ? "Deselect All" : "Select All") {
                        if selectedChapters.count == chapters.count {
                            selectedChapters = []
                        } else {
                            selectedChapters = Set(chapters)
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }

                List(chapters, id: \.self) { chapter in
                    Button(action: {
                        if selectedChapters.contains(chapter) {
                            selectedChapters.remove(chapter)
                        } else {
                            selectedChapters.insert(chapter)
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedChapters.contains(chapter) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedChapters.contains(chapter) ? .blue : .secondary)
                                .font(.system(size: 20))
                            
                            Text("Chapter \(chapter)")
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button(action: {
                let sortedChapters = Array(selectedChapters).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                path.append(QuizRoute.questionCount(file: file, units: units, chapters: sortedChapters))
            }) {
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
        .navigationTitle("Select Chapters")
        .onAppear(perform: loadChapters)
    }

    func loadChapters() {
        let resourceName = file.replacingOccurrences(of: ".csv", with: "")
        guard let filepath = Bundle.main.path(forResource: resourceName, ofType: "csv"),
              let content = try? String(contentsOfFile: filepath, encoding: .utf8) else {
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            
        guard let headerLine = lines.first else { return }
        let headers = CSVParser.safeSplit(line: headerLine)
        
        // 1. DYNAMIC INDEX: Find where 'unit' and 'chapter' columns are
        let unitIndex = headers.firstIndex { $0.lowercased().contains("unit") }
        let chapterIndex = headers.firstIndex { $0.lowercased().contains("chapter") } ?? 2
            
        var foundChapters = Set<String>()
        
        for line in lines.dropFirst() {
            let cols = CSVParser.safeSplit(line: line)
            
            if cols.count > chapterIndex {
                let c = cols[chapterIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 2. SMART FILTERING
                if units.isEmpty {
                    // No units selected (screen skipped), so show ALL chapters
                    if !c.isEmpty { foundChapters.insert(c) }
                } else if let uIndex = unitIndex, cols.count > uIndex {
                    // Units ARE selected, so only show chapters for those units
                    let u = cols[uIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    if units.contains(u) && !c.isEmpty {
                        foundChapters.insert(c)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            if foundChapters.isEmpty {
                // If no chapters found, skip to count screen
                path.append(QuizRoute.questionCount(file: file, units: units, chapters: []))
            } else {
                self.chapters = foundChapters.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                self.selectedChapters = []
            }
        }
    }
}
