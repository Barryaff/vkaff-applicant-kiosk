import SwiftUI

// Cached formatter to avoid per-keystroke allocations in salary fields
private let salaryFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    return formatter
}()

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isMultiline: Bool = false
    var maxLength: Int? = nil
    var errorMessage: String? = nil
    var isValid: Bool = false
    var isSalaryField: Bool = false
    var autocapitalization: TextInputAutocapitalization = .characters
    var onCommit: (() -> Void)? = nil
    var focusBinding: FocusState<PersonalDetailsFocus?>.Binding? = nil
    var focusValue: PersonalDetailsFocus? = nil
    var educationFocusBinding: FocusState<EducationFocus?>.Binding? = nil
    var educationFocusValue: EducationFocus? = nil
    var positionFocusBinding: FocusState<PositionFocus?>.Binding? = nil
    var positionFocusValue: PositionFocus? = nil

    @FocusState private var isFocused: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var errorVisible: Bool = false
    @State private var borderPulse: Bool = false

    // Local text buffer — isolates per-keystroke re-renders to this view only.
    // Syncs back to the binding on focus loss so the struct mutation (which
    // triggers full view-hierarchy invalidation) is batched.
    @State private var localText: String = ""
    @State private var isShaking: Bool = false

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var accessibilityLabelText: String {
        var labelText = label
        if let error = errorMessage {
            labelText += ", Error: \(error)"
        } else if isValid {
            labelText += ", valid"
        }
        return labelText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()
                .accessibilityHidden(true)

            ZStack(alignment: .trailing) {
                if isMultiline {
                    TextEditor(text: $localText)
                        .font(.system(size: 20))
                        .foregroundColor(.darkText)
                        .textInputAutocapitalization(autocapitalization)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 130)
                        .padding(12)
                        .background(fieldBackground)
                        .overlay(fieldBorder)
                        .overlay(focusGlow)
                        .focused($isFocused)
                        .applyFocus(focusBinding: focusBinding, value: focusValue)
                        .applyEducationFocus(focusBinding: educationFocusBinding, value: educationFocusValue)
                        .applyPositionFocus(focusBinding: positionFocusBinding, value: positionFocusValue)
                        .onChange(of: localText) { _, newValue in
                            if let max = maxLength, newValue.count > max {
                                localText = String(newValue.prefix(max))
                                return
                            }
                            // No sync during typing — flush happens on focus loss
                        }
                        .accessibilityLabel(accessibilityLabelText)
                        .accessibilityHint(placeholder.isEmpty ? "Enter \(label.lowercased())" : placeholder)
                        .accessibilityValue(localText.isEmpty ? "empty" : localText)

                    if let max = maxLength {
                        Text("\(localText.count)/\(max)")
                            .font(.system(size: 12))
                            .foregroundColor(.mediumGray)
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                            .frame(maxHeight: .infinity, alignment: .bottomTrailing)
                            .accessibilityLabel("\(localText.count) of \(max) characters used")
                    }
                } else {
                    TextField(placeholder, text: isSalaryField ? localSalaryBinding : $localText, onCommit: {
                        onCommit?()
                    })
                    .font(.system(size: 20))
                    .foregroundColor(.darkText)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .overlay(focusGlow)
                    .focused($isFocused)
                    .applyFocus(focusBinding: focusBinding, value: focusValue)
                    .accessibilityLabel(accessibilityLabelText)
                    .accessibilityHint(placeholder.isEmpty ? "Enter \(label.lowercased())" : placeholder)
                    .applyEducationFocus(focusBinding: educationFocusBinding, value: educationFocusValue)
                    .applyPositionFocus(focusBinding: positionFocusBinding, value: positionFocusValue)
                    .onChange(of: localText) { _, newValue in
                        if let max = maxLength, newValue.count > max {
                            localText = String(newValue.prefix(max))
                            return
                        }
                        // No sync during typing — flush happens on focus loss
                    }
                }

                // Valid checkmark
                if isValid && !isFocused {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.system(size: 20))
                        .padding(.trailing, 16)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .offset(x: shakeOffset)
            .onChange(of: isFocused) { _, focused in
                glowOpacity = focused ? 1 : 0
                if !focused {
                    flushToBinding()
                }
            }

            // Error message -- slides in from below with fade
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .opacity(errorVisible ? 1 : 0)
                    .offset(y: errorVisible ? 0 : 6)
                    .onAppear {
                        triggerErrorAnimation()
                    }
                    .onDisappear {
                        errorVisible = false
                        borderPulse = false
                    }
                    .accessibilityHidden(true)
            }
        }
        .onAppear { localText = text }
        .onChange(of: text) { _, newValue in
            if localText != newValue { localText = newValue }
        }
    }

    // MARK: - Local Buffer Sync

    private func flushToBinding() {
        if text != localText { text = localText }
    }

    // MARK: - Error Animation

    private func triggerErrorAnimation() {
        guard !isShaking else { return }
        isShaking = true

        // Slide error text in from below
        withAnimation(.easeOut(duration: 0.2)) {
            errorVisible = true
        }

        if !reduceMotion {
            // Smooth spring shake: 3 cycles, 6pt amplitude
            let shakeAnim = Animation.spring(response: 0.08, dampingFraction: 0.3)
            withAnimation(shakeAnim) { shakeOffset = 6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(shakeAnim) { shakeOffset = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(shakeAnim) { shakeOffset = 6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(shakeAnim) { shakeOffset = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                withAnimation(shakeAnim) { shakeOffset = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
                    shakeOffset = 0
                }
                isShaking = false
            }
        } else {
            isShaking = false
        }

        // Red border pulse once
        withAnimation(.easeIn(duration: 0.15)) {
            borderPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.25)) {
                borderPulse = false
            }
        }

        // Warning haptic on error
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.warning)
    }

    // MARK: - Phone binding (no auto-prefix — supports international numbers)
    // phoneAutoPrefix removed — use $text directly

    // MARK: - Salary auto-formatting binding (operates on local buffer)
    private var localSalaryBinding: Binding<String> {
        Binding(
            get: { localText },
            set: { newValue in
                let newDigits = newValue.filter { $0.isNumber }
                let oldDigits = localText.filter { $0.isNumber }
                guard newDigits != oldDigits else { return }

                if let number = Int(newDigits) {
                    let formatted = salaryFormatter.string(from: NSNumber(value: number)) ?? newDigits
                    if localText != formatted { localText = formatted }
                } else if newDigits.isEmpty && !localText.isEmpty {
                    localText = ""
                }
                // No sync during typing — flush happens on focus loss
            }
        )
    }

    // MARK: - Focus advance helper
    private func advanceFocus() {
        // Advance personal details focus
        if let binding = focusBinding, let value = focusValue {
            switch value {
            case .fullName: binding.wrappedValue = .preferredName
            case .preferredName: binding.wrappedValue = .nricFIN
            case .nricFIN: binding.wrappedValue = .contactNumber
            case .contactNumber: binding.wrappedValue = .emailAddress
            case .emailAddress: binding.wrappedValue = .residentialAddress
            case .residentialAddress: binding.wrappedValue = .postalCode
            case .postalCode: binding.wrappedValue = .emergencyContactName
            case .emergencyContactName: binding.wrappedValue = .emergencyContactNumber
            case .emergencyContactNumber: binding.wrappedValue = nil
            }
        }
        // Advance education focus
        if let binding = educationFocusBinding, let value = educationFocusValue {
            switch value {
            case .fieldOfStudy: binding.wrappedValue = .institutionName
            case .institutionName: binding.wrappedValue = .certifications
            case .certifications: binding.wrappedValue = nil
            }
        }
        // Advance position focus
        if let binding = positionFocusBinding, let value = positionFocusValue {
            switch value {
            case .positionOther: binding.wrappedValue = .expectedSalary
            case .expectedSalary: binding.wrappedValue = .referrerName
            case .referrerName: binding.wrappedValue = nil
            }
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isFocused ? Color.orangeLight : Color.lightBackground)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(
                errorMessage != nil ? Color.errorRed :
                    (isFocused ? Color.affOrange : Color.dividerSubtle),
                lineWidth: errorMessage != nil ? (borderPulse ? 2.5 : 1.5) : 1
            )
            .allowsHitTesting(false)
    }

    private var focusGlow: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.affOrange.opacity(0.3 * glowOpacity), lineWidth: 2)
            .opacity(glowOpacity)
            .allowsHitTesting(false)
    }
}

