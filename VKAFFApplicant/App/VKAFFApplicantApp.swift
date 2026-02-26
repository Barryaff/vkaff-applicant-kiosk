import SwiftUI

@main
struct VKAFFApplicantApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var registrationVM = RegistrationViewModel()
    @Environment(\.scenePhase) private var scenePhase

    /// Tracks when the app last went to the background
    @State private var backgroundEntryDate: Date?

    /// Threshold for auto-reset when app returns from background mid-form (5 minutes)
    private let backgroundResetThreshold: TimeInterval = 300

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(registrationVM)
                .preferredColorScheme(.light)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .onOpenURL { _ in
                    // Intentionally ignore deep links to prevent breaking kiosk mode
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Re-enable idle sleep prevention
            UIApplication.shared.isIdleTimerDisabled = true

            // Check if we need to reset due to extended background time
            if let bgDate = backgroundEntryDate {
                let elapsed = Date().timeIntervalSince(bgDate)
                backgroundEntryDate = nil

                if elapsed >= backgroundResetThreshold && !registrationVM.isOnWelcomeScreen {
                    // User was mid-form and app was backgrounded for >5 minutes — reset
                    registrationVM.resetToWelcome()
                }
            }

        case .inactive:
            // App is transitioning (e.g., notification center pulled down) — no action needed
            break

        case .background:
            backgroundEntryDate = Date()

        @unknown default:
            break
        }
    }
}
