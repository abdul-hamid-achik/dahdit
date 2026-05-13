import SwiftUI

public struct LessonBubble: View {
    private let title: String
    private let isUnlocked: Bool
    private let isCompleted: Bool

    public init(
        title: String,
        isUnlocked: Bool,
        isCompleted: Bool
    ) {
        self.title = title
        self.isUnlocked = isUnlocked
        self.isCompleted = isCompleted
    }

    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.dahdit.primary : Color.white.opacity(0.10))
                    .frame(width: 64, height: 64)
                Image(systemName: isCompleted ? "checkmark.seal.fill" : "dot.radiowaves.left.and.right")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(isUnlocked ? Color.white : Color.white.opacity(0.34))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(isUnlocked ? Color.white : Color.white.opacity(0.45))
                    .lineLimit(2)
                Text(isCompleted ? "Logged" : isUnlocked ? "Ready to train" : "Locked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isUnlocked ? Color.dahdit.accent : Color.white.opacity(0.35))
            }

            Spacer()

            Image(systemName: isUnlocked ? "chevron.right" : "lock.fill")
                .font(.headline)
                .foregroundStyle(isUnlocked ? Color.white.opacity(0.70) : Color.white.opacity(0.35))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .background(isUnlocked ? Color.dahdit.panelRaised : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(isUnlocked ? Color.dahdit.primary.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: isUnlocked ? Color.dahdit.primary.opacity(0.20) : .clear, radius: 16, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(isUnlocked ? "Starts lesson" : "Locked")
    }
}
