import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    var body: some View {
        ZStack {
            Group {
                switch vm.currentScreen {
                case .welcome:
                    WelcomeView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                case .personalDetails:
                    PersonalDetailsView()
                        .transition(screenTransition)
                case .education:
                    EducationView()
                        .transition(screenTransition)
                case .workExperience:
                    WorkExperienceView()
                        .transition(screenTransition)
                case .positionAvailability:
                    PositionAvailabilityView()
                        .transition(screenTransition)
                case .declaration:
                    DeclarationConsentView()
                        .transition(screenTransition)
                case .confirmation:
                    ConfirmationView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                case .admin:
                    AdminPanelView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: vm.currentScreen)

            if vm.showIdleWarning {
                IdleTimerOverlay()
            }

            if vm.isSubmitting {
                submissionOverlay
            }
        }
        .ignoresSafeArea()
        .onTapGesture {
            vm.resetIdleTimer()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in vm.resetIdleTimer() }
        )
    }

    private var screenTransition: AnyTransition {
        if vm.navigatingForward {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            )
        } else {
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .opacity
            )
        }
    }

    private var submissionOverlay: some View {
        ZStack {
            Color.vkaPurple.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                BrandedSpinner()
                Text("Submitting your application...")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(.white)
            }
        }
    }
}
