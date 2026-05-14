import Foundation
import XCTest

final class DahditSignupSmokeUITests: XCTestCase {
    @MainActor
    func testSignupLoadsHomeWithApollo() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-auth", "--ui-testing"]
        app.launch()

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

        if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        } else if app.keyboards.buttons["go"].exists {
            app.keyboards.buttons["go"].tap()
        }
        app.buttons["auth.submit"].tap()

        if app.buttons["Not Now"].waitForExistence(timeout: 2) {
            app.buttons["Not Now"].tap()
        }

        XCTAssertTrue(app.scrollViews["home.screen"].waitForExistence(timeout: 15))
        dismissSystemPrompts(app)
        XCTAssertTrue(app.staticTexts["Foundations"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["First Signals"].waitForExistence(timeout: 8))
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
