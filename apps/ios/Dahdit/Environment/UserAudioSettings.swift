import DahditCore
import Foundation
import SwiftData

struct AudioSettingsSnapshot: Sendable, Equatable {
    static let `default` = AudioSettingsSnapshot(
        defaultWpm: 15,
        farnsworthWpm: 10,
        toneHz: 700,
        hapticsEnabled: true
    )

    let defaultWpm: Double
    let farnsworthWpm: Double
    let toneHz: Double
    let hapticsEnabled: Bool

    var practiceTiming: MorseTiming {
        MorseTiming(
            wpm: defaultWpm,
            farnsworthWpm: normalizedFarnsworth,
            toneHz: toneHz
        )
    }

    func applyingTone(to timing: MorseTiming) -> MorseTiming {
        MorseTiming(
            wpm: timing.wpm,
            farnsworthWpm: timing.farnsworthWpm,
            toneHz: toneHz
        )
    }

    private var normalizedFarnsworth: Double? {
        farnsworthWpm < defaultWpm ? farnsworthWpm : nil
    }
}

@Model
final class UserAudioSettings {
    @Attribute(.unique) var id: String = "default"
    var defaultWpm: Double = 15
    var farnsworthWpm: Double = 10
    var toneHz: Double = 700
    var hapticsEnabled: Bool = true
    var updatedAt: Date = Date()

    init(
        id: String = "default",
        defaultWpm: Double = 15,
        farnsworthWpm: Double = 10,
        toneHz: Double = 700,
        hapticsEnabled: Bool = true
    ) {
        self.id = id
        self.defaultWpm = defaultWpm
        self.farnsworthWpm = farnsworthWpm
        self.toneHz = toneHz
        self.hapticsEnabled = hapticsEnabled
        self.updatedAt = Date()
    }

    var snapshot: AudioSettingsSnapshot {
        AudioSettingsSnapshot(
            defaultWpm: defaultWpm,
            farnsworthWpm: farnsworthWpm,
            toneHz: toneHz,
            hapticsEnabled: hapticsEnabled
        )
    }

    func touch() {
        farnsworthWpm = min(farnsworthWpm, defaultWpm)
        updatedAt = Date()
    }

    @discardableResult
    @MainActor
    static func current(in modelContext: ModelContext) -> UserAudioSettings {
        let descriptor = FetchDescriptor<UserAudioSettings>(
            predicate: #Predicate { $0.id == "default" }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let settings = UserAudioSettings()
        modelContext.insert(settings)
        try? modelContext.save()
        return settings
    }
}