// MARK: - Focus State Enums

enum PersonalDetailsFocus: Hashable {
    case fullName, preferredName, nricFIN, contactNumber, emailAddress
    case residentialAddress, postalCode, emergencyContactName, emergencyContactNumber
}

enum EducationFocus: Hashable {
    case fieldOfStudy, institutionName, certifications
}

enum PositionFocus: Hashable {
    case positionOther, expectedSalary, referrerName
}

// MARK: - Focus binding helpers

extension View {
    @ViewBuilder
    func applyFocus(focusBinding: FocusState<PersonalDetailsFocus?>.Binding?, value: PersonalDetailsFocus?) -> some View {
        if let binding = focusBinding, let value = value {
            self.focused(binding, equals: value)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyEducationFocus(focusBinding: FocusState<EducationFocus?>.Binding?, value: EducationFocus?) -> some View {
        if let binding = focusBinding, let value = value {
            self.focused(binding, equals: value)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyPositionFocus(focusBinding: FocusState<PositionFocus?>.Binding?, value: PositionFocus?) -> some View {
        if let binding = focusBinding, let value = value {
            self.focused(binding, equals: value)
        } else {
            self
        }
    }
}

// MARK: - NRIC Field (with masking)

struct NRICField: View {
    let label: String
    @Binding var text: String
    var errorMessage: String? = nil
    var isValid: Bool = false
    var focusBinding: FocusState<PersonalDetailsFocus?>.Binding? = nil
    var focusValue: PersonalDetailsFocus? = nil

    @FocusState private var isFocused: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var errorVisible: Bool = false
    @State private var borderPulse: Bool = false

    // Local text buffer for keystroke isolation
    @State private var localText: String = ""
    @State private var isShaking: Bool = false

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var accessibilityLabelText: String {
        var labelText = label
        if let error = errorMessage {
            labelText += ", Error: \(error)"
        } else if isValid {
            labelText += ", valid"
        }
        return labelText
    }

    private var accessibilityValueText: String {
        if localText.isEmpty {
            return "empty"
        }
        if isFocused {
            return localText
        }
        // When not focused, report the masked value
        if isValid {
            return "Masked as \(NRICMasker.mask(localText))"
        }
        return localText
    }

    private var displayText: String {
        if isFocused || localText.isEmpty {
            return localText
        }
        return NRICMasker.mask(localText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()
                .accessibilityHidden(true)

            ZStack(alignment: .trailing) {
                TextField("e.g., S1234567A", text: $localText)
                    .font(.system(size: 20))
                    .foregroundColor(.darkText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isFocused ? Color.orangeLight : Color.lightBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                errorMessage != nil ? Color.errorRed :
                                    (isFocused ? Color.affOrange : Color.dividerSubtle),
                                lineWidth: errorMessage != nil ? (borderPulse ? 2.5 : 1.5) : 1
                            )
                            .allowsHitTesting(false)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.affOrange.opacity(0.3 * glowOpacity), lineWidth: 2)
                            .opacity(glowOpacity)
                            .allowsHitTesting(false)
                    )
                    .focused($isFocused)
                    .applyFocus(focusBinding: focusBinding, value: focusValue)
                    .accessibilityLabel(accessibilityLabelText)
                    .accessibilityValue(accessibilityValueText)
                    .accessibilityHint("Enter your NRIC or FIN number, for example S1234567A. It will be masked when not editing.")
                    .onChange(of: localText) { _, _ in
                        // No sync during typing — flush happens on focus loss
                    }
                    .opacity(isFocused || localText.isEmpty ? 1 : 0)

                // Masked overlay — covers TextField when unfocused to hide raw NRIC on public kiosk
                if !isFocused && !localText.isEmpty {
                    Text(displayText)
                        .font(.system(size: 20))
                        .foregroundColor(.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.lightBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    errorMessage != nil ? Color.errorRed : Color.dividerSubtle,
                                    lineWidth: errorMessage != nil ? (borderPulse ? 2.5 : 1.5) : 1
                                )
                                .allowsHitTesting(false)
                        )
                        .onTapGesture { isFocused = true }
                }

                if isValid && !isFocused {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.system(size: 20))
                        .padding(.trailing, 16)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .offset(x: shakeOffset)
            .onChange(of: isFocused) { _, focused in
                glowOpacity = focused ? 1 : 0
                if !focused {
                    flushToBinding()
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .opacity(errorVisible ? 1 : 0)
                    .offset(y: errorVisible ? 0 : 6)
                    .onAppear {
                        triggerNRICErrorAnimation()
                    }
                    .onDisappear {
                        errorVisible = false
                        borderPulse = false
                    }
                    .accessibilityHidden(true)
            }
        }
        .onAppear { localText = text }
        .onChange(of: text) { _, newValue in
            if localText != newValue { localText = newValue }
        }
    }

    // MARK: - Local Buffer Sync

    private func flushToBinding() {
        if text != localText { text = localText }
    }

    // MARK: - Error Animation

    private func triggerNRICErrorAnimation() {
        guard !isShaking else { return }
        isShaking = true

        // Slide error text in from below
        withAnimation(.easeOut(duration: 0.2)) {
            errorVisible = true
        }

        if !reduceMotion {
            // Smooth spring shake: 3 cycles, 6pt amplitude
            let shakeAnim = Animation.spring(response: 0.08, dampingFraction: 0.3)
            withAnimation(shakeAnim) { shakeOffset = 6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(shakeAnim) { shakeOffset = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(shakeAnim) { shakeOffset = 6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(shakeAnim) { shakeOffset = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                withAnimation(shakeAnim) { shakeOffset = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
                    shakeOffset = 0
                }
                isShaking = false
            }
        } else {
            isShaking = false
        }

        // Red border pulse once
        withAnimation(.easeIn(duration: 0.15)) {
            borderPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.25)) {
                borderPulse = false
            }
        }

        // Warning haptic on error
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.warning)
    }
}
