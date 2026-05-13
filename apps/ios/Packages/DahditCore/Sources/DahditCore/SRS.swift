import Foundation

public enum ReviewGrade: String, Sendable, Codable, CaseIterable {
    case again
    case hard
    case good
    case easy
}

public struct ReviewCard: Sendable, Codable, Equatable {
    public var userId: String
    public var cardKey: String
    public var ease: Double
    public var intervalDays: Int
    public var dueOn: String

    public init(userId: String, cardKey: String, ease: Double, intervalDays: Int, dueOn: String) {
        self.userId = userId
        self.cardKey = cardKey
        self.ease = ease
        self.intervalDays = intervalDays
        self.dueOn = dueOn
    }
}

public func scheduleNext(card: ReviewCard, grade: ReviewGrade, today: Date) -> ReviewCard {
    var next = card
    var ease = card.ease
    var intervalDays = card.intervalDays

    switch grade {
    case .again:
        ease -= 0.20
        intervalDays = 1
    case .hard:
        ease -= 0.15
        intervalDays = max(1, Int(ceil(Double(intervalDays) * 1.2)))
    case .good:
        intervalDays = max(1, Int(ceil(Double(intervalDays) * ease)))
    case .easy:
        ease += 0.15
        intervalDays = max(1, Int(ceil(Double(intervalDays) * ease * 1.3)))
    }

    let clampedEase = min(2.5, max(1.3, ease))
    let date = Calendar(identifier: .gregorian).date(
        byAdding: .day,
        value: intervalDays,
        to: Date.isoDateOnly(today)
    ) ?? today

    next.ease = (clampedEase * 100).rounded() / 100
    next.intervalDays = intervalDays
    next.dueOn = Date.isoDateString(date)
    return next
}

public extension Date {
    static func isoDateOnly(_ date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        return calendar.date(from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: components.year,
            month: components.month,
            day: components.day
        )) ?? date
    }

    static func isoDateString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

