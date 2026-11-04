// PaperRenderer.swift
// Zweck: Zeichnet alle Papiervorlagen vektorbasiert mit Core Graphics (Ticket T4.1/T4.2, Plan 3.3).
// Ein Renderer für alles: Bildschirm (PaperView), Miniatur, später PDF-Export -> was man sieht, ist was man exportiert.
// Thread-sicher (nur Core Graphics, keine UI-Objekte), Ursprung oben links.
import UIKit

enum PaperRenderer {
    static let mm: CGFloat = 72 / 25.4

    static func draw(_ paper: PaperTemplate, size: CGSize, in ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }

        let background = UIColor(hex: paper.colorHex)
        ctx.setFillColor(background.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))

        // Auf dunklem Papier hellere Linien verwenden
        let dark = luminance(background) < 0.35
        let lineColor = dark ? UIColor(hex: "#5A5A5E") : UIColor(hex: paper.lineColorHex)
        ctx.setStrokeColor(lineColor.cgColor)
        ctx.setFillColor(lineColor.cgColor)
        ctx.setLineWidth(0.5)

        let sp = max(CGFloat(paper.lineSpacingMm) * mm, 2)
        let w = size.width, h = size.height

        func hLine(_ y: CGFloat, from x0: CGFloat = 0, to x1: CGFloat? = nil) {
            ctx.move(to: CGPoint(x: x0, y: y)); ctx.addLine(to: CGPoint(x: x1 ?? w, y: y)); ctx.strokePath()
        }
        func vLine(_ x: CGFloat, from y0: CGFloat = 0, to y1: CGFloat? = nil) {
            ctx.move(to: CGPoint(x: x, y: y0)); ctx.addLine(to: CGPoint(x: x, y: y1 ?? h)); ctx.strokePath()
        }

        switch paper.kind {
        case .blank:
            break

        case .lined, .narrowLined, .wideLined:
            var y = sp * 3
            while y < h - sp { hLine(y); y += sp }
            if paper.margin {
                ctx.setStrokeColor(UIColor(hex: dark ? "#8A4A4A" : "#E8A0A0").cgColor)
                vLine(25 * mm)
            }

        case .grid:
            var y = sp
            while y < h { hLine(y); y += sp }
            var x = sp
            while x < w { vLine(x); x += sp }

        case .dotted:
            let r: CGFloat = 0.7
            var y = sp
            while y < h {
                var x = sp
                while x < w { ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)); x += sp }
                y += sp
            }

        case .millimeter:
            let step = mm
            var i = 0
            var y: CGFloat = 0
            while y <= h {
                ctx.setLineWidth(i % 10 == 0 ? 0.6 : (i % 5 == 0 ? 0.4 : 0.2)); hLine(y); y += step; i += 1
            }
            i = 0
            var x: CGFloat = 0
            while x <= w {
                ctx.setLineWidth(i % 10 == 0 ? 0.6 : (i % 5 == 0 ? 0.4 : 0.2)); vLine(x); x += step; i += 1
            }

        case .cornell:
            let headerY = h * 0.1, summaryY = h * 0.82, cueX = w * 0.28
            ctx.setLineWidth(1)
            hLine(headerY); hLine(summaryY); vLine(cueX, from: headerY, to: summaryY)
            ctx.setLineWidth(0.5)
            var y = headerY + sp
            while y < summaryY - sp * 0.5 { hLine(y, from: cueX); y += sp }

        case .music:
            // Notensysteme: 5 Linien (Abstand 2 mm), alle 22 mm ein System
            let gap = 2 * mm, systemHeight = gap * 4, pitch = 22 * mm
            var top = 18 * mm
            while top + systemHeight < h - 10 * mm {
                for k in 0..<5 { hLine(top + CGFloat(k) * gap, from: 12 * mm, to: w - 12 * mm) }
                vLine(12 * mm, from: top, to: top + systemHeight)
                vLine(w - 12 * mm, from: top, to: top + systemHeight)
                top += pitch
            }

        case .checklist:
            var y = sp * 3
            let box = min(sp * 0.55, 5 * mm)
            while y < h - sp {
                hLine(y)
                ctx.stroke(CGRect(x: 14 * mm, y: y - sp / 2 - box / 2, width: box, height: box))
                y += sp
            }

        case .weekly:
            let top = 14 * mm
            let rowH = (h - top - 10 * mm) / 7
            ctx.setLineWidth(1); hLine(top)
            ctx.setLineWidth(0.5)
            for k in 1...7 { hLine(top + CGFloat(k) * rowH) }
            vLine(28 * mm, from: top, to: top + 7 * rowH)
        }
    }

    private static func luminance(_ c: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}
