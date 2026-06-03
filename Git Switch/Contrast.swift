import Foundation

/// sRGB color components in 0...1. Foundation-only so the WCAG math stays unit-testable.
struct RGB: Equatable { let r, g, b: Double }

/// The app's six accent colors, keyed by AppTheme.rawValue.
let accentRGBs: [String: RGB] = [
    "blue":   RGB(r: 0.0,  g: 0.48, b: 1.0),
    "purple": RGB(r: 0.69, g: 0.32, b: 0.87),
    "pink":   RGB(r: 0.94, g: 0.28, b: 0.5),
    "orange": RGB(r: 1.0,  g: 0.58, b: 0.0),
    "green":  RGB(r: 0.2,  g: 0.78, b: 0.35),
    "teal":   RGB(r: 0.0,  g: 0.73, b: 0.82),
]

/// WCAG 2.x relative luminance.
func relativeLuminance(_ c: RGB) -> Double {
    func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
}

/// WCAG contrast ratio (1...21).
func contrastRatio(_ a: RGB, _ b: RGB) -> Double {
    let la = relativeLuminance(a), lb = relativeLuminance(b)
    let hi = max(la, lb), lo = min(la, lb)
    return (hi + 0.05) / (lo + 0.05)
}

/// Chooses the foreground for text/glyphs sitting on an accent fill. White is the
/// conventional on-accent color on macOS, so we keep it whenever it clears a ~4:1 bar
/// (blue, purple); for accents where white is badly sub-threshold (orange/green/teal at
/// ~2.2:1, pink at 3.55:1) we switch to black, which measures 5.9–9.5:1. This fixes the
/// WCAG 1.4.3/1.4.11 failures while preserving the white-on-blue look users expect.
func prefersBlackForeground(on bg: RGB) -> Bool {
    contrastRatio(RGB(r: 1, g: 1, b: 1), bg) < 3.8
}
