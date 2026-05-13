import Foundation

public enum MorseSymbol: String, Sendable, Codable, CaseIterable {
    case dit
    case dah
    case charGap
    case wordGap
}

public struct MorseTiming: Sendable, Codable, Equatable {
    public var wpm: Double
    public var farnsworthWpm: Double?
    public var toneHz: Double

    public init(wpm: Double, farnsworthWpm: Double? = nil, toneHz: Double = 700) {
        self.wpm = wpm
        self.farnsworthWpm = farnsworthWpm
        self.toneHz = toneHz
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wpm = try container.decode(Double.self, forKey: .wpm)
        farnsworthWpm = try container.decodeIfPresent(Double.self, forKey: .farnsworthWpm)
        toneHz = try container.decodeIfPresent(Double.self, forKey: .toneHz) ?? 700
    }

    public var unitMs: Double { 1_200 / wpm }

    public var charGapUnits: Double {
        stretchedGapUnits(standard: 3)
    }

    public var wordGapUnits: Double {
        stretchedGapUnits(standard: 7)
    }

    private func stretchedGapUnits(standard: Double) -> Double {
        guard let farnsworthWpm, farnsworthWpm < wpm else { return standard }
        return standard * (wpm / farnsworthWpm)
    }
}

public protocol MorseCodec: Sendable {
    func encode(_ text: String) -> [MorseSymbol]
    func decode(_ symbols: [MorseSymbol]) -> String
}

public struct InternationalMorseCodec: MorseCodec, Sendable {
    public static let shared = InternationalMorseCodec()

    public init() {}

    public func encode(_ text: String) -> [MorseSymbol] {
        let words = text
            .uppercased()
            .split(whereSeparator: { $0.isWhitespace })

        var symbols: [MorseSymbol] = []
        for (wordIndex, word) in words.enumerated() {
            let encodableCharacters = word.compactMap { character -> String? in
                InternationalMorseCodec.textToCode[String(character)]
            }

            for (characterIndex, code) in encodableCharacters.enumerated() {
                symbols.append(contentsOf: code.map { $0 == "." ? .dit : .dah })
                if characterIndex < encodableCharacters.count - 1 {
                    symbols.append(.charGap)
                }
            }

            if wordIndex < words.count - 1 {
                symbols.append(.wordGap)
            }
        }
        return symbols
    }

    public func decode(_ symbols: [MorseSymbol]) -> String {
        var words: [String] = []
        var word = ""
        var current = ""

        func flushCharacter() {
            guard !current.isEmpty else { return }
            word += InternationalMorseCodec.codeToText[current] ?? "?"
            current = ""
        }

        for symbol in symbols {
            switch symbol {
            case .dit:
                current += "."
            case .dah:
                current += "-"
            case .charGap:
                flushCharacter()
            case .wordGap:
                flushCharacter()
                if !word.isEmpty { words.append(word) }
                word = ""
            }
        }

        flushCharacter()
        if !word.isEmpty { words.append(word) }
        return words.joined(separator: " ")
    }

    public func audioDurationMs(symbols: [MorseSymbol], timing: MorseTiming) -> Double {
        var totalUnits: Double = 0

        for (index, symbol) in symbols.enumerated() {
            switch symbol {
            case .dit:
                totalUnits += 1
            case .dah:
                totalUnits += 3
            case .charGap:
                totalUnits += timing.charGapUnits
            case .wordGap:
                totalUnits += timing.wordGapUnits
            }

            if index + 1 < symbols.count,
               [.dit, .dah].contains(symbol),
               [.dit, .dah].contains(symbols[index + 1]) {
                totalUnits += 1
            }
        }

        return totalUnits * timing.unitMs
    }

    public static let textToCode: [String: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
        "F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
        "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
        "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
        "U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
        "Z": "--..", "0": "-----", "1": ".----", "2": "..---",
        "3": "...--", "4": "....-", "5": ".....", "6": "-....",
        "7": "--...", "8": "---..", "9": "----.", ".": ".-.-.-",
        ",": "--..--", "?": "..--..", "/": "-..-.", "=": "-...-",
        "+": ".-.-.", "-": "-....-"
    ]

    public static let codeToText: [String: String] = Dictionary(
        uniqueKeysWithValues: textToCode.map { ($0.value, $0.key) }
    )
}
