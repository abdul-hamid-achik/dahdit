import DahditCore
import SwiftUI

public struct WaveformVisualizer: View {
    private let symbols: [MorseSymbol]

    public init(symbols: [MorseSymbol]) {
        self.symbols = symbols
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 7) {
            if symbols.isEmpty {
                ForEach(0..<10, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.16 : 0.09))
                        .frame(width: index.isMultiple(of: 3) ? 24 : 9, height: index.isMultiple(of: 3) ? 16 : 8)
                }
            } else {
                ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                    Capsule()
                        .fill(color(for: symbol))
                        .frame(width: width(for: symbol), height: height(for: symbol))
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityLabel("Morse waveform preview")
    }

    private func width(for symbol: MorseSymbol) -> CGFloat {
        switch symbol {
        case .dit: 10
        case .dah: 32
        case .charGap: 12
        case .wordGap: 24
        }
    }

    private func height(for symbol: MorseSymbol) -> CGFloat {
        switch symbol {
        case .dit, .dah: 18
        case .charGap, .wordGap: 4
        }
    }

    private func color(for symbol: MorseSymbol) -> Color {
        switch symbol {
        case .dit, .dah: Color.dahdit.primary
        case .charGap: Color.white.opacity(0.26)
        case .wordGap: Color.dahdit.accent.opacity(0.60)
        }
    }
}
