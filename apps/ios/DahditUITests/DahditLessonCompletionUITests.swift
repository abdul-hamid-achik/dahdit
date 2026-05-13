import XCTest

final class DahditLessonCompletionUITests: XCTestCase {
    @MainActor
    func testCompletesFirstSignalsLesson() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-auth", "--ui-testing"]
        app.launch()

        signUp(app)

        let firstLesson = app.buttons["lesson.First Signals"]
        XCTAssertTrue(firstLesson.waitForExistence(timeout: 8))
        firstLesson.tap()

        XCTAssertTrue(app.buttons["exercise.choice.0"].waitForExistence(timeout: 12))
        app.buttons["exercise.choice.0"].tap()

        let listenAnswer = app.textFields["exercise.listen.answer"]
        XCTAssertTrue(listenAnswer.waitForExistence(timeout: 8))
        listenAnswer.tap()
        listenAnswer.typeText("ET")
        dismissKeyboard(app)
        app.buttons["exercise.listen.submit"].tap()

        XCTAssertTrue(app.buttons["exercise.tap.dit"].waitForExistence(timeout: 8))
        app.buttons["exercise.tap.dit"].tap()
        app.buttons["exercise.tap.dah"].tap()
        app.buttons["exercise.tap.submit"].tap()

        XCTAssertTrue(app.buttons["exercise.translate.dit"].waitForExistence(timeout: 8))
        tapTranslateSOS(app)
        app.buttons["exercise.translate.submit"].tap()

        let copyAnswer = app.textFields["exercise.copy.answer"]
        XCTAssertTrue(copyAnswer.waitForExistence(timeout: 8))
        copyAnswer.tap()
        copyAnswer.typeText("CQ CQ DE DAHDIT")
        dismissKeyboard(app)
        app.buttons["exercise.copy.submit"].tap()

        XCTAssertTrue(app.staticTexts["Signal copied"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["lesson.complete.back"].waitForExistence(timeout: 8))
    }

    @MainActor
    private func signUp(_ app: XCUIApplication) {
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
    }

    @MainActor
    private func tapTranslateSOS(_ app: XCUIApplication) {
        for _ in 0..<3 { app.buttons["exercise.translate.dit"].tap() }
        app.buttons["exercise.translate.charGap"].tap()
        for _ in 0..<3 { app.buttons["exercise.translate.dah"].tap() }
        app.buttons["exercise.translate.charGap"].tap()
        for _ in 0..<3 { app.buttons["exercise.translate.dit"].tap() }
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
}
