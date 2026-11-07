import XCTest

/// Walks the real app through its main flows. Screenshots are attached to the test results.
@MainActor
final class CalculatorFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    private func launch(premium: Bool, keepState: Bool = false, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES", "-useMetric", "NO"] + extraArguments
        if !keepState {
            app.launchArguments.append("-resetState")
        }
        if premium {
            app.launchArguments += ["-debugPremium", "-seedSampleLifts"]
        }
        app.launch()
        return app
    }
    
    private func screenshot(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    private func replaceText(in field: XCUIElement, with text: String, app: XCUIApplication) {
        // Values persist between launches, so tap near the right end to put the caret after
        // them, staying inside any padding around the editable area
        let width = max(field.frame.width, 1)
        field.coordinate(withNormalizedOffset: CGVector(dx: max(0.5, (width - 14) / width), dy: 0.5)).tap()
        if let current = field.value as? String, !current.isEmpty, current != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }
    
    private func dismissKeyboard(_ app: XCUIApplication) {
        let done = app.toolbars.buttons["Done"]
        if done.waitForExistence(timeout: 2) {
            done.tap()
        }
    }
    
    private func openCard(_ title: String, _ app: XCUIApplication) {
        let card = app.staticTexts[title].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5), title)
        var swipes = 0
        while !card.isHittable && swipes < 4 {
            app.swipeUp()
            swipes += 1
        }
        card.tap()
    }
    
    func testFreeUserHitsThePaywallForTheRightFeature() {
        let app = launch(premium: false)
        screenshot("free-home", app)
        openCard("Warm-up Generator", app)
        XCTAssertTrue(app.staticTexts["Unlock Premium"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Warm-up Generator"].exists)
        screenshot("free-paywall", app)
    }
    
    func testPremiumPlateCalculatorUsesStandardPlates() {
        let app = launch(premium: true)
        openCard("Plate Calculator", app)
        
        let field = app.textFields["Total Weight"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        replaceText(in: field, with: "225", app: app)
        dismissKeyboard(app)
        
        let barbell = app.descendants(matching: .any)["Barbell loaded per side with 45, 45 pounds"]
        XCTAssertTrue(barbell.waitForExistence(timeout: 5))
        screenshot("premium-plate-225", app)
    }
    
    func testOneRepMaxHandsOffToTheRPECalculator() {
        let app = launch(premium: true)
        openCard("One-Rep Max", app)
        
        let fields = app.textFields
        XCTAssertTrue(fields.firstMatch.waitForExistence(timeout: 5))
        replaceText(in: fields.element(boundBy: 0), with: "225", app: app)
        replaceText(in: fields.element(boundBy: 1), with: "5", app: app)
        dismissKeyboard(app)
        screenshot("one-rep-max", app)
        
        app.buttons["Save to My Lifts"].tap()
        app.buttons["Squat"].tap()
        // Below the seeded best of 366 lb, so it saves without calling a PR
        XCTAssertTrue(app.buttons["Saved to Squat"].waitForExistence(timeout: 5))
        screenshot("saved-set", app)
        
        app.buttons["Share"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5) || app.navigationBars["UIActivityContentView"].waitForExistence(timeout: 5))
        screenshot("share-sheet", app)
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Use in RPE"].waitForExistence(timeout: 5))
        
        app.staticTexts["Use in RPE"].tap()
        XCTAssertTrue(app.navigationBars["RPE Calculator"].waitForExistence(timeout: 5))
        let e1rm = app.textFields.firstMatch
        XCTAssertTrue(e1rm.waitForExistence(timeout: 5))
        XCTAssertNotEqual(e1rm.value as? String, "Enter E1RM")
        screenshot("rpe-from-handoff", app)
        
        app.swipeUp()
        screenshot("rpe-grid", app)
    }
    
    func testWarmupsListEachLoad() {
        let app = launch(premium: true)
        openCard("Warm-up Generator", app)
        
        let field = app.textFields["Top Set Weight"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        replaceText(in: field, with: "315", app: app)
        dismissKeyboard(app)
        
        XCTAssertTrue(app.staticTexts["Top set"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["3 × 45 per side"].exists)
        screenshot("warmups", app)
    }
    
    func testInputsSurviveARelaunch() {
        var app = launch(premium: false)
        openCard("Training Max", app)
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        replaceText(in: field, with: "405", app: app)
        dismissKeyboard(app)
        app.terminate()
        
        app = launch(premium: false, keepState: true)
        openCard("Training Max", app)
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields.firstMatch.value as? String, "405")
    }
    
    func testFreeUserGetsClosestLoadsAndAnUpgradePath() {
        let app = launch(premium: false)
        openCard("Plate Calculator", app)
        let field = app.textFields["Total Weight"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        replaceText(in: field, with: "137.5", app: app)
        dismissKeyboard(app)
        
        XCTAssertTrue(app.buttons["Below: 135 lb"].waitForExistence(timeout: 5))
        let above = app.buttons["Above: 140 lb"]
        XCTAssertTrue(above.exists)
        screenshot("free-plate-closest", app)
        
        app.buttons["Upgrade to Premium for 1.25 lb change plates"].tap()
        XCTAssertTrue(app.staticTexts["Unlock Premium"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Extended Equipment"].exists)
    }
    
    func testGymProfilesAndDecimalCollarWeight() {
        let app = launch(premium: true)
        app.buttons["Settings"].tap()
        
        XCTAssertTrue(app.buttons["Add Gym"].waitForExistence(timeout: 5))
        app.buttons["Add Gym"].tap()
        let name = app.alerts.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        let gymName = "Gym \(Int.random(in: 1000...9999))"
        name.typeText(gymName)
        app.alerts.buttons["Add"].tap()
        XCTAssertTrue(app.staticTexts[gymName].waitForExistence(timeout: 5))
        screenshot("gym-profiles", app)
        
        let collar = app.textFields["Collar weight"]
        // Drag it into the upper-middle of the sheet: clear of the bar and the keyboard
        var drags = 0
        while drags < 12 && (!collar.isHittable || collar.frame.midY > app.frame.height * 0.5) {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))
            start.press(forDuration: 0.05, thenDragTo: end)
            drags += 1
        }
        screenshot("collar-before-typing", app)
        replaceText(in: collar, with: "2.5", app: app)
        XCTAssertEqual(collar.value as? String, "2.5")
        dismissKeyboard(app)
        screenshot("collar-weight", app)
    }
    
    func testMyLiftsChartsHistory() {
        let app = launch(premium: true)
        openCard("My Lifts", app)
        screenshot("my-lifts", app)
        
        app.staticTexts["Squat"].tap()
        XCTAssertTrue(app.navigationBars["Squat"].waitForExistence(timeout: 5))
        screenshot("lift-detail", app)
        
        let warmups = app.staticTexts["Warm-ups"]
        XCTAssertTrue(warmups.waitForExistence(timeout: 5))
        warmups.tap()
        XCTAssertTrue(app.navigationBars["Warm-ups"].waitForExistence(timeout: 5))
    }
    
    func testBackoffAndMeetPlannerAndSettingsOpen() {
        let app = launch(premium: true)
        openCard("Back-off Sets", app)
        let top = app.textFields["Weight"]
        XCTAssertTrue(top.waitForExistence(timeout: 5))
        replaceText(in: top, with: "315", app: app)
        dismissKeyboard(app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Back-off Weight"].waitForExistence(timeout: 5))
        screenshot("backoff", app)
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
        openCard("Meet Planner", app)
        let squat = app.textFields["Squat"]
        XCTAssertTrue(squat.waitForExistence(timeout: 5))
        replaceText(in: squat, with: "405", app: app)
        replaceText(in: app.textFields["Bench"], with: "275", app: app)
        replaceText(in: app.textFields["Deadlift"], with: "495", app: app)
        dismissKeyboard(app)
        replaceText(in: app.textFields["Body Weight"], with: "198", app: app)
        dismissKeyboard(app)
        app.swipeUp()
        screenshot("meet-planner", app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Projected Totals"].waitForExistence(timeout: 5))
        screenshot("meet-planner-totals", app)
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Premium Active"].waitForExistence(timeout: 5))
        screenshot("settings-top", app)
        app.swipeUp()
        screenshot("settings-equipment", app)
    }
    
    func testLargeTextKeepsScreensUsable() {
        let app = launch(premium: true, extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        screenshot("large-text-home", app)
        openCard("Training Max", app)
        XCTAssertTrue(app.navigationBars["Training Max"].waitForExistence(timeout: 5))
        let field = app.textFields.firstMatch
        replaceText(in: field, with: "405", app: app)
        dismissKeyboard(app)
        app.swipeUp()
        screenshot("large-text-training-max", app)
    }
}
