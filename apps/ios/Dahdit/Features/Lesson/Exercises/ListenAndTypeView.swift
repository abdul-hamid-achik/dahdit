import DahditCore
import DahditUI
import SwiftUI

struct ListenAndTypeView: View {
    let payload: ListenAndTypePayload
    let isPlaying: Bool
    let playbackError: String?
    let onPlay: () -> Void
    let onSubmit: (String) -> Void
    @State private var answer = ""

    var body: some View {
        ExerciseCard(
            eyebrow: "Receive",
            title: "Copy the signal",
            subtitle: "\(Int(payload.prompt.timing.wpm)) WPM · \(Int(payload.prompt.timing.toneHz)) Hz tone",
            systemImage: "speaker.wave.2.fill"
        ) {
            WaveformVisualizer(symbols: [])

            Button {
                onPlay()
            } label: {
                Label(isPlaying ? "Playing signal" : "Play signal", systemImage: isPlaying ? "speaker.wave.2.fill" : "play.fill")
            }
            .buttonStyle(PrimaryLessonButtonStyle())
            .disabled(isPlaying)
            .accessibilityIdentifier("exercise.listen.play")

            if let playbackError {
                Label(playbackError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dahdit.danger)
                    .multilineTextAlignment(.center)
            }

            TextField("Answer", text: $answer)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .lessonTextField()
                .accessibilityIdentifier("exercise.listen.answer")

            Button {
                onSubmit(answer)
            } label: {
                Label("Check copy", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(SecondaryLessonButtonStyle())
            .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("exercise.listen.submit")
        }
    }
}
