import CoreHaptics
import DahditCore
import Foundation

@MainActor
public final class MorseHapticPlayer {
    private var engine: CHHapticEngine?

    public init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    public func key(symbols: [MorseSymbol], timing: MorseTiming) throws {
        guard let engine else { return }
        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0
        let unit = timing.unitMs / 1000

        for symbol in symbols {
            switch symbol {
            case .dit:
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1),
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
                    ],
                    relativeTime: time
                ))
                time += unit
            case .dah:
                events.append(CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
                    ],
                    relativeTime: time,
                    duration: 3 * unit
                ))
                time += 3 * unit
            case .charGap:
                time += timing.charGapUnits * unit
            case .wordGap:
                time += timing.wordGapUnits * unit
            }
        }

        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        try player.start(atTime: 0)
    }
}

