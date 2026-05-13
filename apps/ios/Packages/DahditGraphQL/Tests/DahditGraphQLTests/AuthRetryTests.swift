import Foundation
@testable import DahditGraphQL
import Testing

@Suite("Auth retry")
struct AuthRetryTests {
    @Test func retriesOperationOnceAfterRefresh() async throws {
        MockURLProtocol.reset(responses: [
            MockHTTPResponse(
                statusCode: 200,
                body: #"{"errors":[{"message":"Unauthenticated"}],"data":null}"#
            ),
            MockHTTPResponse(
                statusCode: 200,
                body: """
                {
                  "data": {
                    "me": {
                      "__typename": "User",
                      "id": "user-1",
                      "email": "retry@example.com",
                      "username": "retry_user",
                      "tz": "UTC",
                      "stats": {
                        "__typename": "UserStats",
                        "xpTotal": 0,
                        "streakDays": 0,
                        "hearts": 5,
                        "heartsRefillAt": null
                      }
                    }
                  }
                }
                """
            ),
        ])

        let tokenBox = TokenBox("expired-token")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let api = DahditAPI(
            endpoint: URL(string: "https://api.test/graphql")!,
            tokenProvider: { await tokenBox.current() },
            tokenRefreshHandler: {
                await tokenBox.set("fresh-token")
                return true
            },
            session: session
        )

        let user = try await api.me()

        #expect(user?.username == "retry_user")
        #expect(MockURLProtocol.authorizationHeaders() == [
            "Bearer expired-token",
            "Bearer fresh-token",
        ])
    }
}

private actor TokenBox {
    private var token: String

    init(_ token: String) {
        self.token = token
    }

    func current() -> String {
        token
    }

    func set(_ token: String) {
        self.token = token
    }
}

private struct MockHTTPResponse: Sendable {
    let statusCode: Int
    let body: String
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) private static var responses: [MockHTTPResponse] = []
    nonisolated(unsafe) private static var seenRequests: [URLRequest] = []

    static func reset(responses: [MockHTTPResponse]) {
        self.responses = responses
        seenRequests = []
    }

    static func authorizationHeaders() -> [String] {
        seenRequests.compactMap { $0.value(forHTTPHeaderField: "Authorization") }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.seenRequests.append(request)

        guard !Self.responses.isEmpty else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let response = Self.responses.removeFirst()
        let httpResponse = HTTPURLResponse(
            url: request.url ?? URL(string: "https://api.test/graphql")!,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: ["content-type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(response.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
