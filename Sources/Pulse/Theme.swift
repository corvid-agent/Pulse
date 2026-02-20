import SwiftUI

enum Theme {
    static let accent = Color(red: 0.4, green: 0.9, blue: 0.6)
    static let dimmed = Color.white.opacity(0.5)
    static let surface = Color.white.opacity(0.06)
    static let border = Color.white.opacity(0.1)

    static let monoSmall = Font.system(size: 11, design: .monospaced)
    static let monoBody = Font.system(size: 12, design: .monospaced)
    static let monoTitle = Font.system(size: 13, weight: .semibold, design: .monospaced)

    static let windowWidth: CGFloat = 380
    static let windowHeight: CGFloat = 520
    static let cornerRadius: CGFloat = 8
    static let padding: CGFloat = 10
}
