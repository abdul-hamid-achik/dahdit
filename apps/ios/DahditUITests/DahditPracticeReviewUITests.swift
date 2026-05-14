import Foundation
import XCTest

final class DahditPracticeReviewUITests: XCTestCase {
    @MainActor
    func testCompletesSeededPracticeReview() async throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-auth", "--ui-testing"]
        app.launch()

        let username = signUp(app)
        try await Self.seedDueReview(username: username)

        let practiceTab = app.tabBars.buttons["Practice"]
        XCTAssertTrue(practiceTab.waitForExistence(timeout: 8))
        practiceTab.tap()

        let startButton = app.buttons["practice.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12))
        startButton.tap()

        let playButton = app.buttons["practice.play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 8))
        playButton.tap()

        let answerField = app.textFields["practice.answer"]
        XCTAssertTrue(answerField.waitForExistence(timeout: 8))
        answerField.tap()
        answerField.typeText("E")
        dismissKeyboard(app)

        app.buttons["practice.check"].tap()
        XCTAssertTrue(app.buttons["practice.grade.good"].waitForExistence(timeout: 8))
        app.buttons["practice.grade.good"].tap()
        app.buttons["practice.finish"].tap()

        XCTAssertTrue(app.staticTexts["Review saved"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["practice.back"].waitForExistence(timeout: 8))
    }

    @MainActor
    private func signUp(_ app: XCUIApplication) -> String {
        let nonce = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(10)).lowercased()
        let email = "ui_\(nonce)@example.com"
        let username = "ui_\(nonce)"

        let emailField = app.textFields["auth.email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 8))
        emailField.tap()
        emailField.typeText(email)

        let usernameField = app.textFields["auth.username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
        usernameField.tap()
        usernameField.typeText(username)

        let passwordField = app.secureTextFields["auth.password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2))
        passwordField.tap()
        passwordField.typeText("password123")

        dismissKeyboard(app)
        app.buttons["auth.submit"].tap()

        if app.buttons["Not Now"].waitForExistence(timeout: 2) {
            app.buttons["Not Now"].tap()
        }

        XCTAssertTrue(app.scrollViews["home.screen"].waitForExistence(timeout: 15))
        dismissSystemPrompts(app)
        return username
    }

    private static func seedDueReview(username: String) async throws {
        let url = try XCTUnwrap(URL(string: "http://localhost:4000/__test/seed-review"))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "username": username,
            "cardKey": "char:E",
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        XCTAssertEqual(statusCode, 200, responseBody)
    }

    @MainActor
    private func dismissKeyboard(_ app: XCUIApplication) {
        if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        } else if app.keyboards.buttons["done"].exists {
            app.keyboards.buttons["done"].tap()
        } else if app.keyboards.buttons["go"].exists {
            app.keyboards.buttons["go"].tap()
        }
    }

    @MainActor
    private func dismissSystemPrompts(_ app: XCUIApplication) {
        for _ in 0..<6 {
            if app.buttons["Not Now"].exists {
                app.buttons["Not Now"].tap()
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
    }
}
