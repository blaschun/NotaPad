// PencilKitBridge.swift
// Zweck: Konverter PKDrawing <-> [NotaStroke] (Ticket T2.12). PencilKit liefert Eingabe + Darstellung, gespeichert wird NotaStroke.
// Bekannte Grenze: Radier-Masken (Pixel-Radierer) werden nicht gespeichert -> es wird nur der Strich-Radierer angeboten.
import UIKit
import PencilKit

extension UIColor {
    convenience init(hex: String) {
        let (r, g, b, a) = Color.parseHex(hex)
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        func c(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        if a >= 0.999 { return String(format: "#%02X%02X%02X", c(r), c(g), c(b)) }
        return String(format: "#%02X%02X%02X%02X", c(r), c(g), c(b), c(a))
    }
}

import SwiftUI   // für Color.parseHex

enum PencilKitBridge {
    static func inkName(_ type: PKInk.InkType) -> String {
        switch type {
        case .pen: return "pen"
        case .pencil: return "pencil"
        case .marker: return "marker"
        case .monoline: return "monoline"
        case .fountainPen: return "fountainPen"
        case .watercolor: return "watercolor"
        case .crayon: return "crayon"
        @unknown default: return "pen"
        }
    }

    static func inkType(_ name: String) -> PKInk.InkType {
        switch name {
        case "pencil": return .pencil
        case "marker": return .marker
        case "monoline": return .monoline
        case "fountainPen": return .fountainPen
        case "watercolor": return .watercolor
        case "crayon": return .crayon
        default: return .pen
        }
    }

    static func strokes(from drawing: PKDrawing) -> [NotaStroke] {
        drawing.strokes.map { s in
            var points: [NotaPoint] = []
            for p in s.path {
                points.append(NotaPoint(x: Double(p.location.x), y: Double(p.location.y), t: p.timeOffset,
                                        w: Double(p.size.width), h: Double(p.size.height), opacity: Double(p.opacity),
                                        force: Double(p.force), azimuth: Double(p.azimuth), altitude: Double(p.altitude)))
            }
            let t = s.transform
            return NotaStroke(ink: inkName(s.ink.inkType), colorHex: s.ink.color.hexString, points: points,
                              transform: [Double(t.a), Double(t.b), Double(t.c), Double(t.d), Double(t.tx), Double(t.ty)],
                              createdAt: s.path.creationDate.timeIntervalSinceReferenceDate)
        }
    }

    static func drawing(from strokes: [NotaStroke]) -> PKDrawing {
        var result: [PKStroke] = []
        for s in strokes where !s.points.isEmpty {
            let controls = s.points.map {
                PKStrokePoint(location: CGPoint(x: $0.x, y: $0.y), timeOffset: $0.t,
                              size: CGSize(width: $0.w, height: $0.h), opacity: CGFloat($0.opacity),
                              force: CGFloat($0.force), azimuth: CGFloat($0.azimuth), altitude: CGFloat($0.altitude))
            }
            let path = PKStrokePath(controlPoints: controls, creationDate: Date(timeIntervalSinceReferenceDate: s.createdAt))
            let ink = PKInk(inkType(s.ink), color: UIColor(hex: s.colorHex))
            let m = s.transform.count == 6 ? s.transform : [1, 0, 0, 1, 0, 0]
            let transform = CGAffineTransform(a: m[0], b: m[1], c: m[2], d: m[3], tx: m[4], ty: m[5])
            result.append(PKStroke(ink: ink, path: path, transform: transform, mask: nil))
        }
        return PKDrawing(strokes: result)
    }
}
