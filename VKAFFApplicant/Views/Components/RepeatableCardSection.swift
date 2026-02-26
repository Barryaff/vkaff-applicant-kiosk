import SwiftUI

struct RepeatableCardSection<T: Identifiable, Content: View>: View {
    let title: String
    @Binding var items: [T]
    let maxItems: Int
    let createNew: () -> T
    @ViewBuilder let content: (Binding<T>) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach($items) { $item in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        content($item)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            items.removeAll { $0.id as AnyHashable == item.id as AnyHashable }
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mediumGray)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Remove this \(title.lowercased())")
                    .accessibilityHint("Double tap to remove")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .overlay(
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.purpleLight)
                            .frame(width: 4)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dividerSubtle, lineWidth: 1)
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95, anchor: .top)
                        .combined(with: .opacity)
                        .combined(with: .move(edge: .top)),
                    removal: .scale(scale: 0.95, anchor: .top)
                        .combined(with: .opacity)
                ))
            }

            if items.count < maxItems {
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        items.append(createNew())
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Another \(title)")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.vkaPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                            .foregroundColor(.vkaPurple.opacity(0.4))
                    )
                }
                .accessibilityLabel("Add Another \(title)")
                .accessibilityHint("Adds a new \(title.lowercased()) entry. \(items.count) of \(maxItems) added.")
            }
        }
    }
}
