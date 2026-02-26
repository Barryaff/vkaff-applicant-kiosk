import Foundation
import Combine

class IdleTimer: ObservableObject {
    @Published var isWarningShown = false
    @Published var secondsRemaining: Int = 30

    private var warningTimer: Timer?
    private var resetTimer: Timer?
    private var countdownTimer: Timer?
    private var onReset: (() -> Void)?
    private var isActive = false

    init(onReset: @escaping () -> Void) {
        self.onReset = onReset
    }

    func start() {
        guard !isActive else { return }
        isActive = true
        scheduleWarning()
    }

    func stop() {
        isActive = false
        cancelAll()
    }

    func resetActivity() {
        guard isActive else { return }

        if isWarningShown {
            isWarningShown = false
        }

        cancelAll()
        scheduleWarning()
    }

    func userConfirmedPresence() {
        isWarningShown = false
        cancelAll()
        scheduleWarning()
    }

    // MARK: - Private

    private func scheduleWarning() {
        warningTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.idleWarningSeconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.showWarning()
            }
        }
    }

    private func showWarning() {
        isWarningShown = true
        secondsRemaining = Int(AppConfig.idleResetSeconds - AppConfig.idleWarningSeconds)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.secondsRemaining -= 1
                if self.secondsRemaining <= 0 {
                    self.triggerReset()
                }
            }
        }
    }

    private func triggerReset() {
        cancelAll()
        isWarningShown = false
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
        cancelAll()
    }
}
