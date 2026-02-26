import XCTest
@testable import VKAFFApplicant

@MainActor
final class IdleTimerTests: XCTestCase {

    // MARK: - Reset Cancels Pending Timers

    func testResetActivityCancelsPendingTimersAndReschedules() {
        let resetCalled = XCTestExpectation(description: "Reset callback should NOT be called")
        resetCalled.isInverted = true

        let timer = IdleTimer {
            resetCalled.fulfill()
        }

        timer.start()

        // Continuously reset activity to prevent the warning from ever firing
        for i in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                timer.resetActivity()
            }
        }

        // Wait a bit; the reset callback should NOT be called since we kept resetting
        wait(for: [resetCalled], timeout: 2.0)

        timer.stop()
    }

    func testResetActivityDismissesWarningIfShown() {
        let timer = IdleTimer { }
        timer.start()

        // Manually set warning state to simulate it being shown
        timer.isWarningShown = true

        timer.resetActivity()

        XCTAssertFalse(timer.isWarningShown, "Warning should be dismissed after resetActivity")

        timer.stop()
    }

    // MARK: - Stop Prevents Callbacks

    func testStopPreventsResetCallback() {
        let resetCalled = XCTestExpectation(description: "Reset callback should NOT be called after stop")
        resetCalled.isInverted = true

        let timer = IdleTimer {
            resetCalled.fulfill()
        }

        timer.start()
        timer.stop()

        // Wait well past any potential timer fire
        wait(for: [resetCalled], timeout: 2.0)
    }

    func testStopSetsInactiveState() {
        let timer = IdleTimer { }
        timer.start()
        timer.stop()

        // After stop, resetActivity should be a no-op (guard !isActive)
        timer.isWarningShown = true
        timer.resetActivity()
        // Since isActive is false after stop, resetActivity should not change isWarningShown
        XCTAssertTrue(timer.isWarningShown,
                      "resetActivity should be a no-op when timer is stopped")

        timer.stop()
    }

    func testDoubleStartDoesNotCreateDuplicateTimers() {
        let resetCount = XCTestExpectation(description: "Should not get called")
        resetCount.isInverted = true

        let timer = IdleTimer {
            resetCount.fulfill()
        }

        timer.start()
        timer.start()  // Second start should be ignored
        timer.stop()

        wait(for: [resetCount], timeout: 1.0)
    }

    // MARK: - userConfirmedPresence Resets the Cycle

    func testUserConfirmedPresenceResetsWarningState() {
        let timer = IdleTimer { }
        timer.start()

        // Simulate warning being shown
        timer.isWarningShown = true
        timer.secondsRemaining = 10

        timer.userConfirmedPresence()

        XCTAssertFalse(timer.isWarningShown,
                       "Warning should be dismissed after user confirmed presence")

        timer.stop()
    }

    func testUserConfirmedPresenceDoesNotTriggerReset() {
        let resetCalled = XCTestExpectation(description: "Reset should NOT be called after confirm")
        resetCalled.isInverted = true

        let timer = IdleTimer {
            resetCalled.fulfill()
        }

        timer.start()
        timer.isWarningShown = true

        timer.userConfirmedPresence()

        // Wait; reset should not fire
        wait(for: [resetCalled], timeout: 2.0)

        timer.stop()
    }

    // MARK: - Initial State

    func testInitialState() {
        let timer = IdleTimer { }

        XCTAssertFalse(timer.isWarningShown)
        XCTAssertEqual(timer.secondsRemaining, 30)
    }

    // MARK: - Stop Clears Warning

    func testStopClearsWarningTimers() {
        let timer = IdleTimer { }
        timer.start()
        timer.isWarningShown = true

        timer.stop()

        // After stop, the countdown timer should be invalidated
        // We verify indirectly: after stop, calling start again should work cleanly
        timer.start()
        XCTAssertTrue(timer.isWarningShown,
                      "isWarningShown was set before stop; stop does not reset it directly")
        timer.stop()
    }
}
