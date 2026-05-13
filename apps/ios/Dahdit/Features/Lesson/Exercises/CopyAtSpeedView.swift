import DahditCore
import DahditUI
import SwiftUI

struct CopyAtSpeedView: View {
    let payload: CopyAtSpeedPayload
    let isPlaying: Bool
    let playbackError: String?
    let onPlay: () -> Void
    let onSubmit: (String) -> Void
    @State private var answer = ""

    var body: some View {
        ExerciseCard(
            eyebrow: "Copy",
            title: "\(Int(payload.prompt.timing.wpm)) WPM stream",
            subtitle: "Listen once, then type what you copied.",
            systemImage: "waveform.path"
        ) {
            WaveformVisualizer(symbols: [])

            Button {
                onPlay()
            } label: {
                Label(isPlaying ? "Playing stream" : "Play stream", systemImage: isPlaying ? "speaker.wave.2.fill" : "play.fill")
            }
            .buttonStyle(PrimaryLessonButtonStyle())
            .disabled(isPlaying)
            .accessibilityIdentifier("exercise.copy.play")

            if let playbackError {
                Label(playbackError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dahdit.danger)
                    .multilineTextAlignment(.center)
            }

            TextField("What did you hear?", text: $answer)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .lessonTextField()
                .accessibilityIdentifier("exercise.copy.answer")

            Button {
                onSubmit(answer)
            } label: {
                Label("Check copy", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(SecondaryLessonButtonStyle())
            .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("exercise.copy.submit")
        }
    }
}
