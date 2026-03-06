import SwiftUI
import UIKit

// Cached formatter to avoid per-keystroke allocations in salary fields
private let salaryFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    return formatter
}()

// MARK: - Padded UITextField

/// UITextField subclass with configurable text insets for internal padding.
/// Ensures the entire visual field area is tappable (no padding outside the UITextField).
class PaddedUITextField: UITextField {
    var textInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }
}

// MARK: - UIKit Text Field (UIViewRepresentable)

/// Zero-lag text input backed by UIKit's UITextField.
/// NO SwiftUI binding — text is synced via onTextCommit callback on focus loss only.
/// NO SwiftUI focus integration — UIKit manages its own first responder.
/// This completely severs the observation chain during typing.
struct UIKitTextField: UIViewRepresentable {
    var initialText: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .allCharacters
    var maxLength: Int? = nil
    var isSalaryField: Bool = false
    var font: UIFont = .systemFont(ofSize: 20)
    var textColor: UIColor = .label
    var textInsets: UIEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
    var onTextCommit: ((String) -> Void)? = nil
    var onReturn: (() -> Void)? = nil
    var onFocusChange: ((Bool) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PaddedUITextField {
        let tf = PaddedUITextField()
        tf.delegate = context.coordinator
        context.coordinator.textField = tf
        tf.textInsets = textInsets
        tf.font = font
        tf.textColor = textColor
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.autocapitalizationType = autocapitalization
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.text = initialText
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Input accessory view with Done button
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        toolbar.items = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(
                title: "Done",
                style: .done,
                target: context.coordinator,
                action: #selector(Coordinator.doneTapped)
            )
        ]
        toolbar.tintColor = UIColor(named: "AFFOrange") ?? .systemOrange
        tf.inputAccessoryView = toolbar

        if isSalaryField {
            tf.addTarget(
                context.coordinator,
                action: #selector(Coordinator.salaryEditingChanged(_:)),
                for: .editingChanged
            )
        }

        return tf
    }

