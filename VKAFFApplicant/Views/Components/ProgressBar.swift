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
                            // Completed — gold checkmark
                            Circle()
                                .fill(Color.navy)
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gold)
                        } else if index == currentStep {
                            // Current — orange with pulse
                            Circle()
                                .fill(Color.affOrange)
                                .frame(width: 26, height: 26)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .modifier(PulseModifier())
                        } else {
                            // Upcoming — subtle
                            Circle()
                                .stroke(Color.dividerSubtle, lineWidth: 1.5)
                                .frame(width: 26, height: 26)
                        }
                    }
                    .accessibilityHidden(true)

                    // Label
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text(step.title)
                            .font(.system(size: 11, weight: index == currentStep ? .semibold : .regular))
                            .foregroundColor(index == currentStep ? .navy : (index < currentStep ? .navy.opacity(0.6) : .bodyGray.opacity(0.5)))
                            .tracking(index == currentStep ? 0 : 0.3)
                            .padding(.leading, 6)
                            .accessibilityHidden(true)
                    }

                    // Connector line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.navy.opacity(0.3) : Color.dividerSubtle)
                            .frame(height: 1)
                            .padding(.horizontal, 8)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.4), value: currentStep)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep + 1) of \(steps.count), \(steps[currentStep].title)")
        .accessibilityValue(currentStep > 0 ? "\(currentStep) step\(currentStep == 1 ? "" : "s") completed" : "No steps completed")
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
