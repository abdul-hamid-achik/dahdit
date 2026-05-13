import Apollo
import ApolloAPI
import DahditCore
import Foundation

public typealias TokenProvider = @Sendable () async -> String?
public typealias TokenRefreshHandler = @Sendable () async -> Bool

public actor DahditAPI {
    private let client: ApolloClient
    private let tokenRefreshHandler: TokenRefreshHandler?

    public init(
        endpoint: URL,
        tokenProvider: @escaping TokenProvider,
        tokenRefreshHandler: TokenRefreshHandler? = nil,
        session: URLSession = .shared
    ) {
        self.tokenRefreshHandler = tokenRefreshHandler
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let transport = RequestChainNetworkTransport(
            urlSession: session,
            interceptorProvider: DahditInterceptorProvider(tokenProvider: tokenProvider),
            store: store,
            endpointURL: endpoint
        )
        client = ApolloClient(networkTransport: transport, store: store)
    }

    public func signup(email: String, username: String, password: String, tz: String) async throws -> AuthPayload {
        let data = try await perform(
            DahditGraphQLGenerated.SignupMutation(
                email: email,
                username: username,
                password: password,
                tz: GraphQLNullable.some(tz)
            )
        )
        guard let payload = data.signup else { throw DahditAPIError.emptyResponse }
        return try AuthPayload(payload)
    }

    public func login(email: String, password: String) async throws -> AuthPayload {
        let data = try await perform(
            DahditGraphQLGenerated.LoginMutation(email: email, password: password)
        )
        guard let payload = data.login else { throw DahditAPIError.emptyResponse }
        return try AuthPayload(payload)
    }

    public func refreshToken(_ refreshToken: String) async throws -> AuthPayload {
        let data = try await perform(
            DahditGraphQLGenerated.RefreshTokenMutation(refreshToken: refreshToken),
            allowsAuthRetry: false
        )
        guard let payload = data.refreshToken else { throw DahditAPIError.emptyResponse }
        return try AuthPayload(payload)
    }

    public func deleteAccount() async throws -> Bool {
        let data = try await perform(DahditGraphQLGenerated.DeleteAccountMutation())
        return data.deleteAccount ?? false
    }

    public func me() async throws -> APIUser? {
        let data = try await fetch(DahditGraphQLGenerated.MeQuery())
        guard let user = data.me else { return nil }
        return try APIUser(user)
    }

    public func currentSkillTree() async throws -> SkillTree {
        let data = try await fetch(DahditGraphQLGenerated.SkillTreeQuery())
        guard let skillTree = data.skillTree else { throw DahditAPIError.emptyResponse }
        return try SkillTree(skillTree)
    }

    public func startLesson(id lessonId: String) async throws -> LessonAttempt {
        let data = try await perform(DahditGraphQLGenerated.StartLessonMutation(lessonId: lessonId))
        guard let attempt = data.startLesson else { throw DahditAPIError.emptyResponse }
        return try attempt.toDomain()
    }

    public func completeLesson(attemptId: String, log: [ExerciseResult]) async throws -> LessonResult {
        let data = try await perform(
            DahditGraphQLGenerated.CompleteLessonMutation(
                attemptId: attemptId,
                log: log.map(\.input)
            )
        )
        guard let result = data.completeLesson else { throw DahditAPIError.emptyResponse }
        return try LessonResult(result)
    }

    public func dueReviews(limit: Int = 30) async throws -> [ReviewCard] {
        let data = try await fetch(DahditGraphQLGenerated.DueReviewsQuery(limit: GraphQLNullable.some(Int32(limit))))
        return try (data.dueReviews ?? []).map(ReviewCard.init)
    }

    public func completeReviews(_ results: [ReviewResult]) async throws -> CompleteReviewsResult {
        let data = try await perform(
            DahditGraphQLGenerated.CompleteReviewsMutation(results: results.map(\.input))
        )
        guard let result = data.completeReviews else { throw DahditAPIError.emptyResponse }
        return try CompleteReviewsResult(result)
    }

    public func leaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        let data = try await fetch(DahditGraphQLGenerated.LeaderboardQuery(limit: GraphQLNullable.some(Int32(limit))))
        return try (data.leaderboard ?? []).map(LeaderboardEntry.init)
    }
}

