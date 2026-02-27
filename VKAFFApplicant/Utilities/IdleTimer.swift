import Foundation
import UIKit
import Combine
import os

@MainActor
class IdleTimer: ObservableObject {
    @Published var isWarningShown = false
    @Published var secondsRemaining: Int = 30

    private var warningTimer: Timer?
    private var resetTimer: Timer?
    private var countdownTimer: Timer?
    private var onReset: (() -> Void)?
    private var isActive = false
    private var isPaused = false
    private var backgroundEntryDate: Date?
    private var elapsedBeforeBackground: TimeInterval = 0
    private var warningScheduledDate: Date?
    private var lastResetDate: Date = .distantPast

    private let logger = Logger(subsystem: "com.vkaff.applicant-kiosk", category: "IdleTimer")

    init(onReset: @escaping () -> Void) {
        self.onReset = onReset
        setupBackgroundObservers()
    }

    // MARK: - Public API

    func start() {
        guard !isActive else {
            logger.debug("start() called but timer already active — ignoring")
            return
        }
        isActive = true
        isPaused = false
        logger.info("Idle timer started (warning at \(AppConfig.idleWarningSeconds)s, reset at \(AppConfig.idleResetSeconds)s)")
        scheduleWarning()
    }

    func stop() {
        logger.info("Idle timer stopped")
        isActive = false
        isPaused = false
        elapsedBeforeBackground = 0
        warningScheduledDate = nil
        cancelAll()
    }

    func pause() {
        guard isActive, !isPaused else { return }
        isPaused = true
        logger.info("Idle timer paused (admin panel or overlay)")
        cancelAll()
    }

    func resume() {
        guard isActive, isPaused else { return }
        isPaused = false
        logger.info("Idle timer resumed")
        isWarningShown = false
        scheduleWarning()
    }

    func resetActivity() {
        guard isActive, !isPaused else { return }

        // Throttle: ignore resets within 2 seconds of each other to avoid
        // timer churn from gestures/keyboard events firing per-frame
        let now = Date()
        guard now.timeIntervalSince(lastResetDate) > 2.0 else { return }
        lastResetDate = now

        logger.debug("Activity detected — resetting idle timer")

        if isWarningShown {
            isWarningShown = false
        }

        elapsedBeforeBackground = 0
        cancelAll()
        scheduleWarning()
    }

    func userConfirmedPresence() {
        logger.info("User confirmed presence — resetting idle countdown")
        isWarningShown = false
        elapsedBeforeBackground = 0
        cancelAll()
        scheduleWarning()
    }

    // MARK: - Background / Foreground Handling

    private func setupBackgroundObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleDidEnterBackground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWillEnterForeground()
            }
        }
    }

    private func handleDidEnterBackground() {
        guard isActive, !isPaused else { return }
        backgroundEntryDate = Date()

        // Calculate how much time has elapsed since the warning was scheduled
        if let scheduledDate = warningScheduledDate {
            elapsedBeforeBackground = Date().timeIntervalSince(scheduledDate)
        }

        logger.info("App entered background — elapsed since last activity: \(self.elapsedBeforeBackground, format: .fixed(precision: 1))s")
        cancelAll()
    }

    private func handleWillEnterForeground() {
        guard isActive, !isPaused else { return }

        guard let bgDate = backgroundEntryDate else {
            logger.warning("Entered foreground but no background date recorded — restarting timer")
            scheduleWarning()
            return
        }

        let totalBackgroundTime = Date().timeIntervalSince(bgDate)
        let totalElapsed = elapsedBeforeBackground + totalBackgroundTime
        backgroundEntryDate = nil

        logger.info("App returned to foreground — total idle time: \(totalElapsed, format: .fixed(precision: 1))s")

        if totalElapsed >= AppConfig.idleResetSeconds {
            // Past the reset threshold — trigger reset immediately
            logger.info("Idle time exceeded reset threshold — triggering reset")
            triggerReset()
        } else if totalElapsed >= AppConfig.idleWarningSeconds {
            // In the warning zone — show warning with remaining time
            let remaining = AppConfig.idleResetSeconds - totalElapsed
            logger.info("Idle time in warning zone — showing warning with \(remaining, format: .fixed(precision: 0))s remaining")
            showWarning(withRemaining: Int(remaining))
        } else {
            // Still within idle window — schedule warning for remaining time
            let remainingWarningTime = AppConfig.idleWarningSeconds - totalElapsed
            logger.info("Resuming with \(remainingWarningTime, format: .fixed(precision: 1))s until warning")
            scheduleWarning(afterDelay: remainingWarningTime)
        }

        elapsedBeforeBackground = 0
    }

    // MARK: - Private

    private func scheduleWarning(afterDelay delay: TimeInterval? = nil) {
        let interval = delay ?? AppConfig.idleWarningSeconds
        warningScheduledDate = Date()

        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.showWarning()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        warningTimer = timer

        logger.debug("Warning timer scheduled for \(interval, format: .fixed(precision: 1))s from now")
    }

    private func showWarning(withRemaining remaining: Int? = nil) {
        isWarningShown = true
        secondsRemaining = remaining ?? Int(AppConfig.idleResetSeconds - AppConfig.idleWarningSeconds)

        logger.info("Showing idle warning — \(self.secondsRemaining)s until reset")

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.secondsRemaining -= 1
                if self.secondsRemaining <= 0 {
                    self.triggerReset()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    private func triggerReset() {
        logger.info("Idle timeout reached — triggering session reset")
        cancelAll()
        isWarningShown = false
        elapsedBeforeBackground = 0
        warningScheduledDate = nil
        onReset?()
    }

    private func cancelAll() {
        warningTimer?.invalidate()
        warningTimer = nil
        resetTimer?.invalidate()
        resetTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    deinit {
        // Note: Cannot call cancelAll() here because deinit is nonisolated
        // Timers will be invalidated when their references are released
        warningTimer?.invalidate()
        resetTimer?.invalidate()
        countdownTimer?.invalidate()
    }
}
