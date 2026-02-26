import SwiftUI

struct ConfirmationView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @State private var countdownProgress: CGFloat = 1.0
    @State private var showConfetti: Bool = false

    var body: some View {
        ZStack {
            // Background gradient (same as welcome)
            LinearGradient(
                colors: [Color.vkaPurple, Color.purpleDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated checkmark with confetti
                ZStack {
                    AnimatedCheckmark()

                    // Confetti particles triggered after checkmark
                    if showConfetti {
                        ConfettiParticlesView()
                    }
                }
                .padding(.bottom, 40)
                .accessibilityHidden(true)

                // Thank you message
                Text("Thank You, \(vm.applicant.preferredName.isEmpty ? vm.applicant.fullName : vm.applicant.preferredName)!")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("Thank You, \(vm.applicant.preferredName.isEmpty ? vm.applicant.fullName : vm.applicant.preferredName)!")

                Text("Your application has been received successfully.\nOur HR team will review your application and be in touch shortly.")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.purpleLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 16)
                    .padding(.horizontal, 48)
                    .accessibilityLabel("Your application has been received successfully. Our HR team will review your application and be in touch shortly.")

                // Reference number
                HStack(spacing: 8) {
                    Text("Application Reference:")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))

                    Text(vm.applicant.referenceNumber)
                        .font(.system(size: 16, weight: .bold).monospacedDigit())
                        .foregroundColor(.affOrange)
                }
                .padding(.top, 24)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Application Reference: \(vm.applicant.referenceNumber)")

                // Logos
                VStack(spacing: 16) {
                    Image("vka_logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160)

                    Image("aff_logo_orange")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64)
                }
                .padding(.top, 48)
                .accessibilityHidden(true)

                Spacer()

                // Done button with countdown ring
                ZStack {
                    // Background track ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .accessibilityHidden(true)

                    // Animated countdown ring
                    Circle()
                        .trim(from: 0, to: countdownProgress)
                        .stroke(Color.affOrange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .accessibilityHidden(true)

                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                        vm.resetToWelcome()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Returns to the welcome screen. This screen will automatically return in a few seconds.")
                }
                .padding(.bottom, 48)
                .onAppear {
                    // Smooth countdown ring animation
                    withAnimation(.linear(duration: AppConfig.confirmationAutoReturnSeconds)) {
                        countdownProgress = 0
                    }

                    // Trigger confetti after checkmark draw completes (~1.4s)
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
                    color: index % 2 == 0 ? Color.affOrange : Color.purpleLight,
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
            .frame(width: 8, height: 8)
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
