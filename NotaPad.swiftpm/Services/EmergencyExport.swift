// EmergencyExport.swift
// Zweck: Notfall-Export (Ticket T4.8): kompletter Datenordner + JSON-Liste aller Notizbücher als ZIP.
// Pflicht vor der ersten echten Nutzung, solange es kein richtiges Backup gibt (Plan 2b "Datensicherheit").
import Foundation
import SwiftData

@MainActor
enum EmergencyExport {
    private struct NotebookEntry: Codable {
        let id: UUID
        let title: String
        let kind: String
        let folderPath: String
        let pageCount: Int
        let createdAt: Date
        let updatedAt: Date
        let deleted: Bool
    }

    private static func folderPath(_ folder: Folder?) -> String {
        var names: [String] = []
        var current = folder
        while let c = current { names.insert(c.name, at: 0); current = c.parent }
        return names.joined(separator: "/")
    }

    /// Erstellt die ZIP-Datei im temporären Ordner und gibt ihre URL zurück.
    static func create(context: ModelContext) throws -> URL {
        let store = try FileStore()
        let notebooks = try context.fetch(FetchDescriptor<Notebook>())
        let list = notebooks.map {
            NotebookEntry(id: $0.id, title: $0.title, kind: $0.kindRaw, folderPath: folderPath($0.folder),
                          pageCount: ($0.pages ?? []).count, createdAt: $0.createdAt, updatedAt: $0.updatedAt,
                          deleted: $0.isTrashed)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let json = try encoder.encode(list)

        var files: [(path: String, source: URL)] = []
        if let walker = FileManager.default.enumerator(at: store.root, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let url as URL in walker {
                guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
                let relative = url.path.replacingOccurrences(of: store.root.path, with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/\\"))
                files.append(("Notebooks/" + relative, url))
            }
        }

        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let target = FileManager.default.temporaryDirectory.appendingPathComponent("NotaPad-Export-\(stamp).zip")
        try SimpleZip.write(to: target, files: files, extra: [("notebooks.json", json)])
        return target
    }
}
