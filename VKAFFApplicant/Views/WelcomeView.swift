import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @State private var taglineOpacity: Double = 0
    @State private var gradientShift: Bool = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.vkaPurple,
                    gradientShift ? Color.purpleDeep.opacity(0.95) : Color.purpleDeep
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    gradientShift.toggle()
                }
            }

            VStack(spacing: 0) {
                Spacer()

                // VKA Logo (large, centered)
                Image("vka_logo_white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .onTapGesture {
                        vm.handleWelcomeLogoTap()
                    }

                // AFF Logo (subtle)
                Image("aff_logo_orange")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .opacity(0.4)
                    .padding(.top, 16)

                // Tagline
                Text("Pioneering Taste. Perfecting Innovation.")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(Color.lightBackground)
                    .tracking(0.5)
                    .padding(.top, 32)
                    .opacity(taglineOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            taglineOpacity = taglineOpacity == 0 ? 1 : 0
                        }
                        taglineOpacity = 1
                    }

                // Welcome text
                Text("Welcome to VKAFF")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(.white)
                    .tracking(0.5)
                    .padding(.top, 24)

                Text("Thank you for your interest in joining our team.\nPlease tap below to begin your registration.")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.purpleLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 16)
                    .padding(.horizontal, 48)

                // CTA Button
                Button {
                    vm.navigateForward()
                } label: {
                    Text("Begin Registration")
                }
                .buttonStyle(LargeCTAButtonStyle())
                .padding(.top, 48)

                Spacer()

                // PDPA notice
                Text("Your information is collected in accordance with Singapore's PDPA.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)

                // Footer
                Text("Advanced Flavors & Fragrances Pte. Ltd.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 24)
            }

            // Admin PIN dialog
            if vm.showAdminPIN {
                adminPINOverlay
            }
        }
    }

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
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
        }
    }
}
