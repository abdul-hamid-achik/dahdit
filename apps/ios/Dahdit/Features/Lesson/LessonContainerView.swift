import DahditAudio
import DahditCore
import DahditGraphQL
import DahditUI
import SwiftData
import SwiftUI

struct LessonContainerView: View {
    let lessonId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LessonViewModel

    init(lessonId: String, api: DahditAPI, audio: MorseAudioPlayer) {
        self.lessonId = lessonId
        _viewModel = State(initialValue: LessonViewModel(lessonId: lessonId, api: api, audio: audio))
    }

    var body: some View {
        ZStack {
            GameBackground()
            VStack(spacing: 18) {
                lessonHeader
                ScrollView {
                    VStack(spacing: 18) {
                        switch viewModel.state {
                        case .loading:
                            RadioLoadingView("Loading lesson")
                                .frame(minHeight: 320)
                        case .exercise(let exercise):
                            exerciseView(exercise)
                        case .complete(let result):
                            completionView(result)
                        case .pendingSync:
                            pendingSyncView
                        case .failed(let message):
                            RadioStateView("Could not load lesson", detail: message, systemImage: "wifi.exclamationmark")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.start(modelContext: modelContext) }
    }

    private var lessonHeader: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.bold))
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.dahdit.cream)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Training run")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.dahdit.accent)
                    Text(viewModel.progressLabel)
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(Color.dahdit.cream)
                }

                Spacer()
                HeartBar(hearts: viewModel.hearts)
            }

            ProgressView(value: viewModel.progressFraction)
                .tint(Color.dahdit.accent)
                .background(Color.white.opacity(0.10), in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private func completionView(_ result: LessonResult?) -> some View {
        VStack(spacing: 18) {
            SignalMeter(level: 5)
                .padding(.top, 10)
            ResultBanner(
                title: "Signal copied",
                detail: result.map { "\($0.xpEarned) XP earned. Streak: \($0.newStreak)." }
                    ?? "No exercises were available."
            )
            Button {
                dismiss()
            } label: {
                Label("Back to map", systemImage: "map.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white)
            .background(Color.dahdit.primary, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityIdentifier("lesson.complete.back")
        }
    }

    private var pendingSyncView: some View {
        VStack(spacing: 18) {
            SignalMeter(level: 4)
                .padding(.top, 10)
            ResultBanner(
                title: "Saved for sync",
                detail: "Your lesson is stored on this device. Dahdit will retry progress sync when the API is reachable."
            )
            Button {
                dismiss()
            } label: {
                Label("Back to map", systemImage: "map.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white)
            .background(Color.dahdit.primary, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityIdentifier("lesson.pending.back")
        }
    }

    @ViewBuilder
    private func exerciseView(_ exercise: Exercise) -> some View {
        switch exercise.payload {
        case .listenAndType(let payload):
            ListenAndTypeView(
                payload: payload,
                isPlaying: viewModel.isPlayingPrompt,
                playbackError: viewModel.playbackError,
                onPlay: { Task { await viewModel.playPrompt(for: exercise) } }
            ) { answer in
                Task { await viewModel.submit(answer: .string(answer), modelContext: modelContext) }
            }
        case .tapTheCode(let payload):
            TapTheCodeExerciseView(payload: payload) { symbols in
                Task { await viewModel.submit(answer: .array(symbols.map { .string($0.rawValue) }), modelContext: modelContext) }
            }
        case .matchCharacterToCode(let payload):
            MultipleChoiceView(payload: payload) { index in
                Task { await viewModel.submit(answer: .int(index), modelContext: modelContext) }
            }
        case .translateToMorse(let payload):
            TranslateToMorseView(payload: payload) { symbols in
                Task { await viewModel.submit(answer: .array(symbols.map { .string($0.rawValue) }), modelContext: modelContext) }
            }
        case .copyAtSpeed(let payload):
            CopyAtSpeedView(
                payload: payload,
                isPlaying: viewModel.isPlayingPrompt,
                playbackError: viewModel.playbackError,
                onPlay: { Task { await viewModel.playPrompt(for: exercise) } }
            ) { answer in
                Task { await viewModel.submit(answer: .string(answer), modelContext: modelContext) }
            }
        }
    }
}
