// CoverView.swift
// Zweck: Zeichnet das Cover eines Notizbuchs (einfarbig / ohne; Muster und Foto folgen in P4, T4.5).
import SwiftUI

struct CoverView: View {
    let cover: CoverStyle
    let title: String
    var aspect: CGFloat = 1 / 1.414   // Breite / Höhe; A4 hoch

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle().fill(cover.kind == .none ? Color(hex: Theme.Paper.white) : Color(hex: cover.colorHex))
            if cover.kind != .none && cover.showTitle {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .padding(Theme.Spacing.xs)
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle.nota(Theme.Radius.cover))
        .overlay(RoundedRectangle.nota(Theme.Radius.cover).stroke(Color(.separator), lineWidth: 0.5))
    }
}
