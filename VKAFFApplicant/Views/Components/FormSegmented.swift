import SwiftUI

struct FormSegmented<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T
    var accentColor: Color = .affOrange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .formLabelStyle()

            HStack(spacing: 0) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = option
                        }
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 15, weight: selection == option ? .semibold : .regular))
                            .foregroundColor(selection == option ? .white : .darkText)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                selection == option
                                    ? AnyShape(RoundedRectangle(cornerRadius: 8)).fill(accentColor)
                                    : AnyShape(RoundedRectangle(cornerRadius: 8)).fill(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
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
        }
        .padding(.vertical, 4)
    }
}
