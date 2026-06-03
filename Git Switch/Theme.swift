import SwiftUI

// MARK: - Accent color + WCAG-aware foreground

extension AppTheme {
    /// Raw sRGB components (single source of truth in Contrast.swift).
    var rgb: RGB { accentRGBs[rawValue] ?? RGB(r: 0, g: 0.48, b: 1) }

    var color: Color { Color(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b) }

    /// Legible foreground for text/glyphs drawn on this accent fill (fixes the
    /// white-on-orange/green/teal/pink WCAG failures; keeps white on blue/purple).
    var onAccent: Color { prefersBlackForeground(on: rgb) ? .black : .white }
}

// MARK: - Spacing scale (4pt grid)

enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner radii

enum Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let card: CGFloat = 12   // standard card radius (was a mix of 12/14)
}

// MARK: - Shadows

extension View {
    /// One standard card shadow, scheme-aware (visible on dark backgrounds too).
    func cardShadow(hovering: Bool = false) -> some View {
        shadow(color: .black.opacity(hovering ? 0.16 : 0.10),
               radius: hovering ? 10 : 6, y: hovering ? 3 : 2)
    }
}

// MARK: - App version (read from the bundle, not hardcoded)

enum AppInfo {
    static var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }
}
