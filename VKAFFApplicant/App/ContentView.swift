import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    /// Tracks keyboard visibility for idle timer resets
    @State private var keyboardCancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            Group {
                switch vm.currentScreen {
                case .welcome:
                    WelcomeView()
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.easeOut(duration: 0.3)),
                            removal: .opacity.animation(.easeIn(duration: 0.2))
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
                            insertion: .opacity.animation(.easeOut(duration: 0.3)),
                            removal: .opacity.animation(.easeIn(duration: 0.2))
                        ))
                case .admin:
                    AdminPanelView()
                        .transition(.opacity)
                }
            }
            .animation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.35), value: vm.currentScreen)

            if vm.showIdleWarning {
                IdleTimerOverlay()
            }

            if vm.isSubmitting {
                submissionOverlay
            }
        }
        .ignoresSafeArea()
        // Block swipe-back edge gesture by consuming leading-edge drags
        .gesture(
            DragGesture()
                .onChanged { _ in vm.resetIdleTimer() },
            including: .all
        )
        .onTapGesture {
            vm.resetIdleTimer()
        }
        .onAppear {
            setupKeyboardObservers()
        }
    }

    // MARK: - Keyboard Observers

    /// Subscribe to keyboard show/hide notifications to reset idle timer
    /// when the user interacts with text fields
    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                vm.resetIdleTimer()
            }
            .store(in: &keyboardCancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                vm.resetIdleTimer()
            }
            .store(in: &keyboardCancellables)
    }

    // MARK: - Transitions

    private var screenTransition: AnyTransition {
        if vm.navigatingForward {
            return .asymmetric(
                insertion: .modifier(
                    active: SlideOffsetModifier(offsetX: 60, opacity: 0),
                    identity: SlideOffsetModifier(offsetX: 0, opacity: 1)
                ),
                removal: .opacity.animation(.easeIn(duration: 0.2))
            )
        } else {
            return .asymmetric(
                insertion: .modifier(
                    active: SlideOffsetModifier(offsetX: -60, opacity: 0),
                    identity: SlideOffsetModifier(offsetX: 0, opacity: 1)
                ),
                removal: .opacity.animation(.easeIn(duration: 0.2))
            )
        }
    }

    private var submissionOverlay: some View {
        ZStack {
            Color.navy.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                BrandedSpinner()
                Text("Submitting your application...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Submitting your application. Please wait.")
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Custom slide + fade modifier for premium feel

struct SlideOffsetModifier: ViewModifier {
    let offsetX: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX)
            .opacity(opacity)
    }
}
