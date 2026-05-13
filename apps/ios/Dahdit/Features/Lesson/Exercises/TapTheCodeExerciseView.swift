import DahditCore
import DahditUI
import SwiftUI

struct TapTheCodeExerciseView: View {
    let payload: TapTheCodePayload
    let onSubmit: ([MorseSymbol]) -> Void
    @State private var symbols: [MorseSymbol] = []
    @State private var keyDownAt: Date?
    private let timing = MorseTiming(wpm: 15)

    var body: some View {
        ExerciseCard(
            eyebrow: "Send",
            title: "Key \(payload.prompt.character)",
            subtitle: "Press the key or use the manual paddle controls.",
            systemImage: "dot.radiowaves.left.and.right"
        ) {
            WaveformVisualizer(symbols: symbols)

            TapKeyView { isDown, date in
                if isDown {
                    keyDownAt = date
                } else if let keyDownAt {
                    let durationMs = date.timeIntervalSince(keyDownAt) * 1000
                    symbols.append(SendTimingClassifier.classifyPress(durationMs: durationMs, timing: timing))
                    self.keyDownAt = nil
                }
            }

            HStack(spacing: 10) {
                Button {
                    symbols.append(.dit)
                } label: {
                    Label("Dit", systemImage: "circle.fill")
                }
                .buttonStyle(SecondaryLessonButtonStyle())
                .accessibilityIdentifier("exercise.tap.dit")

                Button {
                    symbols.append(.dah)
                } label: {
                    Label("Dah", systemImage: "minus")
                }
                .buttonStyle(SecondaryLessonButtonStyle())
                .accessibilityIdentifier("exercise.tap.dah")
            }

            HStack(spacing: 10) {
                Button {
                    if !symbols.isEmpty { symbols.removeLast() }
                } label: {
                    Label("Delete", systemImage: "delete.left")
                }
                .buttonStyle(SecondaryLessonButtonStyle())
                .disabled(symbols.isEmpty)
                .accessibilityIdentifier("exercise.tap.delete")

                Button {
                    symbols.removeAll()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .buttonStyle(SecondaryLessonButtonStyle())
                .disabled(symbols.isEmpty)
                .accessibilityIdentifier("exercise.tap.clear")
            }

            Button {
                onSubmit(symbols)
            } label: {
                Label("Send answer", systemImage: "paperplane.fill")
            }
            .buttonStyle(PrimaryLessonButtonStyle())
            .disabled(symbols.isEmpty)
            .accessibilityIdentifier("exercise.tap.submit")
        }
    }
}