private extension DahditAPI {
    func fetch<Query: GraphQLQuery>(_ query: Query) async throws -> Query.Data
        where Query.ResponseFormat == SingleResponseFormat {
        try await withAuthRetry {
            try data(from: await client.fetch(query: query, cachePolicy: .networkOnly))
        }
    }

    func perform<Mutation: GraphQLMutation>(
        _ mutation: Mutation,
        allowsAuthRetry: Bool = true
    ) async throws -> Mutation.Data
        where Mutation.ResponseFormat == SingleResponseFormat {
        try await withAuthRetry(allowsAuthRetry: allowsAuthRetry) {
            try data(from: await client.perform(mutation: mutation))
        }
    }

    func withAuthRetry<Value>(
        allowsAuthRetry: Bool = true,
        _ operation: () async throws -> Value
    ) async throws -> Value {
        do {
            return try await operation()
        } catch {
            let normalizedError = normalize(error)
            guard allowsAuthRetry,
                  normalizedError.isAuthenticationFailure,
                  let tokenRefreshHandler,
                  await tokenRefreshHandler() else {
                throw normalizedError
            }

            do {
                return try await operation()
            } catch {
                throw normalize(error)
            }
        }
    }

    func data<Operation: GraphQLOperation>(from response: GraphQLResponse<Operation>) throws -> Operation.Data {
        if let first = response.errors?.first {
            throw DahditAPIError.graphql(first.message ?? first.localizedDescription)
        }
        guard let data = response.data else { throw DahditAPIError.emptyResponse }
        return data
    }

    func normalize(_ error: any Error) -> DahditAPIError {
        if let error = error as? DahditAPIError {
            return error
        }

        if let error = error as? ResponseCodeInterceptor.ResponseCodeError {
            if error.response.statusCode == 401 || error.response.statusCode == 403 {
                return .graphql(error.graphQLError?.message ?? "Unauthenticated")
            }
            return .transport
        }

        return .transport
    }
}

private struct DahditInterceptorProvider: InterceptorProvider {
    let tokenProvider: TokenProvider

    func httpInterceptors<Operation: GraphQLOperation>(for operation: Operation) -> [any HTTPInterceptor] {
        [
            AuthorizationHTTPInterceptor(tokenProvider: tokenProvider),
            ResponseCodeInterceptor()
        ]
    }
}

private struct AuthorizationHTTPInterceptor: HTTPInterceptor {
    let tokenProvider: TokenProvider

    func intercept(
        request: URLRequest,
        next: NextHTTPInterceptorFunction
    ) async throws -> HTTPResponse {
        var request = request
        if let token = await tokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await next(request)
    }
}

public enum DahditAPIError: Error, Sendable, Equatable {
    case transport
    case graphql(String)
    case emptyResponse
    case invalidPayload(String)
    case decoding(String)

    public var isAuthenticationFailure: Bool {
        switch self {
        case .graphql(let message):
            let lowercased = message.lowercased()
            return lowercased.contains("not authorized")
                || lowercased.contains("unauthenticated")
                || lowercased.contains("authentication")
                || lowercased.contains("refresh expired")
        case .transport, .emptyResponse, .invalidPayload, .decoding:
            return false
        }
    }
}

extension DahditAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .transport:
            "The API request failed."
        case .graphql(let message), .invalidPayload(let message), .decoding(let message):
            message
        case .emptyResponse:
            "The API returned no data."
        }
    }
}

public struct APIUser: Sendable, Codable, Equatable {
    public let id: String
    public let email: String
    public let username: String
    public let tz: String
    public let stats: APIUserStats?
}

public struct APIUserStats: Sendable, Codable, Equatable {
    public let xpTotal: Int
    public let streakDays: Int
    public let hearts: Int
    public let heartsRefillAt: Date?
}

public struct AuthPayload: Sendable, Codable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let user: APIUser
}

