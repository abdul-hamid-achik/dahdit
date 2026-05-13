import DahditCore
import DahditUI
import SwiftUI

struct MultipleChoiceView: View {
    let payload: MatchCharacterToCodePayload
    let onSubmit: (Int) -> Void

    var body: some View {
        ExerciseCard(
            eyebrow: "Decode",
            title: "Find \(payload.prompt.character)",
            subtitle: "Pick the signal pattern that matches this character.",
            systemImage: "rectangle.grid.2x2.fill"
        ) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(payload.prompt.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        onSubmit(index)
                    } label: {
                        Text(option)
                            .font(.system(size: 30, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.dahdit.cream)
                            .frame(maxWidth: .infinity, minHeight: 88)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("exercise.choice.\(index)")
                }
            }
        }
    }
}
