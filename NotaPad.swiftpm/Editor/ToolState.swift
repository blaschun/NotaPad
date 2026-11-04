// ToolState.swift
// Zweck: Aktives Werkzeug + Einstellungen pro Werkzeug, dauerhaft gespeichert (Ticket T2.4, Plan 4d/4b).
// Favoriten-Prinzip wie bei GoodNotes: 3 Farb- und 3 Stärken-Plätze; eine neue Farbe ersetzt den gewählten Platz.
import SwiftUI
import PencilKit

enum EditorTool: String, Codable, CaseIterable {
    case pen, highlighter, eraser, lasso
}

enum PenKind: String, Codable, CaseIterable, Identifiable {
    case fountain, ballpoint, brush, pencil
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fountain: return "Füller"
        case .ballpoint: return "Kugelschreiber"
        case .brush: return "Pinsel"
        case .pencil: return "Bleistift"
        }
    }
    var inkType: PKInkingTool.InkType {
        switch self {
        case .fountain: return .fountainPen
        case .ballpoint: return .pen
        case .brush: return .watercolor
        case .pencil: return .pencil
        }
    }
}

enum EraserTarget: String, Codable, CaseIterable, Identifiable {
    case ink, marker
    var id: String { rawValue }
    var title: String { self == .ink ? "Tinte" : "Textmarker" }
}

struct ToolSettings: Codable, Equatable {
    var tool: EditorTool = .pen
    var penKind: PenKind = .fountain
    var penColors = ["#000000", "#1F5FD6", "#D7263D"]
    var penWidths = [0.3, 0.5, 0.8]            // mm
    var penColorIndex = 0
    var penWidthIndex = 1
    var markerColors = ["#FFE14D", "#7BE07B", "#FF8AD8"]
    var markerWidths = [3.0, 5.0, 8.0]         // mm
    var markerColorIndex = 0
    var markerWidthIndex = 1
    var eraserTarget: EraserTarget = .ink
    var ruler = false
    var fingerDrawing = false
}

/// Alles, was die Zeichenflächen für das aktuelle Werkzeug brauchen.
struct ActiveTool {
    var tool: PKTool
    var targetsMarker: Bool     // true = Marker-Ebene bedienen, false = Tinten-Ebene
    var ruler: Bool
    var finger: Bool
    var readOnly: Bool
}

@Observable
final class ToolState {
    private static let key = "tool.settings"
    var settings: ToolSettings

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let s = try? JSONDecoder().decode(ToolSettings.self, from: data) {
            settings = s
        } else {
            settings = ToolSettings()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    var usesMarkerSlots: Bool { settings.tool == .highlighter }

    var colors: [String] { usesMarkerSlots ? settings.markerColors : settings.penColors }
    var widths: [Double] { usesMarkerSlots ? settings.markerWidths : settings.penWidths }
    var colorIndex: Int { usesMarkerSlots ? settings.markerColorIndex : settings.penColorIndex }
    var widthIndex: Int { usesMarkerSlots ? settings.markerWidthIndex : settings.penWidthIndex }

    var colorHex: String {
        get { colors[min(colorIndex, colors.count - 1)] }
        set {
            if usesMarkerSlots { settings.markerColors[settings.markerColorIndex] = newValue }
            else { settings.penColors[settings.penColorIndex] = newValue }
        }
    }

    var widthMm: Double {
        get { widths[min(widthIndex, widths.count - 1)] }
        set {
            let v = min(max(newValue, 0.1), 20)
            if usesMarkerSlots { settings.markerWidths[settings.markerWidthIndex] = v }
            else { settings.penWidths[settings.penWidthIndex] = v }
        }
    }

    func selectColor(_ i: Int) {
        if usesMarkerSlots { settings.markerColorIndex = i } else { settings.penColorIndex = i }
    }
    func selectWidth(_ i: Int) {
        if usesMarkerSlots { settings.markerWidthIndex = i } else { settings.penWidthIndex = i }
    }

    func activeTool(readOnly: Bool) -> ActiveTool {
        let mmToPt = 72.0 / 25.4
        let tool: PKTool
        var marker = false
        switch settings.tool {
        case .pen:
            let w = min(max(settings.penWidths[settings.penWidthIndex] * mmToPt, 0.5), 40)
            tool = PKInkingTool(settings.penKind.inkType, color: UIColor(hex: settings.penColors[settings.penColorIndex]), width: w)
        case .highlighter:
            marker = true
            let w = min(max(settings.markerWidths[settings.markerWidthIndex] * mmToPt, 2), 60)
            tool = PKInkingTool(.marker, color: UIColor(hex: settings.markerColors[settings.markerColorIndex]), width: w)
        case .eraser:
            marker = settings.eraserTarget == .marker
            tool = PKEraserTool(.vector)
        case .lasso:
            tool = PKLassoTool()
        }
        return ActiveTool(tool: tool, targetsMarker: marker, ruler: settings.ruler,
                          finger: settings.fingerDrawing, readOnly: readOnly)
    }
}
