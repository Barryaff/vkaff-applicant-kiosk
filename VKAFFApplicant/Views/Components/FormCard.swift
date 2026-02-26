import SwiftUI

struct FormCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            content
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
        )
        .frame(maxWidth: 860)
    }
}
