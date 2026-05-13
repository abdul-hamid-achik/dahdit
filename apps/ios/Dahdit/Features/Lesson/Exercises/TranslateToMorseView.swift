import DahditCore
import DahditUI
import SwiftUI

struct TranslateToMorseView: View {
    let payload: TranslateToMorsePayload
    let onSubmit: ([MorseSymbol]) -> Void
    @State private var symbols: [MorseSymbol] = []

    var body: some View {
        ExerciseCard(
            eyebrow: "Transmit",
            title: "Send \(payload.prompt.text)",
            subtitle: "Build the full message with character gaps between letters.",
            systemImage: "antenna.radiowaves.left.and.right"
        ) {
            WaveformVisualizer(symbols: symbols)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Button {
                        symbols.append(.dit)
                    } label: {
                        Label("Dit", systemImage: "circle.fill")
                    }
                    .accessibilityIdentifier("exercise.translate.dit")
                    Button {
                        symbols.append(.dah)
                    } label: {
                        Label("Dah", systemImage: "minus")
                    }
                    .accessibilityIdentifier("exercise.translate.dah")
                }
                GridRow {
                    Button {
                        symbols.append(.charGap)
                    } label: {
                        Label("Letter", systemImage: "arrow.right")
                    }
                    .accessibilityIdentifier("exercise.translate.charGap")
                    Button {
                        symbols.append(.wordGap)
                    } label: {
                        Label("Word", systemImage: "arrow.right.to.line")
                    }
                    .accessibilityIdentifier("exercise.translate.wordGap")
                }
                GridRow {
                    Button {
                        if !symbols.isEmpty { symbols.removeLast() }
                    } label: {
                        Label("Delete", systemImage: "delete.left")
                    }
                    .accessibilityIdentifier("exercise.translate.delete")
                    Button {
                        symbols.removeAll()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .accessibilityIdentifier("exercise.translate.clear")
                }
            }
            .buttonStyle(SecondaryLessonButtonStyle())

            Button {
                onSubmit(symbols)
            } label: {
                Label("Transmit answer", systemImage: "paperplane.fill")
            }
            .buttonStyle(PrimaryLessonButtonStyle())
            .disabled(symbols.isEmpty)
            .accessibilityIdentifier("exercise.translate.submit")
        }
    }
}
