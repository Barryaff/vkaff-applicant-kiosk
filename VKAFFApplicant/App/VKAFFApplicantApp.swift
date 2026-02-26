import SwiftUI

@main
struct VKAFFApplicantApp: App {
    @StateObject private var registrationVM = RegistrationViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(registrationVM)
                .preferredColorScheme(.light)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}
