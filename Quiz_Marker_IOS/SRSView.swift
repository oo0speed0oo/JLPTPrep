import SwiftUI

// MARK: - Hub

/// Entry point for spaced repetition: review what's due, see deck stats,
/// and jump into the add-cards flow.
struct SRSHubView: View {
    @Binding var path: NavigationPath
    let store: QuizStore

    private var matureCount: Int { store.srsCards.filter { $0.repetitions >= 2 }.count }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    SRSReviewView(store: store)
                } label: {
                    HStack {
                        Label("Review Due Cards", systemImage: "brain.head.profile")
                            .font(.headline)
                        Spacer()
                        if store.dueSRSCount > 0 {
                            Text("\(store.dueSRSCount)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                if store.srsCards.isEmpty {
                    Text("Add words or grammar points below to start building your review deck.")
                } else if store.dueSRSCount == 0 {
                    Text("All caught up! New reviews unlock as their schedule comes due.")
                }
            }

            if !store.srsCards.isEmpty {
                Section("Deck") {
                    statRow("Total cards", "\(store.srsCards.count)")
                    statRow("Due now", "\(store.dueSRSCount)")
                    statRow("Learned", "\(matureCount)")
                }
            }

            Section {
                Button {
                    path.append(QuizRoute.srsFileSelect)
                } label: {
                    Label("Add Words / Grammar to Deck", systemImage: "plus.circle.fill")
                }

                if !store.srsCards.isEmpty {
                    Button(role: .destructive) {
                        store.clearSRS()
                    } label: {
                        Label("Clear Deck", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("SRS")
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

// MARK: - Review Session

/// Works through every card that's currently due, using SM-2 style self-grading.
/// "Again" resurfaces the card later in the same session; every other grade
/// pushes it to a future due date and removes it from the current queue.
struct SRSReviewView: View {
    let store: QuizStore

    @Environment(\.dismiss) private var dismiss

    private struct QueueItem: Identifiable {
        var card: SRSCardState
        let question: Question
        var id: UUID { card.id }
    }

    @State private var queue:         [QueueItem] = []
    @State private var currentIndex   = 0
    @State private var showingAnswer  = false
    @State private var showingMeaning = false
    @State private var isLoading      = true
    @State private var reviewedCount  = 0

    // Practice replay — same questions, no effect on SRS scheduling.
    @State private var isPracticing           = false
    @State private var practiceQuestions:      [Question] = []
    @State private var practiceIndex           = 0
    @State private var practiceShowingAnswer   = false
    @State private var practiceShowingMeaning  = false

    private var current: QueueItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading due cards…")
            } else if queue.isEmpty {
                emptyState
            } else if isPracticing {
                if practiceIndex >= practiceQuestions.count {
                    practiceFinishedView
                } else {
                    practiceQuestionView(for: practiceQuestions[practiceIndex])
                }
            } else if currentIndex >= queue.count {
                finishedView
            } else if let item = current {
                questionView(for: item)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadQueue)
    }

    // MARK: - Load

    private func loadQueue() {
        DispatchQueue.global(qos: .userInitiated).async {
            let due = store.dueSRSCards()
            var services: [String: QuizDataService] = [:]
            var items: [QueueItem] = []

            for card in due {
                let service = services[card.file] ?? QuizDataService(file: card.file)
                guard let service else { continue }
                services[card.file] = service
                guard let q = service.question(number: card.questionNumber) else { continue }
                items.append(QueueItem(card: card, question: q))
            }

            DispatchQueue.main.async {
                queue             = items
                practiceQuestions = items.map { $0.question }
                isLoading         = false
            }
        }
    }

    // MARK: - Practice Replay

    private func startPracticeRound() {
        practiceIndex          = 0
        practiceShowingAnswer  = false
        practiceShowingMeaning = false
        isPracticing           = true
    }

    private func advancePractice() {
        practiceShowingAnswer  = false
        practiceShowingMeaning = false
        practiceIndex += 1
    }

    // MARK: - Empty / Finished

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: store.srsCards.isEmpty ? "rectangle.stack.badge.plus" : "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.4))
            Text(store.srsCards.isEmpty ? "Your deck is empty" : "Nothing due right now")
                .font(.title3.bold())
            Text(store.srsCards.isEmpty
                 ? "Go back and tap \"Add Words / Grammar to Deck\" to get started."
                 : "Come back later, or add more cards to your deck.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var finishedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            Text("Review Complete!")
                .font(.largeTitle.bold())
            Text("\(reviewedCount) card\(reviewedCount == 1 ? "" : "s") reviewed")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                startPracticeRound()
            } label: {
                Text("Review Again")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.12))
                    .foregroundColor(.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Button {
                dismiss()
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
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    private var practiceFinishedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Practice Complete!")
                .font(.largeTitle.bold())
            Text("Your SRS schedule wasn't affected.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                startPracticeRound()
            } label: {
                Text("Review Again")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.12))
                    .foregroundColor(.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Practice Question View

    @ViewBuilder
    private func practiceQuestionView(for q: Question) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Text("Practice \(practiceIndex + 1) of \(practiceQuestions.count)")
                    Spacer()
                    Label("Not scored", systemImage: "checkmark.shield")
                }
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

                questionTextBlock(q)

                if practiceShowingAnswer {
                    choicesRevealBlock(q)
                    if !q.meaning.isEmpty {
                        practiceMeaningBlock(q)
                    }
                    Button {
                        advancePractice()
                    } label: {
                        Text(practiceIndex + 1 < practiceQuestions.count ? "Next Card" : "Finish")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        withAnimation { practiceShowingAnswer = true }
                    } label: {
                        Text("Show Answer")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func practiceMeaningBlock(_ q: Question) -> some View {
        if practiceShowingMeaning {
            Text(q.meaning)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
                .padding(.horizontal)
        } else {
            Button {
                withAnimation { practiceShowingMeaning = true }
            } label: {
                Label("Show Meaning", systemImage: "character.book.closed")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Question View

    @ViewBuilder
    private func questionView(for item: QueueItem) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                progressHeader
                metaHeader(item)
                questionTextBlock(item.question)

                if showingAnswer {
                    choicesRevealBlock(item.question)
                    if !item.question.meaning.isEmpty {
                        meaningBlock(item.question)
                    }
                    gradingButtons(for: item)
                } else {
                    Button {
                        withAnimation { showingAnswer = true }
                    } label: {
                        Text("Show Answer")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var progressHeader: some View {
        HStack {
            Text("Card \(currentIndex + 1) of \(queue.count)")
            Spacer()
            if reviewedCount > 0 {
                Label("\(reviewedCount) reviewed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .font(.caption.bold())
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }

    private func metaHeader(_ item: QueueItem) -> some View {
        HStack {
            Label(item.card.file.replacingOccurrences(of: ".csv", with: "").capitalized,
                  systemImage: "book.closed")
                .lineLimit(1)
            Spacer()
            if !item.question.unit.isEmpty    { Text("Unit \(item.question.unit)") }
            if !item.question.chapter.isEmpty { Text("Ch. \(item.question.chapter)") }
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .padding(8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private func questionTextBlock(_ q: Question) -> some View {
        Text(q.text)
            .font(.title3)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
    }

    private func choicesRevealBlock(_ q: Question) -> some View {
        VStack(spacing: 8) {
            ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                let isCorrect = letter == q.answer
                HStack {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCorrect ? .green : .secondary)
                    Text("\(letter): \(q.option(for: letter))")
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isCorrect ? Color.green.opacity(0.15) : Color.gray.opacity(0.08))
                .foregroundColor(isCorrect ? .green : .primary)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Meaning (on-demand reveal)

    @ViewBuilder
    private func meaningBlock(_ q: Question) -> some View {
        if showingMeaning {
            Text(q.meaning)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
                .padding(.horizontal)
        } else {
            Button {
                withAnimation { showingMeaning = true }
            } label: {
                Label("Show Meaning", systemImage: "character.book.closed")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Grading

    private func gradingButtons(for item: QueueItem) -> some View {
        VStack(spacing: 6) {
            Text("How well did you know this?")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                gradeButton(.again, label: "Again", color: .red,    item: item)
                gradeButton(.hard,  label: "Hard",  color: .orange, item: item)
                gradeButton(.good,  label: "Good",  color: .green,  item: item)
                gradeButton(.easy,  label: "Easy",  color: .blue,   item: item)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func gradeButton(_ g: SRSGrade, label: String, color: Color, item: QueueItem) -> some View {
        Button {
            applyGrade(g, for: item)
        } label: {
            VStack(spacing: 3) {
                Text(label).font(.caption.bold())
                Text(item.card.previewInterval(for: g)).font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.35), lineWidth: 1))
        }
    }

    private func applyGrade(_ g: SRSGrade, for item: QueueItem) {
        store.gradeSRSCard(id: item.card.id, grade: g)
        reviewedCount += 1
        if g == .again, let updated = store.srsCards.first(where: { $0.id == item.card.id }) {
            queue.append(QueueItem(card: updated, question: item.question))
        }
        showingAnswer  = false
        showingMeaning = false
        currentIndex += 1
    }
}
