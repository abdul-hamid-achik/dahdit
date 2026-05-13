import DahditAudio
import DahditCore
import DahditGraphQL
import DahditUI
import SwiftData
import SwiftUI

@main
struct DahditApp: App {
    @State private var environment = AppEnvironment.live

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
        .modelContainer(for: LessonAttemptDraft.self)
    }
}

private struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var isSignedIn: Bool?

    var body: some View {
        Group {
            if isSignedIn == true {
                AppTabs {
                    isSignedIn = false
                }
            } else if isSignedIn == false {
                OnboardingView {
                    isSignedIn = true
                }
            } else {
                ZStack {
                    GameBackground()
                    RadioLoadingView()
                }
            }
        }
        .task {
            if isSignedIn == nil {
                isSignedIn = await restoreSession()
            }
        }
    }

    private func restoreSession() async -> Bool {
        if ProcessInfo.processInfo.arguments.contains("--reset-auth") {
            await environment.tokenStore.clear()
            return false
        }

        guard await environment.tokenStore.access() != nil else {
            return false
        }

        do {
            if try await environment.api.me() != nil {
                return true
            }
        } catch let error as DahditAPIError where error.isAuthenticationFailure {
            if await refreshSession() {
                return true
            }
        } catch {
            // Keep the local session during transient API/network failures. Feature screens can show
            // their own loading errors, but a valid-looking token should not be destroyed offline.
            return true
        }

        await environment.tokenStore.clear()
        return false
    }

    private func refreshSession() async -> Bool {
        await environment.tokenRefresher.refresh()
    }
}

private struct AppTabs: View {
    @Environment(AppEnvironment.self) private var environment
    let onSignedOut: @MainActor () -> Void

    var body: some View {
        TabView {
            NavigationStack {
                SkillTreeView(viewModel: SkillTreeViewModel(api: environment.api))
            }
            .tabItem { Label("Home", systemImage: "map.fill") }

            NavigationStack {
                PracticeView()
            }
            .tabItem { Label("Practice", systemImage: "repeat.circle.fill") }

            NavigationStack {
                LeaderboardView()
            }
            .tabItem { Label("Leagues", systemImage: "trophy.fill") }

            NavigationStack {
                ProfileView(onSignedOut: onSignedOut)
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(Color.dahdit.primary)
        .toolbarBackground(Color.dahdit.background.opacity(0.94), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
