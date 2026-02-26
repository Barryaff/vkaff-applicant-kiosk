import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    // Stagger entrance states
    @State private var showLogo: Bool = false
    @State private var showTagline: Bool = false
    @State private var showWelcomeText: Bool = false
    @State private var showButton: Bool = false

    // Looping animation states
    @State private var taglineBreathing: Bool = false
    @State private var taglineDrift: CGFloat = 0
    @State private var gradientShift: Bool = false
    @State private var buttonPulse: Bool = false

    var body: some View {
        ZStack {
            // Background gradient with subtle shifting
            LinearGradient(
                colors: [
                    Color.vkaPurple,
                    gradientShift ? Color.purpleDeep.opacity(0.88) : Color.purpleDeep
                ],
                startPoint: gradientShift ? .topLeading : .top,
                endPoint: gradientShift ? .bottomTrailing : .bottom
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    gradientShift.toggle()
                }
            }

            VStack(spacing: 0) {
                Spacer()

                // VKA Logo (large, centered) -- stagger: 0.3s
                Image("vka_logo_white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .accessibilityLabel("VKA company logo")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Triple tap to access admin panel")
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.92)
                    .onTapGesture {
                        vm.handleWelcomeLogoTap()
                    }

                // AFF Logo (subtle) -- appears with VKA logo
                Image("aff_logo_orange")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .opacity(showLogo ? 0.4 : 0)
                    .padding(.top, 16)
                    .accessibilityHidden(true)

                // Tagline -- stagger: 0.6s, breathing + vertical drift loop
                Text("Pioneering Taste. Perfecting Innovation.")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(Color.lightBackground)
                    .tracking(0.5)
                    .padding(.top, 32)
                    .opacity(showTagline ? (taglineBreathing ? 0.5 : 1.0) : 0)
                    .offset(y: showTagline ? taglineDrift : 8)
                    .accessibilityLabel("Tagline: Pioneering Taste. Perfecting Innovation.")

                // Welcome text -- stagger: 0.9s
                Text("Welcome to VKAFF")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(.white)
                    .tracking(0.5)
                    .padding(.top, 24)
                    .accessibilityAddTraits(.isHeader)
                    .opacity(showWelcomeText ? 1 : 0)
                    .offset(y: showWelcomeText ? 0 : 12)

                Text("Thank you for your interest in joining our team.\nPlease tap below to begin your registration.")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.purpleLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 16)
                    .padding(.horizontal, 48)
                    .accessibilityLabel("Thank you for your interest in joining our team. Please tap below to begin your registration.")
                    .opacity(showWelcomeText ? 1 : 0)
                    .offset(y: showWelcomeText ? 0 : 12)

                // CTA Button -- stagger: 1.2s, subtle scale pulse
                Button {
                    vm.navigateForward()
                } label: {
                    Text("Begin Registration")
                }
                .buttonStyle(LargeCTAButtonStyle())
                .padding(.top, 48)
                .accessibilityLabel("Begin Registration")
                .accessibilityHint("Starts the job application form")
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? (buttonPulse ? 1.02 : 1.0) : 0.9)

                Spacer()

                // PDPA notice
                Text("Your information is collected in accordance with Singapore's PDPA.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
                    .accessibilityLabel("Your information is collected in accordance with Singapore's Personal Data Protection Act.")

                // Footer
                Text("Advanced Flavors & Fragrances Pte. Ltd.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 24)
                    .accessibilityHidden(true)
            }

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
            // Reset states so re-entry re-triggers the stagger
            showLogo = false
            showTagline = false
            showWelcomeText = false
            showButton = false
            taglineBreathing = false
            buttonPulse = false
        }
    }

    // MARK: - Staggered Entrance + Looping Animations

    private func triggerStaggeredEntrance() {
        // Logo fades in first (0.3s)
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showLogo = true
        }

        // Tagline fades in (0.6s)
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showTagline = true
        }

        // Welcome text fades in (0.9s)
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            showWelcomeText = true
        }

        // Button fades in (1.2s)
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            showButton = true
        }

        // Start looping animations after entrance completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            // Tagline breathing: fade in/out over 3s cycle
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                taglineBreathing = true
            }

            // Tagline vertical drift: slight 3pt float over 3s
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                taglineDrift = -3
            }

            // Button pulse: 1.0 -> 1.02 over 2s cycle
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                buttonPulse = true
            }
        }
    }

    // MARK: - Admin PIN Overlay

    private var adminPINOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    vm.showAdminPIN = false
                    vm.adminPINEntry = ""
                }

            VStack(spacing: 20) {
                Text("Admin Access")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.darkText)
                    .accessibilityAddTraits(.isHeader)

                SecureField("Enter PIN", text: $vm.adminPINEntry)
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 200)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.lightBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
        }
    }
}
