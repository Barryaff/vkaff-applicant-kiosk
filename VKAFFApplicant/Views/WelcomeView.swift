import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    // Stagger entrance states
    @State private var showLogos: Bool = false
    @State private var showLabel: Bool = false
    @State private var showHeadline: Bool = false
    @State private var showSubtext: Bool = false
    @State private var showButton: Bool = false
    @State private var showFooter: Bool = false

    // Ambient animation states
    @State private var glowPulse: Bool = false
    @State private var scrollIndicator: CGFloat = 0

    var body: some View {
        ZStack {
            // Deep navy background
            Color.navy
                .ignoresSafeArea()

            // Subtle radial gradient overlay for depth
            RadialGradient(
                colors: [
                    Color.navyLight.opacity(0.4),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Dual logos — VKA above AFF
                VStack(spacing: 20) {
                    Image("vka_logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                        .accessibilityLabel("VKA company logo")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Triple tap to access admin panel")
                        .onTapGesture {
                            vm.handleWelcomeLogoTap()
                        }

                    // Thin gold separator
                    Rectangle()
                        .fill(Color.gold.opacity(0.4))
                        .frame(width: 48, height: 1)

                    Image("aff_logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                        .opacity(0.7)
                        .accessibilityHidden(true)
                }
                .opacity(showLogos ? 1 : 0)
                .scaleEffect(showLogos ? 1 : 0.95)

                Spacer()
                    .frame(height: 64)

                // Section label — uppercase, wide tracking, gold
                Text("WALK-IN REGISTRATION")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundColor(.gold)
                    .opacity(showLabel ? 1 : 0)
                    .offset(y: showLabel ? 0 : 8)
                    .accessibilityHidden(true)

                Spacer()
                    .frame(height: 20)

                // Main headline — large, confident, tight tracking
                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.system(size: 44, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(-0.5)

                    Text("VKAFF")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.white)
                        .tracking(6)
                }
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 16)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Welcome to VKAFF")

                Spacer()
                    .frame(height: 24)

                // Subtext — softer, editorial tone
                Text("Thank you for your interest in joining our team.\nPlease tap below to begin your application.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 80)
                    .opacity(showSubtext ? 1 : 0)
                    .offset(y: showSubtext ? 0 : 10)
                    .accessibilityLabel("Thank you for your interest in joining our team. Please tap below to begin your application.")

                Spacer()
                    .frame(height: 48)

                // CTA Button
                Button {
                    vm.navigateForward()
                } label: {
                    Text("Begin Registration")
                }
                .buttonStyle(LargeCTAButtonStyle())
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? 1 : 0.95)
                .accessibilityLabel("Begin Registration")
                .accessibilityHint("Starts the job application form")

                Spacer()

                // Footer section
                VStack(spacing: 12) {
                    // PDPA notice
                    Text("Your information is collected in accordance with Singapore's PDPA.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.25))
                        .accessibilityLabel("Your information is collected in accordance with Singapore's Personal Data Protection Act.")

                    // Thin separator
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 120)

                    Text("Advanced Flavors & Fragrances Pte. Ltd.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.15))
                        .tracking(1)
                        .accessibilityHidden(true)
                }
                .padding(.bottom, 32)
                .opacity(showFooter ? 1 : 0)
            }

            // Subtle ambient glow behind logos
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gold.opacity(glowPulse ? 0.06 : 0.02), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .position(x: UIScreen.main.bounds.width / 2, y: 200)
                .allowsHitTesting(false)

            // Admin PIN dialog
            if vm.showAdminPIN {
                adminPINOverlay
            }
        }
        .dynamicTypeSize(.large ... .accessibility3)
        .onAppear {
            triggerStaggeredEntrance()
        }
        .onDisappear {
            showLogos = false
            showLabel = false
            showHeadline = false
            showSubtext = false
            showButton = false
            showFooter = false
            glowPulse = false
        }
    }

    // MARK: - Staggered Entrance

    private func triggerStaggeredEntrance() {
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.8).delay(0.2)) {
            showLogos = true
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.7).delay(0.5)) {
            showLabel = true
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(0.7)) {
            showHeadline = true
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.8).delay(1.0)) {
            showSubtext = true
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.7).delay(1.3)) {
            showButton = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.6)) {
            showFooter = true
        }

        // Ambient glow pulse after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Admin PIN Overlay

    private var adminPINOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    vm.showAdminPIN = false
                    vm.adminPINEntry = ""
                }

            VStack(spacing: 24) {
                Text("Admin Access")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.navy)
                    .tracking(-0.3)
                    .accessibilityAddTraits(.isHeader)

                SecureField("Enter PIN", text: $vm.adminPINEntry)
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 200)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.lightBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.dividerSubtle)
                    )
                    .accessibilityLabel("Admin PIN")
                    .accessibilityHint("Enter the admin PIN code")

                HStack(spacing: 16) {
                    Button("Cancel") {
                        vm.showAdminPIN = false
                        vm.adminPINEntry = ""
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Dismisses the admin login dialog")

                    Button("Enter") {
                        vm.attemptAdminLogin()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityLabel("Enter")
                    .accessibilityHint("Submits the admin PIN")
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.3), radius: 40)
            )
        }
    }
}
