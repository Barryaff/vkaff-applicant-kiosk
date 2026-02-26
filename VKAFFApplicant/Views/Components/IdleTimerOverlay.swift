import SwiftUI

struct IdleTimerOverlay: View {
    @EnvironmentObject var vm: RegistrationViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 24) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(.affOrange)
                    .accessibilityHidden(true)

                Text("Are you still here?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)

                Text("Your session will reset in \(vm.idleCountdown) seconds")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .accessibilityLabel("Your session will reset in \(vm.idleCountdown) seconds")

                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    vm.confirmPresence()
                } label: {
                    Text("Yes, I'm here")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
                .accessibilityLabel("Yes, I'm here")
                .accessibilityHint("Tap to continue your session and prevent it from resetting")
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.purpleDeep)
            )
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }
}
