import SwiftUI

struct ConfirmationView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @State private var countdownProgress: CGFloat = 1.0

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

                // Animated checkmark
                AnimatedCheckmark()
                    .padding(.bottom, 40)

                // Thank you message
                Text("Thank You, \(vm.applicant.preferredName.isEmpty ? vm.applicant.fullName : vm.applicant.preferredName)!")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                Text("Your application has been received successfully.\nOur HR team will review your application and be in touch shortly.")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.purpleLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 16)
                    .padding(.horizontal, 48)

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

                Spacer()

                // Done button with countdown ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: countdownProgress)
                        .stroke(Color.affOrange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Button {
                        vm.resetToWelcome()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 48)
                .onAppear {
                    withAnimation(.linear(duration: AppConfig.confirmationAutoReturnSeconds)) {
                        countdownProgress = 0
                    }
                }
            }
        }
    }
}
