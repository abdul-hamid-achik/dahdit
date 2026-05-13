import SwiftUI

public struct ScreenHeader<Trailing: View>: View {
    private let eyebrow: String?
    private let title: String
    private let subtitle: String?
    private let trailing: Trailing

    public init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .foregroundStyle(Color.dahdit.accent)
                }
                Text(title)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dahdit.cream)
                    .minimumScaleFactor(0.78)
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)
            trailing
        }
    }
}

public struct GamePanel<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dahdit.panel, in: RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.20), radius: 14, y: 10)
    }
}

public struct RadioStateView: View {
    private let title: String
    private let detail: String
    private let systemImage: String

    public init(_ title: String, detail: String, systemImage: String) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }

    public var body: some View {
        GamePanel {
            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.dahdit.accent)
                    .frame(width: 74, height: 74)
                    .background(Color.white.opacity(0.08), in: Circle())

                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(Color.dahdit.cream)
                    .multilineTextAlignment(.center)

                Text(detail)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

public struct RadioLoadingView: View {
    private let title: String

    public init(_ title: String = "Tuning signal") {
        self.title = title
    }

    public var body: some View {
        VStack(spacing: 16) {
            SignalMeter(level: 3)
            ProgressView()
                .tint(Color.dahdit.accent)
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.dahdit.cream)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
