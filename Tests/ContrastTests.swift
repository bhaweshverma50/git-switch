import Foundation

// Compile with the real source:
//   swiftc "Git Switch/Contrast.swift" Tests/ContrastTests.swift -o /tmp/contrasttests && /tmp/contrasttests

@main
struct ContrastTests {
    static func main() {
        var failures = 0
        func check(_ cond: Bool, _ msg: String) {
            if cond { print("PASS: \(msg)") } else { print("FAIL: \(msg)"); failures += 1 }
        }
        func approx(_ a: Double, _ b: Double, _ tol: Double = 0.05) -> Bool { abs(a - b) <= tol }

        let black = RGB(r: 0, g: 0, b: 0), white = RGB(r: 1, g: 1, b: 1)
        check(approx(contrastRatio(black, white), 21.0, 0.1), "black/white contrast ~21:1")
        check(approx(contrastRatio(white, white), 1.0), "white/white contrast 1:1")

        // White-on-accent ratios from the review (must match the documented WCAG math).
        check(approx(contrastRatio(white, accentRGBs["orange"]!), 2.21, 0.1), "white-on-orange ~2.21")
        check(approx(contrastRatio(white, accentRGBs["green"]!), 2.22, 0.1), "white-on-green ~2.22")
        check(approx(contrastRatio(white, accentRGBs["teal"]!), 2.34, 0.1), "white-on-teal ~2.34")
        check(approx(contrastRatio(white, accentRGBs["blue"]!), 4.00, 0.15), "white-on-blue ~4.0")

        // The fix: pick the higher-contrast foreground per accent.
        check(prefersBlackForeground(on: accentRGBs["orange"]!), "orange -> black foreground")
        check(prefersBlackForeground(on: accentRGBs["green"]!), "green -> black foreground")
        check(prefersBlackForeground(on: accentRGBs["teal"]!), "teal -> black foreground")
        check(prefersBlackForeground(on: accentRGBs["pink"]!), "pink -> black foreground")
        check(!prefersBlackForeground(on: accentRGBs["blue"]!), "blue -> white foreground")
        check(!prefersBlackForeground(on: accentRGBs["purple"]!), "purple -> white foreground")

        // Every accent's chosen foreground must clear the 3:1 non-text/large-text bar.
        for (name, bg) in accentRGBs {
            let fg = prefersBlackForeground(on: bg) ? black : white
            check(contrastRatio(fg, bg) >= 3.0, "\(name): chosen foreground clears 3:1 (\(String(format: "%.2f", contrastRatio(fg, bg))))")
        }

        if failures == 0 { print("\nALL TESTS PASSED") }
        else { print("\n\(failures) TEST(S) FAILED"); exit(1) }
    }
}
