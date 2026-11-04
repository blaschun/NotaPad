// PruefListeView.swift
// Zweck: Automatische Teile der P0-Prüfliste (Plan 2b, Q1–Q20) direkt in der App testen.
// Die Importe in dieser Datei SIND Prüfpunkt Q1: Kompiliert die App, sind die Frameworks da.
// Nicht automatisch prüfbar (Q6–Q10, Q12, Q19, Q20 …) -> von Hand, Ergebnis in den Plan eintragen.
import SwiftUI
import SwiftData
import PencilKit
import PDFKit
import Vision
import VisionKit
import PhotosUI
import LocalAuthentication
import AVFoundation
import Speech
import Compression
import MetalKit

struct PruefListeView: View {
    @State private var ergebnisse: [(String, Bool, String)] = []
    @AppStorage("pruefliste.startzaehler") private var startzaehler = 0

    var body: some View {
        List {
            Section("Automatisch geprüft") {
                ForEach(Array(ergebnisse.enumerated()), id: \.offset) { _, e in
                    HStack(alignment: .top) {
                        Image(systemName: e.1 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(e.1 ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(e.0).font(.headline)
                            Text(e.2).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Von Hand prüfen (Ergebnis in den Plan eintragen)") {
                Text("Q3/Q4: Daten nach Neustart bzw. Code-Update noch da? Startzähler unten merken.")
                Text("Q5–Q12, Q14, Q19, Q20: siehe Tabelle in Abschnitt 2b des Plans.")
                Text("Startzähler: \(startzaehler)")
            }
        }
        .navigationTitle("Prüfliste P0")
        .onAppear {
            startzaehler += 1
            ergebnisse = laufen()
        }
    }

    private func laufen() -> [(String, Bool, String)] {
        var r: [(String, Bool, String)] = []
        r.append(("Q1 Frameworks importierbar", true, "SwiftData, PencilKit, PDFKit, Vision, VisionKit, PhotosUI, LocalAuthentication, AVFoundation, Speech kompilieren"))
        r.append(("Q2 Liquid Glass", GlassSupport.description.hasPrefix("Liquid"), GlassSupport.description))
        r.append(("Q13 Pencil-Interaktion (Typ vorhanden)", true, "UIPencilInteraction: \(String(describing: UIPencilInteraction.self)) – Squeeze/Hover/Roll im Editor testen (T2.10)"))
        let lz4 = Self.kompressionTest(.lz4), zlib = Self.kompressionTest(.zlib)
        r.append(("Q18 Compression LZ4/ZLIB", lz4 && zlib, "LZ4: \(lz4 ? "ok" : "Fehler"), ZLIB: \(zlib ? "ok" : "Fehler")"))
        r.append(("Q17 Metal verfügbar", MTLCreateSystemDefaultDevice() != nil, "MTLCreateSystemDefaultDevice() – 120/60 Hz später mit MTKView messen"))
        return r
    }

    /// Rundlauf: komprimieren -> dekomprimieren muss das Original ergeben.
    private static func kompressionTest(_ algo: NSData.CompressionAlgorithm) -> Bool {
        let original = Data(String(repeating: "NotaPad ", count: 500).utf8)
        guard let komprimiert = try? (original as NSData).compressed(using: algo) as Data,
              let zurueck = try? (komprimiert as NSData).decompressed(using: algo) as Data
        else { return false }
        return zurueck == original
    }
}
