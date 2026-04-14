import SwiftUI

/// Read-only notes browser shown as a sheet during a quiz.
struct NotesQuickView: View {
    let store: QuizStore

    @Environment(\.dismiss) private var dismiss
    @State private var expandedIDs: Set<UUID> = []

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if store.notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .navigationTitle("My Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No notes yet")
                .font(.headline)
            Text("Add notes from the main menu.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Notes List

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store.notes) { note in
                    noteCard(note)
                }
            }
            .padding()
        }
    }

    private func noteCard(_ note: Note) -> some View {
        let isExpanded = expandedIDs.contains(note.id)

        return VStack(alignment: .leading, spacing: 0) {
            // Header — always visible, tap to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expandedIDs.remove(note.id) }
                    else          { expandedIDs.insert(note.id) }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(note.title.isEmpty ? "Untitled" : note.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(Self.dateFormatter.string(from: note.updatedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            // Body — shown when expanded
            if isExpanded && !note.body.isEmpty {
                Divider()
                    .padding(.horizontal, 14)
                Text(note.body)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}
