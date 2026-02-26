import SwiftUI

struct BrandedSpinner: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: 48, height: 48)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    Color.affOrange,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(rotation))
                .animation(
                    .linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: rotation
                )
        }
        .onAppear {
            rotation = 360
        }
    }
}
