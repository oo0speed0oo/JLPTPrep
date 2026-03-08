import SwiftUI

struct UnitSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    
    @State private var units: [String] = []
    @State private var selectedUnits: Set<String> = []
    @State private var hasAttemptedLoad = false

    var body: some View {
        VStack(spacing: 20) {
            if units.isEmpty {
                Spacer()
                VStack(spacing: 15) {
                    ProgressView()
                    Text("Searching for units...")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Button(selectedUnits.count == units.count ? "Deselect All" : "Select All") {
                        if selectedUnits.count == units.count {
                            selectedUnits = []
                        } else {
                            selectedUnits = Set(units)
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }

                List(units, id: \.self) { unit in
                    Button(action: {
                        if selectedUnits.contains(unit) {
                            selectedUnits.remove(unit)
                        } else {
                            selectedUnits.insert(unit)
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedUnits.contains(unit) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedUnits.contains(unit) ? .blue : .secondary)
                                .font(.system(size: 20))
                            
                            Text("Unit \(unit)")
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button(action: {
                let sortedSelection = Array(selectedUnits).sorted()
                path.append(QuizRoute.chapterSelection(file: file, units: sortedSelection))
            }) {
                Text("Continue to Chapters")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedUnits.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedUnits.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Select Units")
        .onAppear(perform: loadUnits)
    }
    
    func loadUnits() {
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
        
        // 1. SMART CHECK: Look for the word "unit" in the header columns
        let unitColumnIndex = headers.firstIndex { $0.lowercased().contains("unit") }
        
        var foundUnits = Set<String>()

        // 2. Only search for units if a "Unit" column actually exists
        if let index = unitColumnIndex {
            for line in lines.dropFirst() {
                let cols = CSVParser.safeSplit(line: line)
                if cols.count > index {
                    let u = cols[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !u.isEmpty {
                        foundUnits.insert(u)
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.hasAttemptedLoad = true
            
            if foundUnits.isEmpty {
                // ✅ AUTO-SKIP: No "unit" column found, go straight to Chapters
                path.append(QuizRoute.chapterSelection(file: file, units: []))
            } else {
                self.units = foundUnits.sorted()
            }
        }
    }
}