public struct SkillTree: Sendable, Codable, Equatable {
    public let unlockedSkillIds: [String]
    public let unlockedLessonIds: [String]
    public let skills: [Skill]
    public let lessons: [Lesson]
}

public struct Skill: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let slug: String
    public let title: String
    public let description: String
    public let position: Int
    public let prereqIds: [String]
}

public struct Lesson: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let skillId: String
    public let slug: String
    public let title: String
    public let position: Int
    public let xpReward: Int
}

public struct LessonAttempt: Sendable, Equatable, Identifiable {
    public let id: String
    public let lessonId: String
    public let startedAt: Date
    public let maxHearts: Int
    public let exercises: [Exercise]
}

public struct ExerciseResult: Sendable, Codable, Equatable {
    public let exerciseId: String
    public let correct: Bool
    public let timeMs: Int
    public let answer: JSONValue

    public init(exerciseId: String, correct: Bool, timeMs: Int, answer: JSONValue) {
        self.exerciseId = exerciseId
        self.correct = correct
        self.timeMs = timeMs
        self.answer = answer
    }

    var jsonValue: JSONValue {
        .object([
            "exerciseId": .string(exerciseId),
            "correct": .bool(correct),
            "timeMs": .int(timeMs),
            "answer": answer
        ])
    }
}

public struct LessonResult: Sendable, Codable, Equatable {
    public let xpEarned: Int
    public let newStreak: Int
    public let unlockedLessons: [String]
}

public struct ReviewCard: Sendable, Codable, Equatable, Identifiable {
    public var id: String { cardKey }
    public let cardKey: String
    public let ease: Double
    public let intervalDays: Int
    public let dueOn: String
}

public struct ReviewResult: Sendable, Equatable {
    public let cardKey: String
    public let grade: DahditCore.ReviewGrade

    public init(cardKey: String, grade: DahditCore.ReviewGrade) {
        self.cardKey = cardKey
        self.grade = grade
    }

    var jsonValue: JSONValue {
        .object([
            "cardKey": .string(cardKey),
            "grade": .string(grade.rawValue)
        ])
    }
}

public struct CompleteReviewsResult: Sendable, Codable, Equatable {
    public let completedCount: Int
    public let remainingDueCount: Int
}

public struct LeaderboardEntry: Sendable, Codable, Equatable, Identifiable {
    public var id: String { userId }
    public let userId: String
    public let username: String
    public let xpTotal: Int
    public let streakDays: Int
    public let rank: Int
}

private extension AuthPayload {
    init(_ payload: DahditGraphQLGenerated.SignupMutation.Data.Signup) throws {
        accessToken = try required(payload.accessToken, "signup.accessToken")
        refreshToken = try required(payload.refreshToken, "signup.refreshToken")
        let user = try required(payload.user, "signup.user")
        self.user = try makeAPIUser(
            id: user.id,
            email: user.email,
            username: user.username,
            tz: user.tz,
            context: "signup.user"
        )
    }

    init(_ payload: DahditGraphQLGenerated.LoginMutation.Data.Login) throws {
        accessToken = try required(payload.accessToken, "login.accessToken")
        refreshToken = try required(payload.refreshToken, "login.refreshToken")
        let user = try required(payload.user, "login.user")
        self.user = try makeAPIUser(
            id: user.id,
            email: user.email,
            username: user.username,
            tz: user.tz,
            context: "login.user"
        )
    }

    init(_ payload: DahditGraphQLGenerated.RefreshTokenMutation.Data.RefreshToken) throws {
        accessToken = try required(payload.accessToken, "refreshToken.accessToken")
        refreshToken = try required(payload.refreshToken, "refreshToken.refreshToken")
        let user = try required(payload.user, "refreshToken.user")
        self.user = try makeAPIUser(
            id: user.id,
            email: user.email,
            username: user.username,
            tz: user.tz,
            context: "refreshToken.user"
        )
    }
}

private extension APIUser {
    init(_ user: DahditGraphQLGenerated.MeQuery.Data.Me) throws {
        self = try makeAPIUser(
            id: user.id,
            email: user.email,
            username: user.username,
            tz: user.tz,
            stats: try user.stats.map(APIUserStats.init),
            context: "me"
        )
    }
}

