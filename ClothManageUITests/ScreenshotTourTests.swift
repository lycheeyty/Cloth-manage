import XCTest

/// 截图巡游：自动走完主要页面并截图（浅色 + 深色各一轮），
/// 截图作为测试附件导出，由 CI 收集
final class ScreenshotTourTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testTourLight() throws {
        runTour(appearance: "light")
    }

    func testTourDark() throws {
        runTour(appearance: "dark")
    }

    private func runTour(appearance: String) {
        let flag = appearance == "dark" ? "--force-dark" : "--force-light"

        // ---- 第 1 段：空状态 ----
        var app = XCUIApplication()
        app.launchArguments = ["--wipe-data", flag]
        app.launch()
        pause(2)
        snap(app, "01-衣橱-空状态-\(appearance)")
        app.tabBars.buttons["添加"].tap()
        pause(1)
        snap(app, "02-添加-入口-\(appearance)")
        app.terminate()

        // ---- 第 2 段：有数据主流程 ----
        app = XCUIApplication()
        app.launchArguments = ["--seed-demo", flag]
        app.launch()
        pause(3)
        snap(app, "03-衣橱-混排列表-\(appearance)")

        tapIfExists(app.buttons["上装"].firstMatch)
        pause(1)
        snap(app, "04-衣橱-筛选上装-\(appearance)")

        tapIfExists(app.buttons["组合"].firstMatch)
        pause(1)
        snap(app, "05-衣橱-组合筛选-\(appearance)")

        tapIfExists(app.staticTexts["初秋通勤"].firstMatch)
        pause(1)
        snap(app, "06-组合-详情-\(appearance)")
        goBack(app)
        pause(1)

        tapIfExists(app.buttons["全部"].firstMatch)
        pause(1)
        tapIfExists(app.staticTexts["白色针织开衫"].firstMatch)
        pause(1)
        snap(app, "07-单品-详情-\(appearance)")
        goBack(app)
        pause(1)

        tapIfExists(app.buttons["创建组合"].firstMatch)
        pause(1)
        tapIfExists(app.staticTexts["白色针织开衫"].firstMatch)
        tapIfExists(app.staticTexts["直筒牛仔裤"].firstMatch)
        pause(1)
        snap(app, "08-组合-多选模式-\(appearance)")

        tapIfExists(app.buttons["下一步"].firstMatch)
        pause(1)
        snap(app, "09-组合-发布页-\(appearance)")
        tapIfExists(app.buttons["取消"].firstMatch)
        pause(1)

        app.tabBars.buttons["我的"].tap()
        pause(1)
        snap(app, "10-我的-\(appearance)")
        tapIfExists(app.staticTexts["衣橱会员"].firstMatch)
        pause(1)
        snap(app, "11-订阅页-\(appearance)")
        app.terminate()

        // ---- 第 3 段：发布确认页 ----
        app = XCUIApplication()
        app.launchArguments = ["--seed-demo", "--seed-drafts", flag]
        app.launch()
        pause(2)
        app.tabBars.buttons["添加"].tap()
        pause(2)
        snap(app, "12-发布-确认页-\(appearance)")
        app.terminate()
    }

    // MARK: - 工具

    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tapIfExists(_ element: XCUIElement) {
        if element.waitForExistence(timeout: 3), element.isHittable {
            element.tap()
        }
    }

    private func goBack(_ app: XCUIApplication) {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.waitForExistence(timeout: 3) {
            back.tap()
        }
    }

    private func pause(_ seconds: UInt32) {
        sleep(seconds)
    }
}
