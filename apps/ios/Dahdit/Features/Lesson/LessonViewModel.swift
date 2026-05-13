import DahditAudio
import DahditCore
import DahditGraphQL
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class LessonViewModel {
    enum State: Equatable {
        case loading
        case exercise(Exercise)
        case complete(LessonResult?)
        case pendingSync
        case failed(String)
    }

    private let api: DahditAPI
    private let audio: MorseAudioPlayer
    private let codec = InternationalMorseCodec.shared
    private let lessonId: String
    private(set) var state: State = .loading
    private var exercises: [Exercise] = []
    private var attemptId: String?
    private var draft: LessonAttemptDraft?
    private var log: [ExerciseResult] = []
    private var index = 0
    var hearts = 5
    var currentInput = ""
    var isPlayingPrompt = false
    var playbackError: String?
    var progressFraction: Double {
        guard !exercises.isEmpty else { return 0 }
        return min(Double(index) / Double(exercises.count), 1)
    }
    var progressLabel: String {
        guard !exercises.isEmpty else { return "Loading" }
        return "\(min(index + 1, exercises.count)) / \(exercises.count)"
    }

    init(lessonId: String, api: DahditAPI, audio: MorseAudioPlayer) {
        self.lessonId = lessonId
        self.api = api
        self.audio = audio
    }

    func start(modelContext: ModelContext) async {
        state = .loading
        do {
            await LessonAttemptDraftSync.syncPending(in: modelContext, api: api)
            let attempt = try await api.startLesson(id: lessonId)
            attemptId = attempt.id
            exercises = attempt.exercises
            hearts = attempt.maxHearts
            index = 0
            log = []
            draft = upsertDraft(
                attemptId: attempt.id,
                lessonId: attempt.lessonId,
                modelContext: modelContext
            )
            persistDraft(modelContext: modelContext)
            playbackError = nil
            isPlayingPrompt = false
            state = exercises.first.map(State.exercise) ?? .complete(nil)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func playPrompt(for exercise: Exercise) async {
        guard let prompt = audioPrompt(for: exercise), !isPlayingPrompt else { return }
        isPlayingPrompt = true
        playbackError = nil
        defer { isPlayingPrompt = false }

        do {
            try await audio.play(symbols: prompt.symbols, timing: prompt.timing)
        } catch {
            playbackError = error.localizedDescription
        }
    }

    func submit(answer: JSONValue, modelContext: ModelContext) async {
        guard case .exercise(let exercise) = state else { return }
        let correct = isCorrect(exercise: exercise, answer: answer)
        let timeMs = 15_000 + index * 777
        log.append(ExerciseResult(
            exerciseId: exercise.id.uuidString.lowercased(),
            correct: correct,
            timeMs: timeMs,
            answer: answer
        ))

        if !correct { hearts = max(0, hearts - 1) }
        index += 1
        persistDraft(modelContext: modelContext)

        if index >= exercises.count {
            guard let attemptId else {
                state = .failed("Lesson attempt is missing.")
                return
            }
            do {
                let result = try await api.completeLesson(attemptId: attemptId, log: log)
                deleteDraft(modelContext: modelContext)
                state = .complete(result)
            } catch {
                markDraftPendingSync(error: error, modelContext: modelContext)
                state = .pendingSync
            }
        } else {
            state = .exercise(exercises[index])
        }
    }

    private func upsertDraft(
        attemptId rawAttemptId: String,
        lessonId: String,
        modelContext: ModelContext
    ) -> LessonAttemptDraft? {
        guard let attemptUUID = UUID(uuidString: rawAttemptId) else { return nil }

        let descriptor = FetchDescriptor<LessonAttemptDraft>(
            predicate: #Predicate { $0.attemptId == attemptUUID }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.lessonId = lessonId
            existing.currentExerciseIndex = 0
            existing.pendingCompletion = false
            existing.lastSyncError = nil
            existing.updatedAt = Date()
            return existing
        }

        let draft = LessonAttemptDraft(attemptId: attemptUUID, lessonId: lessonId)
        modelContext.insert(draft)
        return draft
    }

    private func persistDraft(modelContext: ModelContext) {
        guard let draft else { return }
        do {
            draft.currentExerciseIndex = index
            draft.logData = try JSONEncoder().encode(log)
            draft.pendingCompletion = false
            draft.lastSyncError = nil
            draft.updatedAt = Date()
            try modelContext.save()
        } catch {
            draft.lastSyncError = error.localizedDescription
            draft.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func markDraftPendingSync(error: Error, modelContext: ModelContext) {
        guard let draft else { return }
        do {
            draft.currentExerciseIndex = index
            draft.logData = try JSONEncoder().encode(log)
            draft.pendingCompletion = true
            draft.lastSyncError = error.localizedDescription
            draft.updatedAt = Date()
            try modelContext.save()
        } catch {
            draft.lastSyncError = error.localizedDescription
            draft.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func deleteDraft(modelContext: ModelContext) {
        guard let draft else { return }
        modelContext.delete(draft)
        try? modelContext.save()
        self.draft = nil
    }

    private func isCorrect(exercise: Exercise, answer: JSONValue) -> Bool {
        switch exercise.payload {
        case .listenAndType(let payload):
            guard case .string(let value) = answer else { return false }
            return payload.solution.accept.map(normalize).contains(normalize(value))
        case .copyAtSpeed(let payload):
            guard case .string(let value) = answer else { return false }
            return payload.solution.accept.map(normalize).contains(normalize(value))
        case .matchCharacterToCode(let payload):
            guard case .int(let value) = answer else { return false }
            return value == payload.solution.correctIndex
        case .tapTheCode(let payload):
            return symbols(from: answer) == payload.solution.symbols
        case .translateToMorse(let payload):
            return symbols(from: answer) == payload.solution.symbols
        }
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func audioPrompt(for exercise: Exercise) -> (symbols: [MorseSymbol], timing: MorseTiming)? {
        switch exercise.payload {
        case .listenAndType(let payload):
            (codec.encode(payload.prompt.text), payload.prompt.timing)
        case .copyAtSpeed(let payload):
            (codec.encode(payload.prompt.text), payload.prompt.timing)
        case .tapTheCode, .matchCharacterToCode, .translateToMorse:
            nil
        }
    }

    private func symbols(from answer: JSONValue) -> [MorseSymbol]? {
        guard case .array(let values) = answer else { return nil }
        return values.compactMap { value in
            guard case .string(let raw) = value else { return nil }
            return MorseSymbol(rawValue: raw)
        }
    }
}
