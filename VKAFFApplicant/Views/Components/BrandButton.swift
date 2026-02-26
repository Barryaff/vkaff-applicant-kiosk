import SwiftUI

struct BrandButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
        case largeCTA
    }

    let title: String
    let style: Style
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            action()
        }) {
            Text(title)
        }
        .modifier(ButtonStyleModifier(style: style, isEnabled: isEnabled))
        .disabled(!isEnabled)
    }
}

struct ButtonStyleModifier: ViewModifier {
    let style: BrandButton.Style
    let isEnabled: Bool

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            content.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
        case .secondary:
            content.buttonStyle(SecondaryButtonStyle())
        case .destructive:
            content.buttonStyle(DestructiveButtonStyle())
        case .largeCTA:
            content.buttonStyle(LargeCTAButtonStyle())
        }
    }
}

// MARK: - Bottom Navigation Bar

struct FormNavigationBar: View {
    let onBack: (() -> Void)?
    let onContinue: () -> Void
    var continueTitle: String = "Continue"
    var isEnabled: Bool = true

    var body: some View {
        HStack {
            if let onBack = onBack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel("Back")
                .accessibilityHint("Go to the previous step")
            }

            Spacer()

            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text(continueTitle)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
            .disabled(!isEnabled)
            .accessibilityLabel(continueTitle)
            .accessibilityHint(isEnabled ? "Proceed to the next step" : "Complete all required fields before continuing")
            .accessibilityValue(isEnabled ? "enabled" : "disabled")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
