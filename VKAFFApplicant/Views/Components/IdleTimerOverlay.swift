import SwiftUI

struct IdleTimerOverlay: View {
    @EnvironmentObject var vm: RegistrationViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(.affOrange)

                Text("Are you still here?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                Text("Your session will reset in \(vm.idleCountdown) seconds")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))

                Button {
                    vm.confirmPresence()
                } label: {
                    Text("Yes, I'm here")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.purpleDeep)
            )
        }
        .transition(.opacity)
    }
}
