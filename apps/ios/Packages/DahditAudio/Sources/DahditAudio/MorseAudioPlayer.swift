import AVFoundation
import DahditCore
import Foundation

public actor MorseAudioPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100

    public init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    public func play(symbols: [MorseSymbol], timing: MorseTiming) async throws {
        try configureSession()
        try stop()

        let buffer = makeBuffer(symbols: symbols, timing: timing)
        engine.prepare()
        try engine.start()
        await player.scheduleBuffer(buffer)
        player.play()

        let duration = Double(buffer.frameLength) / sampleRate
        try await Task.sleep(for: .seconds(duration))
    }

    public func stop() throws {
        if player.isPlaying { player.stop() }
        if engine.isRunning { engine.stop() }
    }

    private func makeBuffer(symbols: [MorseSymbol], timing: MorseTiming) -> AVAudioPCMBuffer {
        let codec = InternationalMorseCodec()
        let durationMs = codec.audioDurationMs(symbols: symbols, timing: timing)
        let frameCount = AVAudioFrameCount(max(1, Int((durationMs / 1000) * sampleRate)))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else { return buffer }
        var cursor = 0

        func writeTone(units: Double) {
            let frames = Int((units * timing.unitMs / 1000) * sampleRate)
            let attackFrames = Int(0.005 * sampleRate)
            for frame in 0..<frames where cursor + frame < Int(frameCount) {
                let t = Double(frame) / sampleRate
                let envelope = envelopeValue(frame: frame, totalFrames: frames, attackFrames: attackFrames)
                channel[cursor + frame] = Float(sin(2 * .pi * timing.toneHz * t) * 0.35 * envelope)
            }
            cursor += frames
        }

        func writeSilence(units: Double) {
            cursor += Int((units * timing.unitMs / 1000) * sampleRate)
            cursor = min(cursor, Int(frameCount))
        }

        for (index, symbol) in symbols.enumerated() {
            switch symbol {
            case .dit:
                writeTone(units: 1)
            case .dah:
                writeTone(units: 3)
            case .charGap:
                writeSilence(units: timing.charGapUnits)
            case .wordGap:
                writeSilence(units: timing.wordGapUnits)
            }

            if index + 1 < symbols.count,
               [.dit, .dah].contains(symbol),
               [.dit, .dah].contains(symbols[index + 1]) {
                writeSilence(units: 1)
            }
        }

        return buffer
    }

    private func envelopeValue(frame: Int, totalFrames: Int, attackFrames: Int) -> Double {
        guard attackFrames > 0 else { return 1 }
        if frame < attackFrames {
            return 0.5 - 0.5 * cos(.pi * Double(frame) / Double(attackFrames))
        }
        let releaseStart = max(0, totalFrames - attackFrames)
        if frame >= releaseStart {
            let position = Double(frame - releaseStart) / Double(attackFrames)
            return 0.5 + 0.5 * cos(.pi * position)
        }
        return 1
    }

    private func configureSession() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, options: [.mixWithOthers])
        try session.setActive(true)
        #endif
    }
}
