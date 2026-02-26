import SwiftUI

// MARK: - Primary Button (Orange)

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
                    .fill(isEnabled ? (configuration.isPressed ? Color.orangePress : Color.affOrange) : Color.bodyGray.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? Color.affOrange : Color.bodyGray.opacity(0.2), lineWidth: 1.5)
            )
            .offset(y: configuration.isPressed ? 0 : -1)
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.4), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (Outlined)

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
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.4), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button (Gray Outlined)

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .tracking(0.5)
            .foregroundColor(configuration.isPressed ? .errorRed : .bodyGray)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(configuration.isPressed ? Color.errorRed.opacity(0.5) : Color.dividerSubtle, lineWidth: 1)
            )
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.4), value: configuration.isPressed)
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
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.4), value: configuration.isPressed)
    }
}
