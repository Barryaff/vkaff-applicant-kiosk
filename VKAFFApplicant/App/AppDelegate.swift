import UIKit
import os

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.vkaff.applicant-kiosk", category: "AppDelegate")

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("VKAFF Kiosk app launched")

        // Prevent device from sleeping while the kiosk app is active
        application.isIdleTimerDisabled = true

        // Disable multitouch globally — only single-finger interactions allowed
        // This prevents accidental multi-finger gestures that could interfere with kiosk mode
        disableMultitouch()

        // Monitor for screenshot and screen recording events
        setupScreenCaptureObservers()

        // Pre-warm the keyboard so it appears instantly on first text field tap
        preWarmKeyboard()

        return true
    }

    // MARK: - Orientation Lock

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Allow all orientations — the iPad can be mounted in any orientation in a kiosk stand
        // Change to .portrait if you want to lock to portrait only
        return .all
    }

    // MARK: - Multitouch Prevention

    /// Disables multitouch on all existing and future windows to ensure
    /// only single-finger interactions are recognized
    private func disableMultitouch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                self?.logger.warning("No window scene found — multitouch disable deferred")
                return
            }
            for window in scene.windows {
                window.isMultipleTouchEnabled = false
                self?.disableMultitouchRecursively(in: window)
            }
            self?.logger.info("Multitouch disabled on all windows")
        }
    }

    private func disableMultitouchRecursively(in view: UIView) {
        view.isMultipleTouchEnabled = false
        for subview in view.subviews {
            disableMultitouchRecursively(in: subview)
        }
    }

    // MARK: - Keyboard Pre-warming

    /// Forces iOS to load the keyboard process at launch so it appears
    /// instantly when the user first taps a text field.
    private func preWarmKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return }

            let tf = UITextField(frame: CGRect(x: -100, y: -100, width: 1, height: 1))
            tf.autocorrectionType = .no
            tf.autocapitalizationType = .none
            tf.spellCheckingType = .no
            window.addSubview(tf)
            tf.becomeFirstResponder()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tf.resignFirstResponder()
                tf.removeFromSuperview()
            }
        }
    }

    // MARK: - Screen Capture Monitoring

    /// Logs screenshot and screen recording events for audit purposes
    private func setupScreenCaptureObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.warning("Screenshot taken on kiosk device")
        }

        // Monitor screen recording state changes
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let isCaptured = (notification.object as? UIScreen)?.isCaptured ?? false
            if isCaptured {
                self?.logger.warning("Screen recording started on kiosk device")
            } else {
                self?.logger.info("Screen recording stopped")
            }
        }
    }
}
