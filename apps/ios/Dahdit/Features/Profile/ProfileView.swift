import DahditGraphQL
import DahditUI
import SwiftUI

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var state: LoadState = .idle
    @State private var showingDeleteConfirmation = false
    @State private var actionError: String?

    private let onSignedOut: @MainActor () -> Void

    init(onSignedOut: @escaping @MainActor () -> Void = {}) {
        self.onSignedOut = onSignedOut
    }

    var body: some View {
        ZStack {
            GameBackground()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadIfNeeded() }
        .confirmationDialog(
            "Delete account?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This marks the local account for deletion and signs you out.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            RadioLoadingView("Reading station log")
        case .failed(let message):
            VStack {
                RadioStateView("Could not load profile", detail: message, systemImage: "wifi.exclamationmark")
            }
            .padding(.horizontal, 22)
        case .loaded(let user):
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(
                        eyebrow: "Station log",
                        title: "Profile",
                        subtitle: "Operator settings and account controls."
                    ) {
                        SignalMeter(level: signalLevel(for: user.stats))
                    }

                    if let actionError {
                        RadioStateView("Action failed", detail: actionError, systemImage: "exclamationmark.triangle.fill")
                    }

                    operatorCard(user)
                    audioPanel
                    accountPanel
                }
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 110)
            }
        }
    }

    private func operatorCard(_ user: APIUser) -> some View {
        GamePanel {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.dahdit.primary)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(initials(for: user.username))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(user.username)
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(Color.dahdit.cream)
                    Text(user.email)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.60))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(user.tz)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dahdit.accent)
                }

                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    HUDChip("\(user.stats?.xpTotal ?? 0) XP", systemImage: "bolt.fill", tint: Color.dahdit.accent)
                    HUDChip("\(user.stats?.streakDays ?? 0)d", systemImage: "flame.fill", tint: Color.dahdit.success)
                }
            }
        }
    }

    private var audioPanel: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 14) {
                panelTitle("Audio", systemImage: "speaker.wave.2.fill")
                settingRow("Tone", value: "700 Hz", systemImage: "waveform")
                settingRow("Default speed", value: "15 WPM", systemImage: "speedometer")
                settingRow("Haptics", value: "On", systemImage: "iphone.radiowaves.left.and.right")
            }
        }
    }

    private var accountPanel: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 14) {
                panelTitle("Account", systemImage: "person.crop.circle.fill")
                Button {
                    signOut()
                } label: {
                    actionRow("Sign out", systemImage: "rectangle.portrait.and.arrow.right", tint: Color.dahdit.cream)
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    actionRow("Delete account", systemImage: "trash.fill", tint: Color.dahdit.danger)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func panelTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(.headline, design: .rounded, weight: .black))
            .foregroundStyle(Color.dahdit.accent)
    }

    private func settingRow(_ title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color.dahdit.primary)
                .frame(width: 28)
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.dahdit.cream)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded, weight: .black))
                .foregroundStyle(Color.white.opacity(0.62))
        }
        .padding(.vertical, 4)
    }

    private func actionRow(_ title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 28)
            Text(title)
                .font(.system(.body, design: .rounded, weight: .bold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .opacity(0.58)
        }
        .foregroundStyle(tint)
        .padding(.vertical, 7)
    }

    private func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    private func load() async {
        state = .loading
        do {
            if let user = try await environment.api.me() {
                state = .loaded(user)
            } else {
                state = .failed("The current session is no longer valid.")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func signOut() {
        Task {
            await environment.tokenStore.clear()
            await MainActor.run {
                onSignedOut()
            }
        }
    }

    private func deleteAccount() async {
        actionError = nil
        do {
            _ = try await environment.api.deleteAccount()
            await environment.tokenStore.clear()
            await MainActor.run {
                onSignedOut()
            }
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func initials(for username: String) -> String {
        String(username.prefix(2)).uppercased()
    }

    private func signalLevel(for stats: APIUserStats?) -> Int {
        min(max((stats?.streakDays ?? 0) + 1, 1), 5)
    }

    private enum LoadState: Equatable {
        case idle
        case loading
        case loaded(APIUser)
        case failed(String)
    }
}