private extension APIUserStats {
    init(_ stats: DahditGraphQLGenerated.MeQuery.Data.Me.Stats) throws {
        xpTotal = try required(stats.xpTotal, "me.stats.xpTotal")
        streakDays = try required(stats.streakDays, "me.stats.streakDays")
        hearts = try required(stats.hearts, "me.stats.hearts")
        heartsRefillAt = try stats.heartsRefillAt.map { try parseDate($0, field: "me.stats.heartsRefillAt") }
    }
}

private extension SkillTree {
    init(_ tree: DahditGraphQLGenerated.SkillTreeQuery.Data.SkillTree) throws {
        unlockedSkillIds = try required(tree.unlockedSkillIds, "skillTree.unlockedSkillIds")
        unlockedLessonIds = try required(tree.unlockedLessonIds, "skillTree.unlockedLessonIds")
        skills = try required(tree.skills, "skillTree.skills").map(Skill.init)
        lessons = try required(tree.lessons, "skillTree.lessons").map(Lesson.init)
    }
}

private extension Skill {
    init(_ skill: DahditGraphQLGenerated.SkillTreeQuery.Data.SkillTree.Skill) throws {
        id = try required(skill.id, "skill.id")
        slug = try required(skill.slug, "skill.slug")
        title = try required(skill.title, "skill.title")
        description = try required(skill.description, "skill.description")
        position = try required(skill.position, "skill.position")
        prereqIds = try required(skill.prereqIds, "skill.prereqIds")
    }
}

private extension Lesson {
    init(_ lesson: DahditGraphQLGenerated.SkillTreeQuery.Data.SkillTree.Lesson) throws {
        id = try required(lesson.id, "lesson.id")
        skillId = try required(lesson.skillId, "lesson.skillId")
        slug = try required(lesson.slug, "lesson.slug")
        title = try required(lesson.title, "lesson.title")
        position = try required(lesson.position, "lesson.position")
        xpReward = try required(lesson.xpReward, "lesson.xpReward")
    }
}

private extension DahditGraphQLGenerated.StartLessonMutation.Data.StartLesson {
    func toDomain() throws -> LessonAttempt {
        let startedAt = try parseDate(try required(startedAt, "startLesson.startedAt"), field: "startLesson.startedAt")
        return try LessonAttempt(
            id: required(id, "startLesson.id"),
            lessonId: required(lessonId, "startLesson.lessonId"),
            startedAt: startedAt,
            maxHearts: required(maxHearts, "startLesson.maxHearts"),
            exercises: required(exercises, "startLesson.exercises").map { try $0.toDomain() }
        )
    }
}

private extension DahditGraphQLGenerated.StartLessonMutation.Data.StartLesson.Exercise {
    func toDomain() throws -> Exercise {
        let id = try required(id, "exercise.id")
        let lessonId = try required(lessonId, "exercise.lessonId")
        let kindRaw = try required(kind, "exercise.kind")
        let payload = try required(payload, "exercise.payload")
        guard let exerciseId = UUID(uuidString: id) else {
            throw DahditAPIError.invalidPayload("Invalid exercise id \(id)")
        }
        guard let lessonUUID = UUID(uuidString: lessonId) else {
            throw DahditAPIError.invalidPayload("Invalid lesson id \(lessonId)")
        }
        guard let kind = ExerciseKind(rawValue: kindRaw) else {
            throw DahditAPIError.invalidPayload("Invalid exercise kind \(kindRaw)")
        }
        let decodedPayload = try payload.decoded(ExercisePayload.self)
        return Exercise(id: exerciseId, lessonId: lessonUUID, kind: kind, payload: decodedPayload)
    }
}

private extension LessonResult {
    init(_ result: DahditGraphQLGenerated.CompleteLessonMutation.Data.CompleteLesson) throws {
        xpEarned = try required(result.xpEarned, "completeLesson.xpEarned")
        newStreak = try required(result.newStreak, "completeLesson.newStreak")
        unlockedLessons = try required(result.unlockedLessons, "completeLesson.unlockedLessons")
    }
}

