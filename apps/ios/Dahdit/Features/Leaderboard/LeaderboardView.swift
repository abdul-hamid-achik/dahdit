import DahditGraphQL
import DahditUI
import SwiftUI

struct LeaderboardView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var state: LoadState = .idle

    var body: some View {
        ZStack {
            GameBackground()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            RadioLoadingView("Opening weekly net")
        case .failed(let message):
            VStack {
                RadioStateView("Could not load leagues", detail: message, systemImage: "wifi.exclamationmark")
            }
            .padding(.horizontal, 22)
        case .loaded(let snapshot):
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(
                        eyebrow: "Weekly net",
                        title: "Leagues",
                        subtitle: "Ranked by copied XP."
                    ) {
                        HUDChip("Top \(snapshot.entries.count)", systemImage: "trophy.fill", tint: Color.dahdit.accent)
                    }

                    if snapshot.entries.isEmpty {
                        RadioStateView(
                            "No stations yet",
                            detail: "Complete a lesson to put your callsign on the board.",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(snapshot.entries) { entry in
                                leaderboardRow(entry, isCurrentUser: entry.userId == snapshot.currentUserId)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 110)
            }
        }
    }

    private func leaderboardRow(_ entry: LeaderboardEntry, isCurrentUser: Bool) -> some View {
        HStack(spacing: 14) {
            Text("#\(entry.rank)")
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(entry.rank <= 3 ? Color.dahdit.accent : Color.white.opacity(0.54))
                .frame(width: 48, alignment: .leading)

            Circle()
                .fill(isCurrentUser ? Color.dahdit.primary : Color.white.opacity(0.10))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: isCurrentUser ? "person.fill" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.username)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.dahdit.cream)
                Text(isCurrentUser ? "You" : "\(entry.streakDays)-day streak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.48))
            }

            Spacer()

            Text("\(entry.xpTotal) XP")
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .foregroundStyle(Color.dahdit.accent)
        }
        .padding(16)
        .background(isCurrentUser ? Color.dahdit.panelRaised : Color.dahdit.panel, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(isCurrentUser ? Color.dahdit.primary.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    private func load() async {
        state = .loading
        do {
            let api = environment.api
            let user = try await api.me()
            let entries = try await api.leaderboard(limit: 50)
            state = .loaded(
                LeaderboardSnapshot(
                    currentUserId: user?.id,
                    entries: entries
                )
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private struct LeaderboardSnapshot: Equatable {
        let currentUserId: String?
        let entries: [LeaderboardEntry]
    }

    private enum LoadState: Equatable {
        case idle
        case loading
        case loaded(LeaderboardSnapshot)
        case failed(String)
    }
}
