import SwiftUI

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isMultiline: Bool = false
    var maxLength: Int? = nil
    var errorMessage: String? = nil
    var isValid: Bool = false
    var onCommit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()

            ZStack(alignment: .trailing) {
                if isMultiline {
                    TextEditor(text: $text)
                        .font(.system(size: 20))
                        .foregroundColor(.darkText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 130)
                        .padding(12)
                        .background(fieldBackground)
                        .overlay(fieldBorder)
                        .focused($isFocused)
                        .onChange(of: text) { _, newValue in
                            if let max = maxLength, newValue.count > max {
                                text = String(newValue.prefix(max))
                            }
                        }

                    if let max = maxLength {
                        Text("\(text.count)/\(max)")
                            .font(.system(size: 12))
                            .foregroundColor(.mediumGray)
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                            .frame(maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                } else {
                    TextField(placeholder, text: $text, onCommit: {
                        onCommit?()
                    })
                    .font(.system(size: 20))
                    .foregroundColor(.darkText)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .focused($isFocused)
                }

                // Valid checkmark
                if isValid && !isFocused {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.system(size: 20))
                        .padding(.trailing, 16)
                        .transition(.opacity.animation(.easeIn(duration: 0.2)))
                }
            }
            .offset(x: shakeOffset)

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .transition(.opacity)
                    .onAppear {
                        withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                            shakeOffset = 6
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            shakeOffset = 0
                        }
                    }
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
                lineWidth: errorMessage != nil ? 1.5 : 1
            )
    }
}

// MARK: - NRIC Field (with masking)

struct NRICField: View {
    let label: String
    @Binding var text: String
    var errorMessage: String? = nil
    var isValid: Bool = false

    @FocusState private var isFocused: Bool
    @State private var shakeOffset: CGFloat = 0

    private var displayText: String {
        if isFocused || text.isEmpty {
            return text
        }
        return NRICMasker.mask(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()

            ZStack(alignment: .trailing) {
                TextField("e.g., S1234567A", text: $text)
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
                                lineWidth: errorMessage != nil ? 1.5 : 1
                            )
                    )
                    .focused($isFocused)

                if isValid && !isFocused {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.system(size: 20))
                        .padding(.trailing, 16)
                }
            }
            .offset(x: shakeOffset)

            if !isFocused && !text.isEmpty && Validators.isValidNRIC(text) {
                Text("Displayed as: \(NRICMasker.mask(text))")
                    .font(.system(size: 12))
                    .foregroundColor(.mediumGray)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .onAppear {
                        withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                            shakeOffset = 6
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            shakeOffset = 0
                        }
                    }
            }
        }
    }
}
