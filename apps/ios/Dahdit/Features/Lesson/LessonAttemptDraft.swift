import Foundation
import SwiftData

@Model
final class LessonAttemptDraft {
    @Attribute(.unique) var attemptId: UUID
    var lessonId: String
    var currentExerciseIndex: Int
    var logData: Data
    var updatedAt: Date

    init(attemptId: UUID, lessonId: String, currentExerciseIndex: Int = 0, logData: Data = Data()) {
        self.attemptId = attemptId
        self.lessonId = lessonId
        self.currentExerciseIndex = currentExerciseIndex
        self.logData = logData
        self.updatedAt = Date()
    }
}

