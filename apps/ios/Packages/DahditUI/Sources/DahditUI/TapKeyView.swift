import DahditCore
import SwiftUI

public struct TapKeyView: View {
    private let onEvent: (Bool, Date) -> Void
    @State private var isPressed = false

    public init(onEvent: @escaping (Bool, Date) -> Void) {
        self.onEvent = onEvent
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(isPressed ? Color.dahdit.primary : Color.dahdit.panelRaised)
                .shadow(color: isPressed ? Color.dahdit.primary.opacity(0.45) : Color.black.opacity(0.22), radius: isPressed ? 20 : 12, y: 10)
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(isPressed ? 0.35 : 0.12), lineWidth: 1)
            VStack(spacing: 10) {
                Image(systemName: isPressed ? "waveform.path.ecg" : "largecircle.fill.circle")
                    .font(.system(size: 34, weight: .bold))
                Text(isPressed ? "KEY DOWN" : "PRESS KEY")
                    .font(.dahdit.mono)
            }
            .foregroundStyle(isPressed ? Color.white : Color.dahdit.cream)
        }
            .frame(minHeight: 156)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onEvent(true, Date())
                    }
                    .onEnded { _ in
                        isPressed = false
                        onEvent(false, Date())
                    }
            )
            .accessibilityLabel("Morse key")
    }
}
