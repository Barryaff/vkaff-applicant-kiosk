import SwiftUI

struct LanguageChipSelector: View {
    @Binding var selectedLanguages: [LanguageProficiency]
    @State private var othersText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language Proficiency")
                .formLabelStyle()

            // Language chips
            FlowLayout(spacing: 10) {
                ForEach(Language.allCases, id: \.self) { language in
                    LanguageChip(
                        language: language,
                        isSelected: isSelected(language),
                        onTap: { toggleLanguage(language) }
                    )
                }
            }

            // Proficiency controls for selected languages
            ForEach($selectedLanguages) { $langProf in
                if langProf.language != .others || !langProf.customLanguage.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(langProf.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.darkText)

                        HStack(spacing: 0) {
                            ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        langProf.proficiency = level
                                    }
                                    let haptic = UISelectionFeedbackGenerator()
                                    haptic.selectionChanged()
                                } label: {
                                    Text(level.rawValue)
                                        .font(.system(size: 13, weight: langProf.proficiency == level ? .semibold : .regular))
                                        .foregroundColor(langProf.proficiency == level ? .white : .darkText)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            langProf.proficiency == level
                                                ? AnyShape(RoundedRectangle(cornerRadius: 6)).fill(Color.vkaPurple)
                                                : AnyShape(RoundedRectangle(cornerRadius: 6)).fill(Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(langProf.displayName) proficiency: \(level.rawValue)")
                                .accessibilityValue(langProf.proficiency == level ? "selected" : "not selected")
                                .accessibilityAddTraits(langProf.proficiency == level ? [.isSelected] : [])
                            }
                        }
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purpleLight.opacity(0.5))
                        )
                    }
                    .padding(.horizontal, 4)
                }
            }

            // Others text field
            if isSelected(.others) {
                FormField(
                    label: "Other Language",
                    text: Binding(
                        get: { selectedLanguages.first(where: { $0.language == .others })?.customLanguage ?? "" },
                        set: { newValue in
                            if let index = selectedLanguages.firstIndex(where: { $0.language == .others }) {
                                selectedLanguages[index].customLanguage = newValue
                            }
                        }
                    ),
                    placeholder: "Enter language name"
                )
            }
        }
    }

    private func isSelected(_ language: Language) -> Bool {
        selectedLanguages.contains { $0.language == language }
    }

    private func toggleLanguage(_ language: Language) {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            if let index = selectedLanguages.firstIndex(where: { $0.language == language }) {
                selectedLanguages.remove(at: index)
            } else {
                selectedLanguages.append(LanguageProficiency(language: language))
            }
        }
    }
}

// MARK: - Single Chip

struct LanguageChip: View {
    let language: Language
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(language.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .darkText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.affOrange : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.affOrange : Color.dividerSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language.rawValue)
        .accessibilityValue(isSelected ? "selected" : "not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to \(isSelected ? "remove" : "add") \(language.rawValue)")
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
