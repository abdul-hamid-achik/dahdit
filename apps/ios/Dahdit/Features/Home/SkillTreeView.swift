import DahditUI
import SwiftUI

struct SkillTreeView: View {
    @Environment(AppEnvironment.self) private var environment
    @State var viewModel: SkillTreeViewModel

    var body: some View {
        ZStack {
            GameBackground()
            switch viewModel.state {
            case .idle, .loading:
                RadioLoadingView()
            case .failed(let message):
                VStack {
                    RadioStateView("Could not load", detail: message, systemImage: "wifi.exclamationmark")
                }
                .padding(.horizontal, 22)
            case .loaded(let snapshot):
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header(xp: snapshot.xpTotal, streak: snapshot.streakDays)
                        ForEach(Array(snapshot.skills.enumerated()), id: \.element.id) { skillIndex, skill in
                            skillSection(skill, index: skillIndex)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 28)
                    .padding(.bottom, 110)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .accessibilityIdentifier("home.screen")
    }

    private func header(xp: Int, streak: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dahdit")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dahdit.cream)
                    Text("Operator training")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.62))
                }
                Spacer()
                XPHud(xp: xp, streak: streak)
            }

            HStack(spacing: 14) {
                SignalMeter(level: 4)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today's signal")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.dahdit.accent)
                    Text("Warm up with the next unlocked drill.")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.62))
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
        }
    }

    private func skillSection(_ skill: SkillNode, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unit \(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dahdit.accent)
                    Text(skill.title)
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(Color.dahdit.cream)
                }
                Spacer()
                HUDChip("\(skill.lessons.filter(\.isCompleted).count)/\(skill.lessons.count)", systemImage: "checkmark.seal.fill", tint: Color.dahdit.success)
            }

            VStack(spacing: 12) {
                ForEach(skill.lessons) { lesson in
                    NavigationLink {
                        LessonContainerView(
                            lessonId: lesson.id,
                            api: environment.api,
                            audio: environment.audio
                        )
                    } label: {
                        LessonBubble(
                            title: lesson.title,
                            isUnlocked: lesson.isUnlocked,
                            isCompleted: lesson.isCompleted
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!lesson.isUnlocked)
                    .accessibilityIdentifier("lesson.\(lesson.title)")
                }
            }
        }
    }
}
