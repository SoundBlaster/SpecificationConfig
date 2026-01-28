import Foundation
@testable import SpecificationConfig
import XCTest

final class ConfigFileWatcherTests: XCTestCase {
    private var tempFileURL: URL!

    override func setUp() {
        super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        tempFileURL = tempDir.appendingPathComponent("config_watcher_test_\(UUID().uuidString).json")
        FileManager.default.createFile(
            atPath: tempFileURL.path,
            contents: Data("{\"key\":\"value\"}".utf8),
            attributes: nil
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }

    func testStartAndDetectChange() async throws {
        let watcher = ConfigFileWatcher(fileURL: tempFileURL, pollInterval: .milliseconds(50))
        let expectation = XCTestExpectation(description: "onChange called")

        await watcher.start {
            expectation.fulfill()
        }

        // Wait a bit then modify the file
        try await Task.sleep(for: .milliseconds(100))
        try Data("{\"key\":\"updated\"}".utf8).write(to: tempFileURL)

        await fulfillment(of: [expectation], timeout: 2.0)
        await watcher.stop()
    }

    func testNoCallbackWithoutChange() async {
        let watcher = ConfigFileWatcher(fileURL: tempFileURL, pollInterval: .milliseconds(50))
        let expectation = XCTestExpectation(description: "onChange should not be called")
        expectation.isInverted = true

        await watcher.start {
            expectation.fulfill()
        }

        // Wait without modifying the file
        await fulfillment(of: [expectation], timeout: 0.3)
        await watcher.stop()
    }

    func testStopPreventsCallback() async throws {
        let watcher = ConfigFileWatcher(fileURL: tempFileURL, pollInterval: .milliseconds(50))
        let expectation = XCTestExpectation(description: "onChange should not fire after stop")
        expectation.isInverted = true

        await watcher.start {
            expectation.fulfill()
        }

        await watcher.stop()

        // Modify the file after stopping
        try await Task.sleep(for: .milliseconds(100))
        try Data("{\"key\":\"modified\"}".utf8).write(to: tempFileURL)

        await fulfillment(of: [expectation], timeout: 0.3)
    }

    func testIsWatchingProperty() async {
        let watcher = ConfigFileWatcher(fileURL: tempFileURL, pollInterval: .milliseconds(50))

        let beforeStart = await watcher.isWatching
        XCTAssertFalse(beforeStart)

        await watcher.start {}

        let duringWatch = await watcher.isWatching
        XCTAssertTrue(duringWatch)

        await watcher.stop()

        let afterStop = await watcher.isWatching
        XCTAssertFalse(afterStop)
    }

    func testMultipleChangesDetected() async throws {
        let watcher = ConfigFileWatcher(fileURL: tempFileURL, pollInterval: .milliseconds(50))
        let counter = ChangeCounter()

        await watcher.start {
            await counter.increment()
        }

        // Modify the file multiple times with enough delay between changes
        for i in 1 ... 3 {
            try await Task.sleep(for: .milliseconds(100))
            try Data("{\"key\":\"v\(i)\"}".utf8).write(to: tempFileURL)
        }

        // Wait for all changes to be detected
        try await Task.sleep(for: .milliseconds(300))

        let count = await counter.count
        XCTAssertGreaterThanOrEqual(count, 2, "Expected at least 2 change detections, got \(count)")
        await watcher.stop()
    }

    func testRestartWatching() async throws {
        let watcher = ConfigFileWatcher(fileURL: tempFileURL, pollInterval: .milliseconds(50))
        let expectation = XCTestExpectation(description: "onChange called after restart")

        // Start and stop
        await watcher.start {}
        await watcher.stop()

        // Restart with new callback
        await watcher.start {
            expectation.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))
        try Data("{\"key\":\"restarted\"}".utf8).write(to: tempFileURL)

        await fulfillment(of: [expectation], timeout: 2.0)
        await watcher.stop()
    }
}

/// Actor to safely count changes from concurrent callback invocations.
private actor ChangeCounter {
    var count = 0
    func increment() {
        count += 1
    }
}
