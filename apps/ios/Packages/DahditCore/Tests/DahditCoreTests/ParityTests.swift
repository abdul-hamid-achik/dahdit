import Foundation
import Testing
@testable import DahditCore

private struct CodecVector: Decodable {
    let text: String
    let symbols: [MorseSymbol]
    let decoded: String
}

private struct SRSVector: Decodable {
    let card: ReviewCard
    let grade: ReviewGrade
    let today: String
    let expected: ReviewCard
}

@Suite("Morse parity vectors")
struct ParityTests {
    @Test func codecVectors() throws {
        let vectors: [CodecVector] = try load("codec")
        let codec = InternationalMorseCodec()

        for vector in vectors {
            #expect(codec.encode(vector.text) == vector.symbols)
            #expect(codec.decode(vector.symbols) == vector.decoded)
        }
    }

    @Test func srsVectors() throws {
        let vectors: [SRSVector] = try load("srs")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for vector in vectors {
            let today = try #require(formatter.date(from: vector.today))
            #expect(scheduleNext(card: vector.card, grade: vector.grade, today: today) == vector.expected)
        }
    }

    @Test func sendTimingThresholds() {
        let timing = MorseTiming(wpm: 15)
        #expect(SendTimingClassifier.classifyPress(durationMs: 90, timing: timing) == .dit)
        #expect(SendTimingClassifier.classifyPress(durationMs: 160, timing: timing) == .dah)
        #expect(SendTimingClassifier.classifyGap(gapMs: 250, timing: timing) == .characterBoundary)
        #expect(SendTimingClassifier.classifyGap(gapMs: 450, timing: timing) == .endOfInput)
    }

    private func load<T: Decodable>(_ name: String) throws -> T {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json"))
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