private extension ReviewCard {
    init(_ card: DahditGraphQLGenerated.DueReviewsQuery.Data.DueReview) throws {
        cardKey = try required(card.cardKey, "dueReviews.cardKey")
        ease = try required(card.ease, "dueReviews.ease")
        intervalDays = try required(card.intervalDays, "dueReviews.intervalDays")
        dueOn = try required(card.dueOn, "dueReviews.dueOn")
    }
}

private extension CompleteReviewsResult {
    init(_ result: DahditGraphQLGenerated.CompleteReviewsMutation.Data.CompleteReviews) throws {
        completedCount = try required(result.completedCount, "completeReviews.completedCount")
        remainingDueCount = try required(result.remainingDueCount, "completeReviews.remainingDueCount")
    }
}

private extension LeaderboardEntry {
    init(_ entry: DahditGraphQLGenerated.LeaderboardQuery.Data.Leaderboard) throws {
        userId = try required(entry.userId, "leaderboard.userId")
        username = try required(entry.username, "leaderboard.username")
        xpTotal = try required(entry.xpTotal, "leaderboard.xpTotal")
        streakDays = try required(entry.streakDays, "leaderboard.streakDays")
        rank = try required(entry.rank, "leaderboard.rank")
    }
}

private extension ExerciseResult {
    var input: DahditGraphQLGenerated.ExerciseResultInput {
        DahditGraphQLGenerated.ExerciseResultInput(
            answer: answer,
            correct: correct,
            exerciseId: exerciseId,
            timeMs: Int32(timeMs)
        )
    }
}

private extension ReviewResult {
    var input: DahditGraphQLGenerated.ReviewResultInput {
        DahditGraphQLGenerated.ReviewResultInput(cardKey: cardKey, grade: grade.rawValue)
    }
}

private func makeAPIUser(
    id: String?,
    email: String?,
    username: String?,
    tz: String?,
    stats: APIUserStats? = nil,
    context: String
) throws -> APIUser {
    try APIUser(
        id: required(id, "\(context).id"),
        email: required(email, "\(context).email"),
        username: required(username, "\(context).username"),
        tz: required(tz, "\(context).tz"),
        stats: stats
    )
}

private func required<Value>(_ value: Value?, _ field: String) throws -> Value {
    guard let value else { throw DahditAPIError.invalidPayload("Missing \(field)") }
    return value
}

private func parseDate(_ value: String, field: String) throws -> Date {
    let fractionalFormatter = ISO8601DateFormatter()
    fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractionalFormatter.date(from: value) {
        return date
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    guard let date = formatter.date(from: value) else {
        throw DahditAPIError.invalidPayload("Invalid date for \(field): \(value)")
    }
    return date
}

public enum JSONValue: Sendable, Codable, Equatable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public func decoded<Value: Decodable>(_ type: Value.Type) throws -> Value {
        let decoder = JSONDecoder.dahdit

        do {
            if case .string(let value) = self,
               let data = value.data(using: .utf8),
               let decoded = try? decoder.decode(type, from: data) {
                return decoded
            }

            let data = try JSONEncoder().encode(self)
            return try decoder.decode(type, from: data)
        } catch let error as DecodingError {
            throw DahditAPIError.decoding(error.dahditDescription)
        }
    }
}

private extension JSONDecoder {
    static var dahdit: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension DecodingError {
    var dahditDescription: String {
        switch self {
        case .keyNotFound(let key, let context):
            "Missing key '\(key.stringValue)' at \(context.dahditPath)."
        case .valueNotFound(_, let context):
            "Missing value at \(context.dahditPath): \(context.debugDescription)"
        case .typeMismatch(_, let context):
            "Type mismatch at \(context.dahditPath): \(context.debugDescription)"
        case .dataCorrupted(let context):
            "Invalid data at \(context.dahditPath): \(context.debugDescription)"
        @unknown default:
            "The API response could not be decoded."
        }
    }
}

private extension DecodingError.Context {
    var dahditPath: String {
        let path = codingPath.map(\.stringValue).joined(separator: ".")
        return path.isEmpty ? "<root>" : path
    }
}
