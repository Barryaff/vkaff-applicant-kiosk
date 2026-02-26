import SwiftUI

struct ProgressBar: View {
    let currentStep: Int
    let steps = AppScreen.formScreens

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                HStack(spacing: 0) {
                    // Step indicator
                    ZStack {
                        if index < currentStep {
                            // Completed
                            Circle()
                                .fill(Color.vkaPurple)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else if index == currentStep {
                            // Current
                            Circle()
                                .fill(Color.affOrange)
                                .frame(width: 28, height: 28)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .modifier(PulseModifier())
                        } else {
                            // Upcoming
                            Circle()
                                .fill(Color.dividerSubtle)
                                .frame(width: 28, height: 28)
                        }
                    }

                    // Label
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text(step.title)
                            .font(.system(size: 11, weight: index == currentStep ? .semibold : .regular))
                            .foregroundColor(index <= currentStep ? .darkText : .mediumGray)
                            .padding(.leading, 6)
                    }

                    // Connector line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.affOrange : Color.dividerSubtle)
                            .frame(height: 2)
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
