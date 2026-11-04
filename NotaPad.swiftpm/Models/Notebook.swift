// Notebook.swift
// Zweck: Ein Dokument der Bibliothek (Notizbuch, Whiteboard, Text-Dokument, Quicknote). Plan 5.3.
// Zeichnungen/Bilder liegen NICHT hier, sondern als Dateien (FileStore); hier nur Metadaten.
import Foundation
import SwiftData

enum NotebookKind: String, Codable, CaseIterable {
    case notebook, whiteboard, textDocument, quicknote
}

@Model
final class Notebook {
    var id: UUID = UUID()
    var title: String = "Unbenannt"
    var kindRaw: String = NotebookKind.notebook.rawValue
    var cover: CoverStyle = CoverStyle()
    var isFavorite: Bool = false
    var isLocked: Bool = false
    var isReadOnly: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastOpenedAt: Date? = nil
    var deletedAt: Date? = nil
    var originalFolderID: UUID? = nil
    var lastPageID: UUID? = nil
    var lastZoom: Double = 1.0
    var scrollDirection: String = "vertical"
    var formatVersion: Int = 1

    var folder: Folder? = nil
    @Relationship(deleteRule: .cascade, inverse: \Page.notebook)
    var pages: [Page]? = []

    var kind: NotebookKind {
        get { NotebookKind(rawValue: kindRaw) ?? .notebook }
        set { kindRaw = newValue.rawValue }
    }

    init(title: String, kind: NotebookKind = .notebook, folder: Folder? = nil) {
        self.title = title
        self.kindRaw = kind.rawValue
        self.folder = folder
    }
}
