import SwiftUI

/// A phone number input with a country code dropdown.
/// Singapore (+65) and Malaysia (+60) are pinned at the top.
struct PhoneFieldWithCode: View {
    let label: String
    @Binding var countryCode: String
    @Binding var phoneNumber: String
    var placeholder: String = "Phone number"
    var errorMessage: String? = nil
    var isValid: Bool = false
    var focusBinding: FocusState<PersonalDetailsFocus?>.Binding? = nil
    var focusValue: PersonalDetailsFocus? = nil

    @FocusState private var isFocused: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var errorVisible: Bool = false
    @State private var borderPulse: Bool = false

    private var selectedCode: CountryCode {
        CountryCode.find(byDialCode: countryCode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()
                .accessibilityHidden(true)

            HStack(spacing: 0) {
                // Country code picker
                Menu {
                    // Pinned section
                    Section("Frequently Used") {
                        codeButton(CountryCode.singapore)
                        codeButton(CountryCode.malaysia)
                    }

                    Section("All Countries") {
                        ForEach(CountryCode.all.dropFirst(2)) { code in
                            codeButton(code)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCode.flag)
                            .font(.system(size: 18))
                        Text(selectedCode.dialCode)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.darkText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.mediumGray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 10, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(isFocused ? Color.orangeLight : Color.lightBackground)
                    )
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 10, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .stroke(
                                errorMessage != nil ? Color.errorRed :
                                    (isFocused ? Color.affOrange : Color.dividerSubtle),
                                lineWidth: errorMessage != nil ? (borderPulse ? 2.5 : 1.5) : 1
                            )
                    )
                }
                .accessibilityLabel("Country code: \(selectedCode.name) \(selectedCode.dialCode)")

                // Divider
                Rectangle()
                    .fill(Color.dividerSubtle)
                    .frame(width: 1)
                    .padding(.vertical, 6)

                // Phone number field
                ZStack(alignment: .trailing) {
                    TextField(placeholder, text: $phoneNumber)
                        .font(.system(size: 20))
                        .foregroundColor(.darkText)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(
                            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 10, topTrailingRadius: 10)
                                .fill(isFocused ? Color.orangeLight : Color.lightBackground)
                        )
                        .overlay(
                            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 10, topTrailingRadius: 10)
                                .stroke(
                                    errorMessage != nil ? Color.errorRed :
                                        (isFocused ? Color.affOrange : Color.dividerSubtle),
                                    lineWidth: errorMessage != nil ? (borderPulse ? 2.5 : 1.5) : 1
                                )
                        )
                        .overlay(
                            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 10, topTrailingRadius: 10)
                                .stroke(Color.affOrange.opacity(0.4 * glowOpacity), lineWidth: 3)
                                .blur(radius: 4)
                                .opacity(glowOpacity)
                        )
                        .focused($isFocused)
                        .applyFocus(focusBinding: focusBinding, value: focusValue)
                        .accessibilityLabel("\(label), phone number")
                        .accessibilityValue(phoneNumber.isEmpty ? "empty" : phoneNumber)

                    if isValid && !isFocused {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.successGreen)
                            .font(.system(size: 20))
                            .padding(.trailing, 12)
                            .accessibilityHidden(true)
                    }
                }
            }
            .offset(x: shakeOffset)
            .onChange(of: isFocused) { _, focused in
                withAnimation(.easeInOut(duration: 0.3)) {
                    glowOpacity = focused ? 1 : 0
                }
                if focused {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .opacity(errorVisible ? 1 : 0)
                    .offset(y: errorVisible ? 0 : 6)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.2)) { errorVisible = true }
                        triggerShake()
                    }
                    .onDisappear {
                        errorVisible = false
                        borderPulse = false
                    }
                    .accessibilityHidden(true)
            }
        }
    }

    private func codeButton(_ code: CountryCode) -> some View {
        Button {
            countryCode = code.dialCode
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text(code.menuLabel)
                if code.dialCode == countryCode {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private func triggerShake() {
        let anim = Animation.spring(response: 0.08, dampingFraction: 0.3)
        withAnimation(anim) { shakeOffset = 6 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(anim) { shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(anim) { shakeOffset = 4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
        withAnimation(.easeIn(duration: 0.15)) { borderPulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.25)) { borderPulse = false }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