    func updateUIView(_ tf: PaddedUITextField, context: Context) {
        context.coordinator.parent = self
        // Only populate text before the user has ever edited this field.
        // After first edit, UIKit owns the text — never overwrite.
        if !context.coordinator.isEditing && !context.coordinator.hasBeenEdited {
            if tf.text != initialText {
                tf.text = initialText
            }
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitTextField
        var isEditing = false
        var hasBeenEdited = false
        weak var textField: UITextField?

        init(parent: UIKitTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isEditing = true
            hasBeenEdited = true
            parent.onFocusChange?(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isEditing = false
            let finalText = textField.text ?? ""
            parent.onTextCommit?(finalText)
            parent.onFocusChange?(false)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn?()
            textField.resignFirstResponder()
            return true
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard let currentText = textField.text,
                  let swiftRange = Range(range, in: currentText) else {
                return true
            }
            let newText = currentText.replacingCharacters(in: swiftRange, with: string)
            if let max = parent.maxLength, newText.count > max {
                return false
            }
            return true
        }

        @objc func salaryEditingChanged(_ textField: UITextField) {
            let raw = textField.text ?? ""
            let digits = raw.filter { $0.isNumber }
            if let number = Int(digits) {
                let formatted = salaryFormatter.string(from: NSNumber(value: number)) ?? digits
                if textField.text != formatted {
                    textField.text = formatted
                }
            } else if digits.isEmpty {
                textField.text = ""
            }
        }

        @objc func doneTapped() {
            textField?.resignFirstResponder()
        }
    }
}

// MARK: - FormField

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

    // Visual focus state — @State (NOT @FocusState) to avoid SwiftUI focus system conflicts
    @State private var isFieldFocused: Bool = false
    // SwiftUI FocusState only used for multiline TextEditor
    @FocusState private var isTextEditorFocused: Bool

    @State private var shakeOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var errorVisible: Bool = false
    @State private var borderPulse: Bool = false

    // Single-line: local value initialized from binding once, synced back on commit only
    @State private var localValue: String = ""
    @State private var needsInit: Bool = true

    // Multiline: local text buffer (synced on focus loss)
    @State private var localText: String = ""

    private var accessibilityLabelText: String {
        var labelText = label
        if let error = errorMessage {
            labelText += ", Error: \(error)"
        } else if isValid {
            labelText += ", valid"
        }
        return labelText
    }

    private var uiKitAutocapitalization: UITextAutocapitalizationType {
        let desc = String(describing: autocapitalization)
        if desc.contains("never") { return .none }
        if desc.contains("words") { return .words }
        if desc.contains("sentences") { return .sentences }
        return .allCharacters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()
                .accessibilityHidden(true)

            ZStack(alignment: .trailing) {
                if isMultiline {
                    multilineEditor
                } else {
                    singleLineField
                }

                // Valid checkmark
                if isValid && !isFieldFocused {
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
            .onChange(of: isFieldFocused) { _, focused in
                glowOpacity = focused ? 1 : 0
                if !focused && isMultiline && text != localText {
                    // Flush multiline local buffer on focus loss
                    text = localText
                }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .opacity(errorVisible ? 1 : 0)
                    .offset(y: errorVisible ? 0 : 6)
                    .onAppear { triggerErrorAnimation() }
                    .onDisappear {
                        errorVisible = false
                        borderPulse = false
                    }
                    .accessibilityHidden(true)
            }
        }
        .onAppear {
            if needsInit {
                localValue = text
                localText = text
                needsInit = false
            }
        }
    }

    // MARK: - Single-line UIKit field

    private var singleLineField: some View {
        UIKitTextField(
            initialText: localValue,
            placeholder: placeholder,
            keyboardType: keyboardType,
            autocapitalization: uiKitAutocapitalization,
            maxLength: maxLength,
            isSalaryField: isSalaryField,
            font: .systemFont(ofSize: 20),
            textColor: UIColor(named: "DarkText") ?? .label,
            onTextCommit: { newValue in
                localValue = newValue
                guard text != newValue else { return }
                text = newValue
            },
            onReturn: onCommit,
            onFocusChange: { focused in
                isFieldFocused = focused
            }
        )
        .frame(height: 52)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .overlay(focusGlow)
        .compositingGroup()
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(placeholder.isEmpty ? "Enter \(label.lowercased())" : placeholder)
    }

    // MARK: - Multiline SwiftUI TextEditor

    @ViewBuilder
    private var multilineEditor: some View {
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
            .compositingGroup()
            .focused($isTextEditorFocused)
            .applyFocus(focusBinding: focusBinding, value: focusValue)
            .applyEducationFocus(focusBinding: educationFocusBinding, value: educationFocusValue)
            .applyPositionFocus(focusBinding: positionFocusBinding, value: positionFocusValue)
            .onChange(of: localText) { oldValue, newValue in
                guard let max = maxLength, newValue.count > max else { return }
                // Avoid re-triggering onChange by only truncating when actually over limit
                let truncated = String(newValue.prefix(max))
                guard truncated != oldValue else { return }
                localText = truncated
            }
            .onChange(of: isTextEditorFocused) { _, focused in
                isFieldFocused = focused
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
    }

    // MARK: - Error Animation

    private func triggerErrorAnimation() {
        errorVisible = true
        borderPulse = true
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            borderPulse = false
        }
    }

    // MARK: - Visual Components

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isFieldFocused ? Color.orangeLight : Color.lightBackground)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(
                errorMessage != nil ? Color.errorRed :
                    (isFieldFocused ? Color.affOrange : Color.dividerSubtle),
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

// MARK: - Equatable (skip body re-evaluation when visible props unchanged)

extension FormField: Equatable {
    static func == (lhs: FormField, rhs: FormField) -> Bool {
        lhs.label == rhs.label &&
        lhs.placeholder == rhs.placeholder &&
        lhs.isMultiline == rhs.isMultiline &&
        lhs.maxLength == rhs.maxLength &&
        lhs.errorMessage == rhs.errorMessage &&
        lhs.isValid == rhs.isValid &&
        lhs.isSalaryField == rhs.isSalaryField
    }
}

extension NRICField: Equatable {
    static func == (lhs: NRICField, rhs: NRICField) -> Bool {
        lhs.label == rhs.label &&
        lhs.errorMessage == rhs.errorMessage &&
        lhs.isValid == rhs.isValid
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

// MARK: - Focus binding helpers (for multiline TextEditor only)

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

    @State private var isFieldFocused: Bool = false
    @State private var localValue: String = ""
    @State private var needsInit: Bool = true
    @State private var shakeOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var errorVisible: Bool = false
    @State private var borderPulse: Bool = false

    private var accessibilityLabelText: String {
        var labelText = label
        if let error = errorMessage {
            labelText += ", Error: \(error)"
        } else if isValid {
            labelText += ", valid"
        }
        return labelText
    }

    private var displayText: String {
        if isFieldFocused || localValue.isEmpty {
            return localValue
        }
        return NRICMasker.mask(localValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()
                .accessibilityHidden(true)

            ZStack(alignment: .trailing) {
                // UIKit text field — always present, receives taps through masked overlay
                UIKitTextField(
                    initialText: localValue,
                    placeholder: "e.g., S1234567A",
                    autocapitalization: .allCharacters,
                    font: .systemFont(ofSize: 20),
                    textColor: UIColor(named: "DarkText") ?? .label,
                    onTextCommit: { newValue in
                        localValue = newValue
                        guard text != newValue else { return }
                        text = newValue
                    },
                    onFocusChange: { focused in
                        isFieldFocused = focused
                        glowOpacity = focused ? 1 : 0
                    }
                )
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFieldFocused ? Color.orangeLight : Color.lightBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            errorMessage != nil ? Color.errorRed :
                                (isFieldFocused ? Color.affOrange : Color.dividerSubtle),
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
                .compositingGroup()
                .accessibilityLabel(accessibilityLabelText)
                .accessibilityHint("Enter your NRIC or FIN number. It will be masked when not editing.")

                // Masked overlay — hides raw NRIC on public kiosk when not editing.
                // allowsHitTesting(false) lets taps pass through to the UIKit text field behind.
                if !isFieldFocused && !localValue.isEmpty {
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
                        .allowsHitTesting(false)
                }

                if isValid && !isFieldFocused {
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

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .opacity(errorVisible ? 1 : 0)
                    .offset(y: errorVisible ? 0 : 6)
                    .onAppear { triggerNRICErrorAnimation() }
                    .onDisappear {
                        errorVisible = false
                        borderPulse = false
                    }
                    .accessibilityHidden(true)
            }
        }
        .onAppear {
            if needsInit {
                localValue = text
                needsInit = false
            }
        }
    }

    // MARK: - Error Animation

    private func triggerNRICErrorAnimation() {
        errorVisible = true
        borderPulse = true
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            borderPulse = false
        }
    }
}
