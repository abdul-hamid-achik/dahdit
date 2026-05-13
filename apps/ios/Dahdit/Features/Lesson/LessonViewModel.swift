import DahditAudio
import DahditCore
import DahditGraphQL
import Foundation
import Observation

@MainActor
@Observable
final class LessonViewModel {
    enum State: Equatable {
        case loading
        case exercise(Exercise)
        case complete(LessonResult?)
        case failed(String)
    }

    private let api: DahditAPI
    private let audio: MorseAudioPlayer
    private let codec = InternationalMorseCodec.shared
    private let lessonId: String
    private(set) var state: State = .loading
    private var exercises: [Exercise] = []
    private var attemptId: String?
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

    func start() async {
        state = .loading
        do {
            let attempt = try await api.startLesson(id: lessonId)
            attemptId = attempt.id
            exercises = attempt.exercises
            hearts = attempt.maxHearts
            index = 0
            log = []
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

    func submit(answer: JSONValue) async {
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

        if index >= exercises.count {
            guard let attemptId else {
                state = .failed("Lesson attempt is missing.")
                return
            }
            do {
                let result = try await api.completeLesson(attemptId: attemptId, log: log)
                state = .complete(result)
            } catch {
                state = .failed(error.localizedDescription)
            }
        } else {
            state = .exercise(exercises[index])
        }
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
