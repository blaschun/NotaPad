// PaperTemplate.swift
// Zweck: Papiervorlage einer Seite inkl. Feineinstellungen (Plan 3.3, 4d: Standard = liniert 8 mm, weiß, A4 hoch).
import Foundation

struct PaperTemplate: Codable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case blank, lined, narrowLined, wideLined, grid, dotted, cornell, music, checklist, weekly, millimeter
    }

    var kind: Kind = .lined
    var colorHex: String = Theme.Paper.white
    var lineSpacingMm: Double = 8
    var lineColorHex: String = "#C9D3E0"
    var margin: Bool = false
}

/// Seitenformate in PDF-Punkten (1 pt = 1/72 Zoll).
enum PageFormat {
    static let a4 = (width: 595.0, height: 842.0)
    static let a5 = (width: 420.0, height: 595.0)
    static let usLetter = (width: 612.0, height: 792.0)
}
