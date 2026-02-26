import SwiftUI

// MARK: - Typography View Modifiers

struct HeadingStyle: ViewModifier {
    var size: CGFloat = 28
    var weight: Font.Weight = .semibold
    var color: Color = .navy

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .default))
            .foregroundColor(color)
            .tracking(-0.5)
    }
}

struct SubheadingStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 22, weight: .medium, design: .default))
            .foregroundColor(.navy)
            .tracking(-0.3)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .regular, design: .default))
            .foregroundColor(.darkText)
            .lineSpacing(4)
    }
}

struct LabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .medium, design: .default))
            .foregroundColor(.bodyGray)
    }
}

struct SectionLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundColor(.gold)
            .tracking(3)
            .textCase(.uppercase)
    }
}

struct InputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 20, weight: .regular, design: .default))
            .foregroundColor(.darkText)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(.bodyGray)
    }
}

// MARK: - View Extension

extension View {
    func headingStyle(size: CGFloat = 28) -> some View {
        modifier(HeadingStyle(size: size))
    }

    func subheadingStyle() -> some View {
        modifier(SubheadingStyle())
    }

    func bodyStyle() -> some View {
        modifier(BodyStyle())
    }

    func formLabelStyle() -> some View {
        modifier(LabelStyle())
    }

    func sectionLabelStyle() -> some View {
        modifier(SectionLabelStyle())
    }

    func inputStyle() -> some View {
        modifier(InputStyle())
    }

    func captionStyle() -> some View {
        modifier(CaptionStyle())
    }
}
