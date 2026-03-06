import SwiftUI

struct UnitSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    
    @State private var units: [String] = []
    @State private var selectedUnits: Set<String> = []

    var body: some View {
        VStack {
            Text("Select Units")
                .font(.title.bold())
                .padding()

            if units.isEmpty {
                Spacer()
                Text("Searching for units...")
                    .foregroundColor(.secondary)
                ProgressView()
                Spacer()
            } else {
                // ADDED: Select/Deselect All Toggle
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
                    .padding(.trailing)
                }

                List(units, id: \.self) { unit in
                    Toggle("Unit \(unit)", isOn: Binding(
                        get: { selectedUnits.contains(unit) },
                        set: { isSelected in
                            if isSelected {
                                selectedUnits.insert(unit)
                            } else {
                                selectedUnits.remove(unit)
                            }
                        }
                    ))
                }
            }

            Button("Continue to Chapters") {
                let sortedSelection = Array(selectedUnits).sorted()
                path.append(QuizRoute.chapterSelection(file: file, units: sortedSelection))
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedUnits.isEmpty)
            .padding()
        }
        .navigationTitle("Units")
        .onAppear(perform: loadUnits)
    }

    func loadUnits() {
        let resourceName = file.replacingOccurrences(of: ".csv", with: "")
        guard let filepath = Bundle.main.path(forResource: resourceName, ofType: "csv") else {
            print("❌ CSV File not found: \(file)")
            return
        }
        
        do {
            let content = try String(contentsOfFile: filepath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            var foundUnits = Set<String>()
            
            for line in lines.dropFirst() {
                let cols = line.components(separatedBy: ",")
                if cols.count > 1 {
                    let u = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !u.isEmpty {
                        foundUnits.insert(u)
                    }
                }
            }
            
            self.units = foundUnits.sorted()
            
            // FIX: Initialize with an empty set so nothing is clicked on start
            self.selectedUnits = []
            
        } catch {
            print("❌ Error loading CSV: \(error.localizedDescription)")
        }
    }
}
