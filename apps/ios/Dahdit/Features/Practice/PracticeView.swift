import DahditCore
import DahditGraphQL
import DahditUI
import SwiftData
import SwiftUI

struct PracticeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.modelContext) private var modelContext
    @Query private var audioSettings: [UserAudioSettings]
    @State private var mode: PracticeMode = .idle
    @State private var reviews: [DahditGraphQL.ReviewCard] = []
    @State private var currentIndex = 0
    @State private var answer = ""
    @State private var revealed = false
    @State private var wasCorrect = false
    @State private var selectedGrade: DahditCore.ReviewGrade?
    @State private var results: [DahditGraphQL.ReviewResult] = []
    @State private var startedAt = Date()
    @State private var completion: CompleteReviewsResult?
    @State private var errorMessage: String?
    @State private var isPlaying = false
    @State private var playbackError: String?

    var body: some View {
        ZStack {
            GameBackground()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            UserAudioSettings.current(in: modelContext)
            await loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .idle, .loading:
            RadioLoadingView("Checking review queue")
        case .failed:
            VStack {
                RadioStateView(
                    "Could not load reviews",
                    detail: errorMessage ?? "The review queue did not respond.",
                    systemImage: "wifi.exclamationmark"
                )
            }
            .padding(.horizontal, 22)
        case .list:
            reviewList
        case .reviewing:
            reviewSession
        case .saving:
            RadioLoadingView("Saving review grades")
        case .completed:
            completionView
        }
    }

    private var reviewList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(
                    eyebrow: "Daily copy",
                    title: "Practice",
                    subtitle: reviews.isEmpty
                        ? "Review due signals and keep the rhythm fresh."
                        : "Copy the cards that are due today."
                ) {
                    HUDChip("\(reviews.count) due", systemImage: "repeat.circle.fill", tint: Color.dahdit.success)
                }

                if reviews.isEmpty {
                    clearChannelPanel
                    RadioStateView(
                        "No reviews due",
                        detail: "Come back after your next lesson or tomorrow's rollover.",
                        systemImage: "checkmark.circle.fill"
                    )
                } else {
                    Button {
                        startSession()
                    } label: {
                        Label("Start review", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryLessonButtonStyle())
                    .accessibilityIdentifier("practice.start")

                    VStack(spacing: 12) {
                        ForEach(reviews) { review in
                            reviewRow(review)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 110)
        }
    }

    private var reviewSession: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(
                    eyebrow: "Daily review",
                    title: "Copy card",
                    subtitle: "Listen, type what you copied, then grade the recall."
                ) {
                    HUDChip("\(currentIndex + 1)/\(reviews.count)", systemImage: "rectangle.stack.fill", tint: Color.dahdit.accent)
                }

                ExerciseCard(
                    eyebrow: reviewKindTitle(for: currentReview.cardKey),
                    title: revealed ? reviewTitle(for: currentReview.cardKey) : "What did you copy?",
                    subtitle: "\(Int(audioSettingsSnapshot.defaultWpm)) WPM review signal",
                    systemImage: "repeat.circle.fill"
                ) {
                    WaveformVisualizer(symbols: currentSymbols)

                    Button {
                        playCurrent()
                    } label: {
                        Label(isPlaying ? "Playing signal" : "Play signal", systemImage: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                    }
                    .buttonStyle(PrimaryLessonButtonStyle())
                    .disabled(isPlaying)
                    .accessibilityIdentifier("practice.play")

                    if let playbackError {
                        Label(playbackError, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dahdit.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    TextField("Copied text", text: $answer)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .lessonTextField()
                        .disabled(revealed)
                        .accessibilityIdentifier("practice.answer")

                    if revealed {
                        reviewResultPanel
                        gradePicker

                        Button {
                            nextOrSave()
                        } label: {
                            Label(currentIndex + 1 == reviews.count ? "Finish review" : "Next card", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(PrimaryLessonButtonStyle())
                        .accessibilityIdentifier(currentIndex + 1 == reviews.count ? "practice.finish" : "practice.next")
                    } else {
                        Button {
                            checkAnswer()
                        } label: {
                            Label("Check copy", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(SecondaryLessonButtonStyle())
                        .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("practice.check")
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 110)
        }
    }

    private var completionView: some View {
        VStack {
            RadioStateView(
                "Review saved",
                detail: "Copied \(completion?.completedCount ?? results.count) cards. \(completion?.remainingDueCount ?? 0) cards remain due.",
                systemImage: "checkmark.seal.fill"
            )

            Button {
                Task { await load() }
            } label: {
                Label("Back to practice", systemImage: "repeat.circle.fill")
            }
            .buttonStyle(PrimaryLessonButtonStyle())
            .padding(.horizontal, 22)
            .accessibilityIdentifier("practice.back")
        }
    }

    private var clearChannelPanel: some View {
        GamePanel {
            HStack(spacing: 16) {
                SignalMeter(level: 5)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Clear channel")
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(Color.dahdit.cream)
                    Text("All scheduled cards are copied for today.")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.62))
                }
                Spacer()
            }
        }
    }

    private var reviewResultPanel: some View {
        HStack(spacing: 12) {
            Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(wasCorrect ? Color.dahdit.success : Color.dahdit.danger)

            VStack(alignment: .leading, spacing: 4) {
                Text(wasCorrect ? "Copied correctly" : "Missed copy")
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(Color.dahdit.cream)
                Text("Answer: \(targetAnswer(for: currentReview.cardKey))")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private var gradePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Grade recall")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.dahdit.accent)

            HStack(spacing: 8) {
                ForEach(DahditCore.ReviewGrade.allCases, id: \.self) { grade in
                    Button {
                        selectedGrade = grade
                    } label: {
                        Text(gradeLabel(grade))
                            .font(.caption.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedGrade == grade ? gradeTint(grade).opacity(0.95) : Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(selectedGrade == grade ? Color.white : Color.dahdit.cream)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("practice.grade.\(grade.rawValue)")
                }
            }
        }
    }

    private func reviewRow(_ review: DahditGraphQL.ReviewCard) -> some View {
        HStack(spacing: 14) {
            Image(systemName: reviewIcon(for: review.cardKey))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.dahdit.accent)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(reviewTitle(for: review.cardKey))
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(Color.dahdit.cream)
                Text("Due \(review.dueOn) - interval \(review.intervalDays)d - ease \(review.ease.formatted(.number.precision(.fractionLength(2))))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.56))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.dahdit.panel, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var currentReview: DahditGraphQL.ReviewCard {
        reviews[min(currentIndex, max(0, reviews.count - 1))]
    }

    private var currentSymbols: [MorseSymbol] {
        InternationalMorseCodec.shared.encode(targetAnswer(for: currentReview.cardKey))
    }

    private func loadIfNeeded() async {
        guard mode == .idle else { return }
        await load()
    }

    private func load() async {
        mode = .loading
        do {
            reviews = try await environment.api.dueReviews(limit: 30)
            resetSession()
            mode = .list
        } catch {
            errorMessage = error.localizedDescription
            mode = .failed
        }
    }

    private func startSession() {
        resetSession()
        startedAt = Date()
        mode = .reviewing
    }

    private func resetSession() {
        currentIndex = 0
        answer = ""
        revealed = false
        wasCorrect = false
        selectedGrade = nil
        results = []
        completion = nil
        playbackError = nil
        isPlaying = false
    }

    private func checkAnswer() {
        let expected = normalized(targetAnswer(for: currentReview.cardKey))
        wasCorrect = normalized(answer) == expected
        selectedGrade = defaultGrade(wasCorrect: wasCorrect, elapsed: Date().timeIntervalSince(startedAt))
        revealed = true
    }

    private func nextOrSave() {
        results.append(
            DahditGraphQL.ReviewResult(
                cardKey: currentReview.cardKey,
                grade: selectedGrade ?? .again
            )
        )

        if currentIndex + 1 < reviews.count {
            currentIndex += 1
            answer = ""
            revealed = false
            wasCorrect = false
            selectedGrade = nil
            playbackError = nil
            startedAt = Date()
        } else {
            Task { await saveResults() }
        }
    }

    private func saveResults() async {
        mode = .saving
        do {
            completion = try await environment.api.completeReviews(results)
            mode = .completed
        } catch {
            errorMessage = error.localizedDescription
            mode = .failed
        }
    }

    private func playCurrent() {
        isPlaying = true
        playbackError = nil
        let audio = environment.audio
        let symbols = currentSymbols
        let timing = audioSettingsSnapshot.practiceTiming
        Task {
            do {
                try await audio.play(symbols: symbols, timing: timing)
            } catch {
                playbackError = error.localizedDescription
            }
            isPlaying = false
        }
    }

    private var audioSettingsSnapshot: AudioSettingsSnapshot {
        audioSettings.first?.snapshot ?? .default
    }

    private func defaultGrade(wasCorrect: Bool, elapsed: TimeInterval) -> DahditCore.ReviewGrade {
        if !wasCorrect { return .again }
        if elapsed < 4 { return .easy }
        return .good
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func targetAnswer(for cardKey: String) -> String {
        let parts = cardKey.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return cardKey.uppercased() }
        if parts[0] == "prosign" {
            return parts[1].replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").uppercased()
        }
        return parts[1].uppercased()
    }

    private func reviewTitle(for cardKey: String) -> String {
        targetAnswer(for: cardKey)
    }

    private func reviewKindTitle(for cardKey: String) -> String {
        if cardKey.hasPrefix("word:") { return "Word review" }
        if cardKey.hasPrefix("prosign:") { return "Prosign review" }
        return "Character review"
    }

    private func reviewIcon(for cardKey: String) -> String {
        if cardKey.hasPrefix("word:") { return "textformat.abc" }
        if cardKey.hasPrefix("prosign:") { return "signature" }
        return "waveform"
    }

    private func gradeLabel(_ grade: DahditCore.ReviewGrade) -> String {
        switch grade {
        case .again: "Again"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
    }

    private func gradeTint(_ grade: DahditCore.ReviewGrade) -> Color {
        switch grade {
        case .again: Color.dahdit.danger
        case .hard: Color.dahdit.accent
        case .good: Color.dahdit.primary
        case .easy: Color.dahdit.success
        }
    }

    private enum PracticeMode: Equatable {
        case idle
        case loading
        case list
        case reviewing
        case saving
        case completed
        case failed
    }
}
