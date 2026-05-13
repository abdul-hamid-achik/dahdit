import DahditUI
import SwiftUI

struct ResultBanner: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.dahdit.success)
            Text(title)
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundStyle(Color.dahdit.cream)
            Text(detail)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.66))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}
