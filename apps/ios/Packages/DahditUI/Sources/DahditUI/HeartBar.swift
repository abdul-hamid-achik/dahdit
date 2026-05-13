import SwiftUI

public struct HeartBar: View {
    private let hearts: Int
    private let maxHearts: Int

    public init(hearts: Int, maxHearts: Int = 5) {
        self.hearts = hearts
        self.maxHearts = maxHearts
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<maxHearts, id: \.self) { index in
                Circle()
                    .fill(index < hearts ? Color.dahdit.danger : Color.white.opacity(0.12))
                    .frame(width: 10, height: 10)
                    .overlay {
                        if index < hearts {
                            Circle()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        }
                    }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.10), in: Capsule())
        .accessibilityLabel("\(hearts) hearts remaining")
    }
}
