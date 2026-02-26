import SwiftUI

struct FormSegmented<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T
    var accentColor: Color = .affOrange

    @Namespace private var segmentedNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .formLabelStyle()
                .accessibilityHidden(true)

            HStack(spacing: 0) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selection = option
                        }
                        let haptic = UISelectionFeedbackGenerator()
                        haptic.selectionChanged()
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 15, weight: selection == option ? .semibold : .regular))
                            .foregroundColor(selection == option ? .white : .darkText)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background {
                                if selection == option {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(accentColor)
                                        .matchedGeometryEffect(id: "segmentIndicator", in: segmentedNamespace)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label): \(option.rawValue)")
                    .accessibilityValue(selection == option ? "selected" : "not selected")
                    .accessibilityAddTraits(selection == option ? [.isSelected] : [])
                    .accessibilityHint("Double tap to select \(option.rawValue)")
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.lightBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.dividerSubtle, lineWidth: 1)
            )
        }
    }
}

// MARK: - Toggle with label

struct FormToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.darkText)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(.affOrange)
                .labelsHidden()
                .accessibilityLabel(label)
                .accessibilityValue(isOn ? "on" : "off")
                .accessibilityHint("Double tap to toggle")
        }
        .padding(.vertical, 4)
    }
}
