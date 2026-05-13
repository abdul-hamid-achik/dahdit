import Foundation

public typealias ExerciseID = UUID
public typealias LessonID = UUID

public enum ExerciseKind: String, Sendable, Codable, CaseIterable {
    case listenAndType
    case tapTheCode
    case matchCharacterToCode
    case translateToMorse
    case copyAtSpeed
}

public struct Exercise: Sendable, Identifiable, Codable, Equatable {
    public let id: ExerciseID
    public let lessonId: LessonID
    public let kind: ExerciseKind
    public let payload: ExercisePayload

    public init(id: ExerciseID, lessonId: LessonID, kind: ExerciseKind, payload: ExercisePayload) {
        self.id = id
        self.lessonId = lessonId
        self.kind = kind
        self.payload = payload
    }
}

public enum ExercisePayload: Sendable, Codable, Equatable {
    case listenAndType(ListenAndTypePayload)
    case tapTheCode(TapTheCodePayload)
    case matchCharacterToCode(MatchCharacterToCodePayload)
    case translateToMorse(TranslateToMorsePayload)
    case copyAtSpeed(CopyAtSpeedPayload)

    public var kind: ExerciseKind {
        switch self {
        case .listenAndType: .listenAndType
        case .tapTheCode: .tapTheCode
        case .matchCharacterToCode: .matchCharacterToCode
        case .translateToMorse: .translateToMorse
        case .copyAtSpeed: .copyAtSpeed
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind
    }

    private enum PayloadCodingKeys: String, CodingKey {
        case kind
        case prompt
        case solution
    }

    public init(from decoder: Decoder) throws {
        let kindContainer = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try kindContainer.decode(ExerciseKind.self, forKey: .kind)

        switch kind {
        case .listenAndType:
            self = .listenAndType(try ListenAndTypePayload(from: decoder))
        case .tapTheCode:
            self = .tapTheCode(try TapTheCodePayload(from: decoder))
        case .matchCharacterToCode:
            self = .matchCharacterToCode(try MatchCharacterToCodePayload(from: decoder))
        case .translateToMorse:
            self = .translateToMorse(try TranslateToMorsePayload(from: decoder))
        case .copyAtSpeed:
            self = .copyAtSpeed(try CopyAtSpeedPayload(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PayloadCodingKeys.self)
        try container.encode(kind, forKey: .kind)

        switch self {
        case .listenAndType(let payload):
            try container.encode(payload.prompt, forKey: .prompt)
            try container.encode(payload.solution, forKey: .solution)
        case .tapTheCode(let payload):
            try container.encode(payload.prompt, forKey: .prompt)
            try container.encode(payload.solution, forKey: .solution)
        case .matchCharacterToCode(let payload):
            try container.encode(payload.prompt, forKey: .prompt)
            try container.encode(payload.solution, forKey: .solution)
        case .translateToMorse(let payload):
            try container.encode(payload.prompt, forKey: .prompt)
            try container.encode(payload.solution, forKey: .solution)
        case .copyAtSpeed(let payload):
            try container.encode(payload.prompt, forKey: .prompt)
            try container.encode(payload.solution, forKey: .solution)
        }
    }
}

public struct ListenAndTypePayload: Sendable, Codable, Equatable {
    public var prompt: AudioTextPrompt
    public var solution: AcceptedTextSolution

    public init(prompt: AudioTextPrompt, solution: AcceptedTextSolution) {
        self.prompt = prompt
        self.solution = solution
    }
}

public struct TapTheCodePayload: Sendable, Codable, Equatable {
    public var prompt: CharacterPrompt
    public var solution: SymbolSolution

    public init(prompt: CharacterPrompt, solution: SymbolSolution) {
        self.prompt = prompt
        self.solution = solution
    }
}

public struct MatchCharacterToCodePayload: Sendable, Codable, Equatable {
    public var prompt: MultipleChoicePrompt
    public var solution: CorrectIndexSolution

    public init(prompt: MultipleChoicePrompt, solution: CorrectIndexSolution) {
        self.prompt = prompt
        self.solution = solution
    }
}

public struct TranslateToMorsePayload: Sendable, Codable, Equatable {
    public var prompt: TextPrompt
    public var solution: SymbolSolution

    public init(prompt: TextPrompt, solution: SymbolSolution) {
        self.prompt = prompt
        self.solution = solution
    }
}

public struct CopyAtSpeedPayload: Sendable, Codable, Equatable {
    public var prompt: CopyPrompt
    public var solution: CopySolution

    public init(prompt: CopyPrompt, solution: CopySolution) {
        self.prompt = prompt
        self.solution = solution
    }
}

public struct AudioTextPrompt: Sendable, Codable, Equatable {
    public var text: String
    public var timing: MorseTiming

    public init(text: String, timing: MorseTiming) {
        self.text = text
        self.timing = timing
    }
}

public struct CharacterPrompt: Sendable, Codable, Equatable {
    public var character: String

    public init(character: String) {
        self.character = character
    }
}

public struct MultipleChoicePrompt: Sendable, Codable, Equatable {
    public var character: String
    public var options: [String]

    public init(character: String, options: [String]) {
        self.character = character
        self.options = options
    }
}

public struct TextPrompt: Sendable, Codable, Equatable {
    public var text: String

    public init(text: String) {
        self.text = text
    }
}

public struct CopyPrompt: Sendable, Codable, Equatable {
    public var text: String
    public var timing: MorseTiming
    public var durationSec: Int

    public init(text: String, timing: MorseTiming, durationSec: Int) {
        self.text = text
        self.timing = timing
        self.durationSec = durationSec
    }
}

public struct AcceptedTextSolution: Sendable, Codable, Equatable {
    public var accept: [String]

    public init(accept: [String]) {
        self.accept = accept
    }
}

public struct SymbolSolution: Sendable, Codable, Equatable {
    public var symbols: [MorseSymbol]

    public init(symbols: [MorseSymbol]) {
        self.symbols = symbols
    }
}

public struct CorrectIndexSolution: Sendable, Codable, Equatable {
    public var correctIndex: Int

    public init(correctIndex: Int) {
        self.correctIndex = correctIndex
    }
}

public struct CopySolution: Sendable, Codable, Equatable {
    public var accept: [String]
    public var toleranceLevenshteinPer5Chars: Int

    public init(accept: [String], toleranceLevenshteinPer5Chars: Int) {
        self.accept = accept
        self.toleranceLevenshteinPer5Chars = toleranceLevenshteinPer5Chars
    }
}
