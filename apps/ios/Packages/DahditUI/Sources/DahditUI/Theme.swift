import SwiftUI

public extension Color {
    enum dahdit {
        public static let background = Color(red: 0.05, green: 0.07, blue: 0.10)
        public static let panel = Color(red: 0.10, green: 0.13, blue: 0.18)
        public static let panelRaised = Color(red: 0.14, green: 0.18, blue: 0.24)
        public static let primary = Color(red: 0.06, green: 0.55, blue: 0.82)
        public static let accent = Color(red: 0.98, green: 0.68, blue: 0.22)
        public static let success = Color(red: 0.08, green: 0.55, blue: 0.35)
        public static let danger = Color(red: 0.82, green: 0.22, blue: 0.20)
        public static let cream = Color(red: 0.95, green: 0.96, blue: 0.93)
        public static let ink = Color.primary
        public static let muted = Color.secondary
    }
}

public extension Font {
    enum dahdit {
        public static let title = Font.system(.largeTitle, design: .rounded, weight: .bold)
        public static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
        public static let body = Font.system(.body, design: .rounded)
        public static let mono = Font.system(.title3, design: .monospaced, weight: .semibold)
    }
}

public struct GameBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.dahdit.background
            LinearGradient(
                colors: [
                    Color.dahdit.primary.opacity(0.28),
                    Color.clear,
                    Color.dahdit.accent.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

public struct SignalMeter: View {
    private let level: Int
    private let maxLevel: Int

    public init(level: Int = 4, maxLevel: Int = 5) {
        self.level = level
        self.maxLevel = maxLevel
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<maxLevel, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index < level ? Color.dahdit.accent : Color.white.opacity(0.16))
                    .frame(width: 8, height: CGFloat(10 + index * 5))
            }
        }
        .accessibilityLabel("Signal level \(level) of \(maxLevel)")
    }
}

public struct HUDChip: View {
    private let title: String
    private let systemImage: String
    private let tint: Color

    public init(_ title: String, systemImage: String, tint: Color = Color.dahdit.primary) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.10), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
    }
}
