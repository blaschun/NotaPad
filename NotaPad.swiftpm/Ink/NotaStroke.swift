// NotaStroke.swift
// Zweck: Eigenes Strichformat "NotaStroke" (.nstk) – Hauptquelle aller Tinte (Ticket T2.12, Plan 5.2/5.10).
// Warum: Gespeichert wird nie das PencilKit-Format. PencilKit ist nur Eingabe + Darstellung; die Daten bleiben beim
// späteren Wechsel auf die eigene Engine (NotaInk) und für den GoodNotes-Export gleich.
// Dateiaufbau: "NSTK" + Version (1 Byte) + zlib-komprimiertes JSON.
import Foundation

struct NotaPoint: Codable, Hashable {
    var x: Double
    var y: Double
    var t: Double          // Zeit seit Strichbeginn (s)
    var w: Double          // Breite der Spitze (pt)
    var h: Double          // Höhe der Spitze (pt)
    var opacity: Double
    var force: Double
    var azimuth: Double    // Radiant
    var altitude: Double   // Radiant
}

struct NotaStroke: Codable, Hashable {
    var ink: String                 // pen, pencil, marker, monoline, fountainPen, watercolor, crayon
    var colorHex: String            // #RRGGBB oder #RRGGBBAA
    var points: [NotaPoint]
    var transform: [Double] = [1, 0, 0, 1, 0, 0]   // a, b, c, d, tx, ty
    var createdAt: Double           // Sekunden seit Referenzdatum
}

private struct NotaStrokeFile: Codable {
    var formatVersion: Int = 1
    var strokes: [NotaStroke]
}

enum NotaStrokeCodec {
    enum CodecError: LocalizedError {
        case badHeader, unsupportedVersion(Int)
        var errorDescription: String? {
            switch self {
            case .badHeader: return "Die Zeichnungsdatei ist beschädigt."
            case .unsupportedVersion(let v): return "Die Zeichnungsdatei hat eine neuere Version (\(v)). Bitte aktualisiere NotaPad."
            }
        }
    }

    private static let magic = Data("NSTK".utf8)
    private static let currentVersion: UInt8 = 1

    static func encode(_ strokes: [NotaStroke]) throws -> Data {
        let json = try JSONEncoder().encode(NotaStrokeFile(strokes: strokes))
        let packed = try (json as NSData).compressed(using: .zlib) as Data
        return magic + Data([currentVersion]) + packed
    }

    static func decode(_ data: Data) throws -> [NotaStroke] {
        guard data.count > 5, data.prefix(4) == magic else { throw CodecError.badHeader }
        let version = Int(data[data.startIndex + 4])
        guard version <= Int(currentVersion) else { throw CodecError.unsupportedVersion(version) }
        let packed = data.dropFirst(5)
        let json = try (Data(packed) as NSData).decompressed(using: .zlib) as Data
        return try JSONDecoder().decode(NotaStrokeFile.self, from: json).strokes
    }
}
