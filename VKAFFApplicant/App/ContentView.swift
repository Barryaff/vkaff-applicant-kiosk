import SwiftUI
import Combine

struct ContentView: View {
    @Environment(RegistrationViewModel.self) var vm

    /// Tracks keyboard visibility for idle timer resets
    @State private var keyboardCancellables = Set<AnyCancellable>()

    /// Cycling status message shown during submission overlay
    @State private var submissionMessage: String = "Submitting your application..."

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
                case .supportingDocuments:
                    SupportingDocumentsView()
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
            // Note: screen transitions are handled by withAnimation in navigateForward/Back

            if vm.showIdleWarning {
                IdleTimerOverlay()
            }

            if vm.isSubmitting {
                submissionOverlay
            }
        }
        .ignoresSafeArea([.container, .keyboard], edges: .all)
        .alert("Submission Issue", isPresented: Binding(
            get: { vm.submissionError != nil },
            set: { if !$0 { vm.submissionError = nil } }
        )) {
            Button("Try Again") {
                vm.submissionError = nil
                vm.retrySubmission()
            }
            Button("OK", role: .cancel) {
                vm.submissionError = nil
            }
        } message: {
            Text(vm.submissionError ?? "")
        }
        // Reset idle timer on user interaction via UIKit touch detection.
        // Using a UIKit overlay instead of simultaneousGesture(TapGesture()) because
        // SwiftUI TapGesture adds ~300ms delay to UITextField first-responder resolution.
        .background(IdleResetTouchView { vm.resetIdleTimer() })
        .onAppear {
            setupKeyboardObservers()
        }
        .onChange(of: vm.isSubmitting) { _, isSubmitting in
            if isSubmitting {
                submissionMessage = "Submitting your application..."
                // Cycle messages for user reassurance
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    if vm.isSubmitting { submissionMessage = "Uploading documents..." }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 18) {
                    if vm.isSubmitting { submissionMessage = "Almost there..." }
                }
            } else {
                submissionMessage = "Submitting your application..."
            }
        }
    }

    // MARK: - Keyboard Observers

    /// Subscribe to keyboard show/hide notifications to reset idle timer
    /// when the user interacts with text fields
    private func setupKeyboardObservers() {
        keyboardCancellables.removeAll()

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { _ in
                vm.resetIdleTimer()
            }
            .store(in: &keyboardCancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
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
                Text(submissionMessage)
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

// MARK: - UIKit Touch Interceptor (zero-delay idle reset)

/// Detects touches via UIKit hit-test without adding a gesture recognizer.
/// Unlike SwiftUI's TapGesture, this has zero impact on UITextField responsiveness.
struct IdleResetTouchView: UIViewRepresentable {
    let onTouch: () -> Void

    func makeUIView(context: Context) -> TouchPassthroughView {
        let view = TouchPassthroughView()
        view.onTouch = onTouch
        return view
    }

    func updateUIView(_ uiView: TouchPassthroughView, context: Context) {
        uiView.onTouch = onTouch
    }
}

/// Transparent UIView that detects touches via hitTest but always returns nil
/// so touches pass through to the SwiftUI views underneath.
class TouchPassthroughView: UIView {
    var onTouch: (() -> Void)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Fire idle reset on every touch, then pass through
        if event?.type == .touches {
            DispatchQueue.main.async { [weak self] in
                self?.onTouch?()
            }
        }
        return nil // Always pass through — never captures the touch
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
