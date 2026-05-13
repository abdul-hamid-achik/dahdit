import Foundation
import DahditGraphQL
import SwiftData

@Model
final class LessonAttemptDraft {
    @Attribute(.unique) var attemptId: UUID
    var lessonId: String
    var currentExerciseIndex: Int
    var logData: Data
    var pendingCompletion: Bool = false
    var lastSyncError: String?
    var updatedAt: Date

    init(
        attemptId: UUID,
        lessonId: String,
        currentExerciseIndex: Int = 0,
        logData: Data = Data(),
        pendingCompletion: Bool = false,
        lastSyncError: String? = nil
    ) {
        self.attemptId = attemptId
        self.lessonId = lessonId
        self.currentExerciseIndex = currentExerciseIndex
        self.logData = logData
        self.pendingCompletion = pendingCompletion
        self.lastSyncError = lastSyncError
        self.updatedAt = Date()
    }
}

@MainActor
enum LessonAttemptDraftSync {
    static func syncPending(in modelContext: ModelContext, api: DahditAPI) async {
        let descriptor = FetchDescriptor<LessonAttemptDraft>(
            predicate: #Predicate { $0.pendingCompletion == true },
            sortBy: [SortDescriptor(\.updatedAt)]
        )

        guard let drafts = try? modelContext.fetch(descriptor), !drafts.isEmpty else {
            return
        }

        for draft in drafts {
            do {
                let log = try JSONDecoder().decode([ExerciseResult].self, from: draft.logData)
                _ = try await api.completeLesson(
                    attemptId: draft.attemptId.uuidString.lowercased(),
                    log: log
                )
                modelContext.delete(draft)
                try? modelContext.save()
            } catch {
                draft.lastSyncError = error.localizedDescription
                draft.updatedAt = Date()
                try? modelContext.save()
            }
        }
    }
}
