// Color+Hex.swift
// Zweck: HEX-Strings ("#RRGGBB" / "#RRGGBBAA") <-> SwiftUI-Color (Ticket T1.1).
// Warum: Farben werden im Dateiformat als HEX gespeichert (Plan 5.4).
import SwiftUI
import UIKit

extension Color {
    /// Erzeugt eine Farbe aus "#RRGGBB" oder "#RRGGBBAA". Ungültige Eingaben ergeben Schwarz.
    init(hex: String) {
        let (r, g, b, a) = Color.parseHex(hex)
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Zerlegt den HEX-String; jeder Wert wird auf 0...1 begrenzt.
    static func parseHex(_ hex: String) -> (Double, Double, Double, Double) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard (s.count == 6 || s.count == 8), let value = UInt64(s, radix: 16) else {
            return (0, 0, 0, 1)
        }
        let hasAlpha = s.count == 8
        let r = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = Double((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = Double((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? Double(value & 0xFF) / 255 : 1
        return (r, g, b, a)
    }

    /// Gibt "#RRGGBB" (bzw. "#RRGGBBAA", wenn nicht deckend) zurück.
    func hexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        func c(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        if a >= 0.999 { return String(format: "#%02X%02X%02X", c(r), c(g), c(b)) }
        return String(format: "#%02X%02X%02X%02X", c(r), c(g), c(b), c(a))
    }
}
