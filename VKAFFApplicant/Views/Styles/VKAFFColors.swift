import SwiftUI

extension Color {
    // MARK: - Brand Primary
    static let affOrange = Color(hex: "D64C01")
    static let vkaPurple = Color(hex: "462E8C")

    // MARK: - Extended Palette
    static let orangeLight = Color(hex: "F5E6D9")
    static let orangePress = Color(hex: "B84000")
    static let purpleLight = Color(hex: "EDE8F5")
    static let purpleDeep = Color(hex: "2E1D5E")
    static let darkText = Color(hex: "1A1A1A")
    static let mediumGray = Color(hex: "6B7280")
    static let lightBackground = Color(hex: "FAFAF8")
    static let cardWhite = Color.white
    static let successGreen = Color(hex: "1B7A3D")
    static let errorRed = Color(hex: "C0392B")
    static let dividerSubtle = Color(hex: "E5E7EB")

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
