import Foundation

public enum SendBoundary: Sendable, Equatable {
    case sameCharacter
    case characterBoundary
    case endOfInput
}

public struct SendTimingEvent: Sendable, Equatable {
    public var keyDownAtMs: Double
    public var keyUpAtMs: Double

    public init(keyDownAtMs: Double, keyUpAtMs: Double) {
        self.keyDownAtMs = keyDownAtMs
        self.keyUpAtMs = keyUpAtMs
    }
}

public struct SendDecodeResult: Sendable, Equatable {
    public var symbols: [MorseSymbol]
    public var boundaries: [SendBoundary]
}

public enum SendTimingClassifier {
    public static func classifyPress(durationMs: Double, timing: MorseTiming) -> MorseSymbol {
        durationMs < 1.5 * timing.unitMs ? .dit : .dah
    }

    public static func classifyGap(gapMs: Double, timing: MorseTiming) -> SendBoundary {
        if gapMs < 1.5 * timing.unitMs { return .sameCharacter }
        if gapMs < 5 * timing.unitMs { return .characterBoundary }
        return .endOfInput
    }

    public static func decode(events: [SendTimingEvent], timing: MorseTiming) -> SendDecodeResult {
        var symbols: [MorseSymbol] = []
        var boundaries: [SendBoundary] = []

        for (index, event) in events.enumerated() {
            symbols.append(classifyPress(durationMs: event.keyUpAtMs - event.keyDownAtMs, timing: timing))
            guard index + 1 < events.count else { continue }

            let gap = events[index + 1].keyDownAtMs - event.keyUpAtMs
            let boundary = classifyGap(gapMs: gap, timing: timing)
            boundaries.append(boundary)
            if boundary == .characterBoundary { symbols.append(.charGap) }
            if boundary == .endOfInput { symbols.append(.wordGap) }
        }

        return SendDecodeResult(symbols: symbols, boundaries: boundaries)
    }
}

