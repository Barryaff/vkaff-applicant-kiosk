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
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardWhite)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .frame(maxWidth: 720)
    }
}
