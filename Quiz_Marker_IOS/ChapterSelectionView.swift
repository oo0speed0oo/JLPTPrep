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
                ProgressView("Loading Chapters...")
                Spacer()
            } else {
                // ADDED: Select/Deselect All Toggle
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
                    Toggle("Chapter \(chapter)", isOn: Binding(
                        get: { selectedChapters.contains(chapter) },
                        set: { isSelected in
                            if isSelected { selectedChapters.insert(chapter) }
                            else { selectedChapters.remove(chapter) }
                        }
                    ))
                    .toggleStyle(CheckboxToggleStyle())
                }
            }
            
            Button(action: {
                path.append(QuizRoute.questionCount(file: file, units: units, chapters: Array(selectedChapters).sorted()))
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
            print("CSV not found or unreadable")
            return
        }
        
        // Handle both Unix and Windows line endings
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
        var foundChapters = Set<String>()
        
        for line in lines.dropFirst() {
            let cols = line.components(separatedBy: ",")
            if cols.count >= 3 {
                // Use whitespacesAndNewlines to be safe with CSV formatting
                let u = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let c = cols[2].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if units.contains(u) && !c.isEmpty {
                    foundChapters.insert(c)
                }
            }
        }
        
        self.chapters = foundChapters.sorted()
        
        // FIX: Initialize with an empty set so nothing is clicked on start
        self.selectedChapters = []
    }
    
    // This makes the toggle look like a checkbox instead of a switch
    struct CheckboxToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button {
                configuration.isOn.toggle()
            } label: {
                HStack {
                    Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                        .foregroundColor(configuration.isOn ? .blue : .secondary)
                        .font(.system(size: 20))
                    configuration.label
                }
            }
            .buttonStyle(.plain) // Prevents the whole row from flashing when tapped
        }
    }
}
