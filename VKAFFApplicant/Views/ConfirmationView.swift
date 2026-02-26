import SwiftUI

struct ConfirmationView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @State private var countdownProgress: CGFloat = 1.0
    @State private var showConfetti: Bool = false
    @State private var showContent: Bool = false

    var body: some View {
        ZStack {
            // Deep navy background (matching welcome)
            Color.navy
                .ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [Color.navyLight.opacity(0.3), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated checkmark with confetti
                ZStack {
                    AnimatedCheckmark()

                    if showConfetti {
                        ConfettiParticlesView()
                    }
                }
                .padding(.bottom, 48)
                .accessibilityHidden(true)

                // Thank you message
                Text("Thank You, \(vm.applicant.preferredName.isEmpty ? vm.applicant.fullName : vm.applicant.preferredName)!")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 12)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("Thank You, \(vm.applicant.preferredName.isEmpty ? vm.applicant.fullName : vm.applicant.preferredName)!")

                Text("Your application has been received successfully.\nOur HR team will review and be in touch shortly.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.top, 16)
                    .padding(.horizontal, 64)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 8)
                    .accessibilityLabel("Your application has been received successfully. Our HR team will review and be in touch shortly.")

                // Reference number
                HStack(spacing: 8) {
                    Text("Reference")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gold.opacity(0.7))
                        .tracking(2)
                        .textCase(.uppercase)

                    Text(vm.applicant.referenceNumber)
                        .font(.system(size: 15, weight: .bold).monospacedDigit())
                        .foregroundColor(.gold)
                }
                .padding(.top, 28)
                .opacity(showContent ? 1 : 0)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Application Reference: \(vm.applicant.referenceNumber)")

                // Logos
                VStack(spacing: 16) {
                    Image("vka_logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                        .opacity(0.5)

                    Image("aff_logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .opacity(0.3)
                }
                .padding(.top, 56)
                .opacity(showContent ? 1 : 0)
                .accessibilityHidden(true)

                Spacer()

                // Done button with countdown ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                        .frame(width: 72, height: 72)
                        .accessibilityHidden(true)

                    Circle()
                        .trim(from: 0, to: countdownProgress)
                        .stroke(Color.gold, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .accessibilityHidden(true)

                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                        vm.resetToWelcome()
                    } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .medium))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Returns to the welcome screen")
                }
                .padding(.bottom, 48)
                .onAppear {
                    withAnimation(.linear(duration: AppConfig.confirmationAutoReturnSeconds)) {
                        countdownProgress = 0
                    }

                    // Content reveal after checkmark
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.8)) {
                            showContent = true
                        }
                    }

                    // Confetti after checkmark draw
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showConfetti = true
                        }
                    }
                }
            }
        }
        .dynamicTypeSize(.large ... .accessibility3)
    }
}

// MARK: - Confetti Particles

struct ConfettiParticlesView: View {
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                ConfettiDot(
                    color: index % 2 == 0 ? Color.gold : Color.affOrange.opacity(0.7),
                    delay: Double(index) * 0.08,
                    angle: Angle(degrees: Double(index) * 60),
                    distance: CGFloat(45 + (index % 3) * 12)
                )
            }
        }
    }
}

struct ConfettiDot: View {
    let color: Color
    let delay: Double
    let angle: Angle
    let distance: CGFloat

    @State private var isAnimating = false
    @State private var opacity: Double = 0

    private var offsetX: CGFloat {
        cos(angle.radians) * distance
    }

    private var offsetY: CGFloat {
        sin(angle.radians) * distance
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .offset(
                x: isAnimating ? offsetX : 0,
                y: isAnimating ? (offsetY - 40) : 0
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(delay)) {
                    isAnimating = true
                    opacity = 1.0
                }
                withAnimation(.easeIn(duration: 0.6).delay(delay + 0.8)) {
                    opacity = 0
                }
            }
    }
}
