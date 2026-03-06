import SwiftUI

// MARK: - Animation Tokens

extension Animation {
    /// Quick interactive feedback (buttons, toggles)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.7)
    /// Smooth transitions (screen changes, reveals)
    static let smooth = Animation.easeOut(duration: 0.3)
    /// Dramatic emphasis (success states, celebrations)
    static let dramatic = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - Primary Button (Orange)

// TODO: Add focus indicator for accessibility — @Environment(\.isFocused) is not available
// in ButtonStyle context. Implement focus ring overlay at the call site or via a wrapper view.
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? (configuration.isPressed ? Color.orangePress : Color.affOrange) : Color.mediumGray.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? Color.affOrange : Color.mediumGray.opacity(0.4), lineWidth: 1.5)
            )
            .offset(y: configuration.isPressed ? 0 : -1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (Outlined)

// TODO: Add focus indicator for accessibility — same constraint as PrimaryButtonStyle.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .tracking(1)
            .foregroundColor(configuration.isPressed ? .affOrange : .navy)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.orangeLight : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(configuration.isPressed ? Color.affOrange : Color.dividerSubtle, lineWidth: 1.5)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button (Gray Outlined)

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .tracking(0.5)
            .foregroundColor(configuration.isPressed ? .errorRed : .mediumGray)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(configuration.isPressed ? Color.errorRed.opacity(0.5) : Color.dividerSubtle, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Large CTA (Welcome Screen)

struct LargeCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .tracking(3)
            .textCase(.uppercase)
            .foregroundColor(configuration.isPressed ? .navy : .white)
            .padding(.horizontal, 56)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.gold : Color.affOrange)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .offset(y: configuration.isPressed ? 0 : -2)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
