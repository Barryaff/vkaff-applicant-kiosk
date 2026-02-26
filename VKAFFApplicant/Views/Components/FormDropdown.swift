import SwiftUI

struct FormDropdown<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T
    var options: [T]? = nil
    var errorMessage: String? = nil

    var body: some View {
        let displayOptions = options ?? Array(T.allCases)

        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .formLabelStyle()
                .accessibilityHidden(true)

            Menu {
                ForEach(displayOptions, id: \.self) { option in
                    Button(option.rawValue) {
                        selection = option
                        let haptic = UISelectionFeedbackGenerator()
                        haptic.selectionChanged()
                    }
                }
            } label: {
                HStack {
                    Text(selection.rawValue)
                        .font(.system(size: 18))
                        .foregroundColor(.darkText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.mediumGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.lightBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.dividerSubtle, lineWidth: 1)
                )
            }
            .accessibilityLabel("\(label), dropdown")
            .accessibilityValue(selection.rawValue)
            .accessibilityHint("Double tap to choose a different option")

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }
}
