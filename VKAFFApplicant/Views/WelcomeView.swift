import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    // Stagger entrance states
    @State private var showLogo: Bool = false
    @State private var showHeadline: Bool = false
    @State private var showSubtext: Bool = false
    @State private var showButton: Bool = false
    @State private var showFooter: Bool = false

    // Ambient animation states
    @State private var glowPulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep navy background
                Color.navy
                    .ignoresSafeArea()

                // Subtle radial gradient — larger, centered on content
                RadialGradient(
                    colors: [
                        Color.navyLight.opacity(0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: geo.size.height * 0.6
                )
                .ignoresSafeArea()

                // Ambient glow — centered on logos
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.gold.opacity(glowPulse ? 0.08 : 0.03), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.3)
                    .allowsHitTesting(false)

                // Content — fills full viewport
                VStack(spacing: 0) {

                    Spacer()

                    // VKA logo — hero element
                    Image("vka_logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                        .accessibilityLabel("VKA company logo")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Triple tap to access admin panel")
                        .onTapGesture {
                            vm.handleWelcomeLogoTap()
                        }
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? 1 : 0.96)

                    Spacer()
                        .frame(height: geo.size.height * 0.06)

                    // Headline
                    VStack(spacing: 16) {
                        Text("Registration")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white)
                            .tracking(-0.5)

                        // Gold accent line
                        Rectangle()
                            .fill(Color.gold.opacity(0.4))
                            .frame(width: 40, height: 1.5)
                    }
                    .opacity(showHeadline ? 1 : 0)
                    .offset(y: showHeadline ? 0 : 12)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("Registration")

                    Spacer()
                        .frame(height: 28)

                    // Subtext
                    Text("Thank you for your interest in joining our team.\nTap below to begin your application.")
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .frame(maxWidth: 420)
                        .opacity(showSubtext ? 1 : 0)
                        .offset(y: showSubtext ? 0 : 8)
                        .accessibilityLabel("Thank you for your interest in joining our team. Tap below to begin your application.")

                    Spacer()
                        .frame(height: 48)

                    // CTA Button
                    Button {
                        vm.navigateForward()
                    } label: {
                        Text("Begin")
                    }
                    .buttonStyle(LargeCTAButtonStyle())
                    .opacity(showButton ? 1 : 0)
                    .scaleEffect(showButton ? 1 : 0.95)
                    .accessibilityLabel("Begin Registration")
                    .accessibilityHint("Starts the job application form")

                    Spacer()

                    // Footer
                    VStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 80)

                        Text("Your information is collected in accordance with Singapore's PDPA.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.50))
                            .accessibilityLabel("Your information is collected in accordance with Singapore's Personal Data Protection Act.")

                        Text("Advanced Flavors & Fragrances Pte. Ltd.")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.white.opacity(0.35))
                            .tracking(1.5)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, 28)
                    .opacity(showFooter ? 1 : 0)
                }
                .frame(maxWidth: .infinity)

                // Admin PIN dialog
                if vm.showAdminPIN {
                    adminPINOverlay
                }
            }
        }
        .dynamicTypeSize(.large ... .accessibility3)
        .onAppear {
            triggerStaggeredEntrance()
        }
        .onDisappear {
            showLogo = false
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
            showLogo = true
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(0.6)) {
            showHeadline = true
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.8).delay(0.9)) {
            showSubtext = true
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.7).delay(1.2)) {
            showButton = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.5)) {
            showFooter = true
        }

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

                    Button("Enter") {
                        vm.attemptAdminLogin()
                    }
                    .buttonStyle(PrimaryButtonStyle())
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
