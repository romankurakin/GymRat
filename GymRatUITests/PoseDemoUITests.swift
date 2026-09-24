import XCTest

final class PoseDemoUITests: XCTestCase {
    @MainActor
    func testSamplePhotoShowsRealSkeleton() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.buttons["settingsButton"].tap()
        let link = app.buttons["poseDemoLink"]
        for _ in 0..<5 {
            if link.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        app.buttons["poseSampleButton"].tap()
        let status = app.staticTexts["poseStatus"]
        let found = NSPredicate(format: "label == %@", "Found 33 body landmarks")
        expectation(for: found, evaluatedWith: status)
        waitForExpectations(timeout: 30)
        let overlay = app.otherElements["poseSkeletonOverlay"]
        XCTAssertTrue(overlay.exists)
        XCTAssertEqual(overlay.value as? String, "33")
        XCTAssertTrue(app.buttons["posePhotoPicker"].isEnabled)
    }
}
