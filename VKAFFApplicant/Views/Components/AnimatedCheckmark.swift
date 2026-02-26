import SwiftUI

struct AnimatedCheckmark: View {
    @State private var drawProgress: CGFloat = 0
    @State private var circleScale: CGFloat = 0.5
    @State private var circleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Outer gold ring
            Circle()
                .stroke(Color.gold.opacity(0.3), lineWidth: 1.5)
                .frame(width: 100, height: 100)
                .scaleEffect(circleScale)
                .opacity(circleOpacity)

            // Navy filled circle
            Circle()
                .fill(Color.navyLight)
                .frame(width: 90, height: 90)
                .scaleEffect(circleScale)
                .opacity(circleOpacity)

            // Gold checkmark
            CheckmarkShape()
                .trim(from: 0, to: drawProgress)
                .stroke(
                    Color.gold,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 40, height: 30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                circleScale = 1.0
                circleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                drawProgress = 1.0
            }
        }
        .accessibilityLabel("Success checkmark")
        .accessibilityHidden(true)
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.1, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.15))

        return path
    }
}
