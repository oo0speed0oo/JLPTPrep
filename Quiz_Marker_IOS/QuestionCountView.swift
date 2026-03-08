import SwiftUI

struct QuestionCountView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    let chapters: [String]

    @State private var totalAvailable: Int = 0
    @State private var selectedAmount: Int = 1
    
    @State private var amountString: String = "1"
    @FocusState private var isInputActive: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("How many questions?")
                .font(.headline)
            
            if totalAvailable == 0 {
                VStack {
                    ProgressView()
                    Text("Searching for matching questions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 10) {
                    Text("\(totalAvailable) questions available")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    HStack {
                        Text("Enter Amount:")
                        
                        TextField("", text: $amountString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(10)
                            .frame(width: 80)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .focused($isInputActive)
                            .onChange(of: amountString) { oldValue, newValue in
                                validateInput(newValue)
                            }
                    }
                    .font(.title3)
                }
            }
            
            Button("Start Quiz") {
                path.append(QuizRoute.activeQuiz(file: file, units: units, chapters: chapters, limit: selectedAmount))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(totalAvailable == 0 || selectedAmount < 1)
        }
        .navigationTitle("Questions")
        .onAppear(perform: countPossibleQuestions)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
            }
        }
    }

    func validateInput(_ value: String) {
        let filtered = value.filter { "0123456789".contains($0) }
        if let currentInt = Int(filtered) {
            if currentInt > totalAvailable {
                selectedAmount = totalAvailable
                amountString = "\(totalAvailable)"
            } else {
                selectedAmount = currentInt
                amountString = filtered
            }
        } else if filtered.isEmpty {
            selectedAmount = 0
            amountString = ""
        }
    }

    func countPossibleQuestions() {
        let resourceName = file.replacingOccurrences(of: ".csv", with: "")
        guard let filepath = Bundle.main.path(forResource: resourceName, ofType: "csv"),
              let content = try? String(contentsOfFile: filepath, encoding: .utf8) else { return }
        
        let allLines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard let headerLine = allLines.first else { return }
        let headers = CSVParser.safeSplit(line: headerLine)
        
        // 1. Find correct column indexes from the header
        let unitIndex = headers.firstIndex { $0.lowercased().contains("unit") }
        let chapterIndex = headers.firstIndex { $0.lowercased().contains("chapter") } ?? 1
            
        var count = 0
        let dataLines = allLines.dropFirst()
        
        for line in dataLines {
            let cols = CSVParser.safeSplit(line: line)
            
            if cols.count > chapterIndex {
                let c = cols[chapterIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 2. LOGIC FIX: Check if Chapter matches
                let matchesChapter = chapters.contains(c)
                
                // 3. LOGIC FIX: Check Unit ONLY if the units array isn't empty
                var matchesUnit = true
                if !units.isEmpty, let uIdx = unitIndex, cols.count > uIdx {
                    let u = cols[uIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    matchesUnit = units.contains(u)
                } else if !units.isEmpty && unitIndex == nil {
                    // Safety: user picked units but file has no unit column
                    matchesUnit = false
                }

                if matchesUnit && matchesChapter {
                    count += 1
                }
            }
        }
        
        DispatchQueue.main.async {
            // Safety: If somehow 0 are found, set to 0 but allow the UI to move on
            // or show a "No Questions" state.
            self.totalAvailable = count
            self.selectedAmount = count
            self.amountString = "\(count)"
            
            // If the file is broken and count is really 0, we shouldn't hang
            if count == 0 {
                self.totalAvailable = -1 // Temporary flag to show "No questions found"
            }
        }
    }
}
