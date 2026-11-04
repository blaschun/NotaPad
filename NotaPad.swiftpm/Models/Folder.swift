// Folder.swift
// Zweck: Ordner der Bibliothek (Plan 5.3). Verschachtelbar, Papierkorb über deletedAt.
// Regeln: alle Felder mit Standardwert, Beziehungen optional, kein .unique (CloudKit-tauglich, Plan 12.7).
import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID = UUID()
    var name: String = "Neuer Ordner"
    var colorHex: String = "#3A6FD8"
    var symbolName: String = "folder.fill"
    var isFavorite: Bool = false
    var sortField: String = LibrarySortField.updatedAt.rawValue
    var sortAscending: Bool = false
    var foldersFirst: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date? = nil
    var originalParentID: UUID? = nil     // für "Wiederherstellen" aus dem Papierkorb

    var parent: Folder? = nil
    @Relationship(deleteRule: .cascade, inverse: \Folder.parent)
    var children: [Folder]? = []
    @Relationship(deleteRule: .cascade, inverse: \Notebook.folder)
    var notebooks: [Notebook]? = []

    init(name: String = "Neuer Ordner", parent: Folder? = nil) {
        self.name = name
        self.parent = parent
    }
}

/// Sortierfelder der Bibliothek (Plan 4c.1), als String gespeichert.
enum LibrarySortField: String, CaseIterable {
    case updatedAt, createdAt, name, lastOpenedAt, kind
}
