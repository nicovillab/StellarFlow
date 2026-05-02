import SwiftUI

extension Color {

    /// Initializes a `Color` from a 6-digit hex string (with or without `#`). Invalid lengths fall back to white.
    /// - Parameter hex: A hex color string, e.g. `"#FDB813"` or `"FDB813"`.
    init(hex: String) {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hexString.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default:
            (r, g, b) = (255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }

    /// A random color from the curated palette used for newly added bodies.
    /// Picked to look distinct against the dark background and against each other.
    static func randomPalette() -> Color {
        let palette = ["#FF6B9D", "#4ECDC4", "#FFD93D", "#6BCF7F", "#A78BFA", "#F97316"]
        return Color(hex: palette.randomElement() ?? "#FFFFFF")
    }
}
