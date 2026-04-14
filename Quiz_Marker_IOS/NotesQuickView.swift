import SwiftUI

/// Editable notes sheet shown during a quiz.
/// Notes can be read, edited, and created without leaving the quiz.
struct NotesQuickView: View {
    let store: QuizStore

    @Environment(\.dismiss) private var dismiss

    // Which note is currently open for editing
    @State private var expandedID:   UUID?   = nil
    @State private var editingTitle: String  = ""
    @State private var editingBody:  String  = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(store.notes) { note in
                        noteCard(note)
                    }

                    if store.notes.isEmpty {
                        emptyHint
                    }
                }
                .padding()
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveCurrentNote()
                        cleanUpEmptyNote()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createNewNote()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }

    // MARK: - Empty Hint

    private var emptyHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "note.text")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No notes yet")
                .font(.headline)
            Text("Tap the pencil icon to write one.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }

    // MARK: - Note Card

    private func noteCard(_ note: Note) -> some View {
        let isExpanded = expandedID == note.id

        return VStack(alignment: .leading, spacing: 0) {

            // ── Header row ──
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    if isExpanded {
                        saveCurrentNote()
                        cleanUpEmptyNote()
                        expandedID = nil
                    } else {
                        saveCurrentNote()
                        open(note)
                    }
                }
            } label: {
                HStack {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            // ── Editable body ──
            if isExpanded {
                Divider().padding(.horizontal, 14)

                TextField("Title", text: $editingTitle)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .onChange(of: editingTitle) { _, _ in saveCurrentNote() }

                Divider().padding(.horizontal, 14).padding(.top, 6)

                TextEditor(text: $editingBody)
                    .font(.body)
                    .frame(minHeight: 120, maxHeight: 220)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .scrollContentBackground(.hidden)
                    .onChange(of: editingBody) { _, _ in saveCurrentNote() }

                // Subtle placeholder when body is empty
                .overlay(alignment: .topLeading) {
                    if editingBody.isEmpty {
                        Text("Write your note…")
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .allowsHitTesting(false)
                    }
                }

                Divider().padding(.horizontal, 14)
                    .padding(.bottom, 4)
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
    }

    // MARK: - Actions

    private func open(_ note: Note) {
        expandedID   = note.id
        editingTitle = note.title
        editingBody  = note.body
    }

    private func createNewNote() {
        saveCurrentNote()
        cleanUpEmptyNote()
        let note = store.addNote(title: "", body: "")
        withAnimation { open(note) }
    }

    /// Persists whatever is currently in the edit fields.
    private func saveCurrentNote() {
        guard let id = expandedID else { return }
        store.updateNote(id: id, title: editingTitle, body: editingBody)
    }

    /// Removes a note that was created but left completely blank.
    private func cleanUpEmptyNote() {
        guard let id = expandedID else { return }
        let t = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = editingBody.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty && b.isEmpty {
            store.deleteNote(id: id)
        }
        expandedID = nil
    }
}
