import DahditCore
import DahditUI
import SwiftUI

struct TapTheCodeExerciseView: View {
    let payload: TapTheCodePayload
    let timing: MorseTiming
    let onKeyedSymbol: (MorseSymbol) -> Void
    let onSubmit: ([MorseSymbol]) -> Void
    @State private var symbols: [MorseSymbol] = []
    @State private var keyDownAt: Date?

    init(
        payload: TapTheCodePayload,
        timing: MorseTiming = MorseTiming(wpm: 15),
        onKeyedSymbol: @escaping (MorseSymbol) -> Void = { _ in },
        onSubmit: @escaping ([MorseSymbol]) -> Void
    ) {
        self.payload = payload
        self.timing = timing
        self.onKeyedSymbol = onKeyedSymbol
        self.onSubmit = onSubmit
    }

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
                    let symbol = SendTimingClassifier.classifyPress(durationMs: durationMs, timing: timing)
                    symbols.append(symbol)
                    onKeyedSymbol(symbol)
                    self.keyDownAt = nil
                }
            }

            HStack(spacing: 10) {
                Button {
                    symbols.append(.dit)
                    onKeyedSymbol(.dit)
                } label: {
                    Label("Dit", systemImage: "circle.fill")
                }
                .buttonStyle(SecondaryLessonButtonStyle())
                .accessibilityIdentifier("exercise.tap.dit")

                Button {
                    symbols.append(.dah)
                    onKeyedSymbol(.dah)
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
