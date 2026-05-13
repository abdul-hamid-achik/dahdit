import SwiftUI

public struct XPHud: View {
    private let xp: Int
    private let streak: Int

    public init(xp: Int, streak: Int) {
        self.xp = xp
        self.streak = streak
    }

    public var body: some View {
        HStack(spacing: 10) {
            HUDChip("\(xp)", systemImage: "bolt.fill", tint: Color.dahdit.accent)
            HUDChip("\(streak)", systemImage: "flame.fill", tint: Color.dahdit.danger)
        }
        .accessibilityElement(children: .combine)
    }
}
