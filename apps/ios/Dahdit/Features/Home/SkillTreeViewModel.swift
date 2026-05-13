import DahditGraphQL
import Observation
import SwiftUI

struct SkillNode: Identifiable, Hashable {
    let id: String
    let title: String
    let lessons: [LessonNode]
}

struct LessonNode: Identifiable, Hashable {
    let id: String
    let title: String
    let isUnlocked: Bool
    let isCompleted: Bool
}

struct HomeSnapshot: Equatable {
    let skills: [SkillNode]
    let xpTotal: Int
    let streakDays: Int
}

@MainActor
@Observable
final class SkillTreeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(HomeSnapshot)
        case failed(String)
    }

    private let api: DahditAPI
    var state: State = .idle

    init(api: DahditAPI) {
        self.api = api
    }

    func load() async {
        state = .loading
        do {
            async let treeRequest = api.currentSkillTree()
            async let userRequest = api.me()

            let tree = try await treeRequest
            let user = try await userRequest
            let lessonsBySkill = Dictionary(grouping: tree.lessons, by: \.skillId)
            let nodes = tree.skills
                .sorted { $0.position < $1.position }
                .map { skill in
                    SkillNode(
                        id: skill.id,
                        title: skill.title,
                        lessons: (lessonsBySkill[skill.id] ?? [])
                            .sorted { $0.position < $1.position }
                            .map { lesson in
                                LessonNode(
                                    id: lesson.id,
                                    title: lesson.title,
                                    isUnlocked: tree.unlockedLessonIds.contains(lesson.id),
                                    isCompleted: false
                                )
                            }
                    )
                }
            state = .loaded(
                HomeSnapshot(
                    skills: nodes,
                    xpTotal: user?.stats?.xpTotal ?? 0,
                    streakDays: user?.stats?.streakDays ?? 0
                )
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
