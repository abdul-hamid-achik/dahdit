import DahditCore
@testable import DahditGraphQL
import Testing

@Suite("JSON payload decoding")
struct JSONValueDecodingTests {
    @Test func decodesSeededExercisePayloads() throws {
        let payloads: [JSONValue] = [
            .object([
                "kind": .string("matchCharacterToCode"),
                "prompt": .object([
                    "character": .string("E"),
                    "options": .array([.string("."), .string("-"), .string(".-"), .string("-.")]),
                ]),
                "solution": .object(["correctIndex": .int(0)]),
            ]),
            .object([
                "kind": .string("listenAndType"),
                "prompt": .object([
                    "text": .string("ET"),
                    "timing": .object([
                        "wpm": .int(12),
                        "toneHz": .int(700),
                        "farnsworthWpm": .int(8),
                    ]),
                ]),
                "solution": .object(["accept": .array([.string("ET")])]),
            ]),
            .object([
                "kind": .string("tapTheCode"),
                "prompt": .object(["character": .string("A")]),
                "solution": .object(["symbols": .array([.string("dit"), .string("dah")])]),
            ]),
            .object([
                "kind": .string("translateToMorse"),
                "prompt": .object(["text": .string("SOS")]),
                "solution": .object([
                    "symbols": .array([
                        .string("dit"),
                        .string("dit"),
                        .string("dit"),
                        .string("charGap"),
                        .string("dah"),
                        .string("dah"),
                        .string("dah"),
                        .string("charGap"),
                        .string("dit"),
                        .string("dit"),
                        .string("dit"),
                    ]),
                ]),
            ]),
            .object([
                "kind": .string("copyAtSpeed"),
                "prompt": .object([
                    "text": .string("CQ CQ DE DAHDIT"),
                    "timing": .object([
                        "wpm": .int(12),
                        "toneHz": .int(700),
                        "farnsworthWpm": .int(8),
                    ]),
                    "durationSec": .int(20),
                ]),
                "solution": .object([
                    "accept": .array([.string("CQ CQ DE DAHDIT")]),
                    "toleranceLevenshteinPer5Chars": .int(1),
                ]),
            ]),
        ]

        for payload in payloads {
            _ = try payload.decoded(ExercisePayload.self)
        }
    }

    @Test func decodesJSONStringPayload() throws {
        let payload = JSONValue.string("""
        {
          "kind": "matchCharacterToCode",
          "prompt": {
            "character": "E",
            "options": [".", "-", ".-", "-."]
          },
          "solution": {
            "correctIndex": 0
          }
        }
        """)
        _ = try payload.decoded(ExercisePayload.self)
    }
}
