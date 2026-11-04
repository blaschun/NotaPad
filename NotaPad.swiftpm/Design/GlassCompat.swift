// GlassCompat.swift
// Zweck: Liquid Glass (iPadOS 26) mit Rückfall auf Material (ältere Systeme / älteres SDK). Ticket T0.3 / Prüfpunkt Q2.
// Warum #if compiler(>=6.2): Swift 6.2 gehört zum iOS-26-SDK. Kennt Swift Playgrounds das SDK nicht,
// wird der Glas-Zweig gar nicht erst kompiliert -> kein Compilerfehler, nur der Rückfall.
import SwiftUI

extension View {
    /// Schwebende Leisten/Bedienelemente (niemals auf Inhalt wie das Blatt anwenden – HIG).
    @ViewBuilder
    func notaGlass(cornerRadius: CGFloat = Theme.Radius.popover) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle.nota(cornerRadius))
        }
        #else
        self.background(.ultraThinMaterial, in: RoundedRectangle.nota(cornerRadius))
        #endif
    }
}

/// Meldet, welcher Zweig tatsächlich aktiv ist (für die Prüfliste).
enum GlassSupport {
    static var description: String {
        #if compiler(>=6.2)
        if #available(iOS 26, *) { return "Liquid Glass aktiv (SDK + System ab iPadOS 26)" }
        return "SDK kennt Glas, System ist älter -> Rückfall Material"
        #else
        return "SDK ohne Glas (Swift < 6.2) -> Rückfall Material"
        #endif
    }
}
