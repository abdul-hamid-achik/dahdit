import DahditUI
import SwiftUI

struct OnboardingView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signup = "Sign up"
        case login = "Log in"

        var id: String { rawValue }
    }

    @Environment(AppEnvironment.self) private var environment
    let onAuthenticated: () -> Void
    @State private var mode: Mode = .signup
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")

    var body: some View {
        NavigationStack {
            ZStack {
                GameBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Dahdit")
                                        .font(.system(size: 52, weight: .black, design: .rounded))
                                        .foregroundStyle(Color.dahdit.cream)
                                    Text("-.. .- .... -.. .. -")
                                        .font(.system(.headline, design: .monospaced, weight: .bold))
                                        .foregroundStyle(Color.dahdit.accent)
                                }
                                Spacer()
                                SignalMeter(level: 4)
                            }

                            Text("Train your ear, then key it back.")
                                .font(.system(.title2, design: .rounded, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.78))
                        }
                        .padding(.top, 42)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                HUDChip("15 WPM", systemImage: "speedometer", tint: Color.dahdit.accent)
                                HUDChip("5 hearts", systemImage: "heart.fill", tint: Color.dahdit.danger)
                            }

                            Text("Short audio drills, send practice, and daily review loops built around real International Morse.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.66))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        }

                        VStack(spacing: 18) {
                            Picker("Mode", selection: $mode) {
                                ForEach(Mode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            VStack(spacing: 12) {
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .submitLabel(.next)
                                    .dahditField()
                                    .accessibilityIdentifier("auth.email")

                                if mode == .signup {
                                    TextField("Username", text: $username)
                                        .textContentType(.username)
                                        .textInputAutocapitalization(.never)
                                        .submitLabel(.next)
                                        .dahditField()
                                        .accessibilityIdentifier("auth.username")
                                }

                                SecureField("Password", text: $password)
                                    .textContentType(isUITesting ? nil : (mode == .signup ? .newPassword : .password))
                                    .submitLabel(.go)
                                    .dahditField()
                                    .accessibilityIdentifier("auth.password")
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.dahdit.danger)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                Task { await authenticate() }
                            } label: {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .tint(canSubmit ? .white : Color.dahdit.background)
                                    } else {
                                        Image(systemName: mode == .signup ? "person.badge.plus" : "arrow.right.circle.fill")
                                        Text(mode.rawValue)
                                    }
                                }
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(canSubmit ? Color.white : Color.dahdit.background.opacity(0.42))
                            .background(canSubmit ? Color.dahdit.primary : Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                            .disabled(!canSubmit || isSubmitting)
                            .accessibilityIdentifier("auth.submit")
                        }
                        .padding(18)
                        .background(Color.dahdit.cream, in: RoundedRectangle(cornerRadius: 28))
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && (mode == .login || !username.isEmpty)
    }

    private func authenticate() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let payload = switch mode {
            case .signup:
                try await environment.api.signup(
                    email: email,
                    username: username,
                    password: password,
                    tz: TimeZone.current.identifier
                )
            case .login:
                try await environment.api.login(email: email, password: password)
            }
            await environment.tokenStore.set(
                accessToken: payload.accessToken,
                refreshToken: payload.refreshToken
            )
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension View {
    func dahditField() -> some View {
        self
            .font(.system(.body, design: .rounded, weight: .semibold))
            .textInputAutocapitalization(.never)
            .foregroundStyle(Color.dahdit.background)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}
