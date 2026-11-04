// LibraryService.swift
// Zweck: Alle Aktionen der Bibliothek an einer Stelle (Anlegen, Umbenennen, Duplizieren, Verschieben, Papierkorb).
// Warum eigener Typ: Views zeigen nur an und rufen diese Methoden auf (Plan 5.6). Fehler werden geworfen, nie verschluckt.
// Papierkorb-Prinzip: Beim Löschen wird das Element vom Elternordner gelöst (originalFolderID/originalParentID merkt den Ort)
// und bekommt deletedAt. Inhalte eines gelöschten Ordners bleiben in ihm; sie gelten über Folder.isTrashed als gelöscht.
import Foundation
import SwiftData

@MainActor
struct LibraryService {
    let context: ModelContext

    enum ServiceError: LocalizedError {
        case invalidMove
        var errorDescription: String? {
            "Ein Ordner kann nicht in sich selbst oder in einen seiner Unterordner verschoben werden."
        }
    }

    // MARK: Suchen

    func folder(id: UUID) -> Folder? {
        var d = FetchDescriptor<Folder>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }

    func notebook(id: UUID) -> Notebook? {
        var d = FetchDescriptor<Notebook>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }

    private func cleaned(_ name: String, fallback: String = "Unbenannt") -> String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? fallback : t
    }

    // MARK: Anlegen

    @discardableResult
    func createNotebook(title: String, kind: NotebookKind = .notebook, cover: CoverStyle = CoverStyle(),
                        paper: PaperTemplate = PaperTemplate(), width: Double = PageFormat.a4.width,
                        height: Double = PageFormat.a4.height, in folder: Folder?) throws -> Notebook {
        let nb = Notebook(title: cleaned(title), kind: kind, folder: folder)
        nb.cover = cover
        let page = Page(order: 0, paper: paper, notebook: nb)
        page.widthPt = width
        page.heightPt = height
        context.insert(nb)
        context.insert(page)
        try FileStore().createDirectory(for: nb.id)
        try context.save()
        return nb
    }

    @discardableResult
    func createFolder(name: String, colorHex: String = "#3A6FD8", symbol: String = "folder.fill", in parent: Folder?) throws -> Folder {
        let f = Folder(name: cleaned(name, fallback: "Neuer Ordner"), parent: parent)
        f.colorHex = colorHex
        f.symbolName = symbol
        context.insert(f)
        try context.save()
        return f
    }

    // MARK: Ändern

    func rename(_ item: LibraryItem, to name: String) throws {
        switch item {
        case .folder(let f): f.name = cleaned(name, fallback: "Neuer Ordner"); f.updatedAt = Date()
        case .notebook(let n): n.title = cleaned(name); n.updatedAt = Date()
        }
        try context.save()
    }

    func toggleFavorite(_ item: LibraryItem) throws {
        switch item {
        case .folder(let f): f.isFavorite.toggle()
        case .notebook(let n): n.isFavorite.toggle()
        }
        try context.save()
    }

    func markOpened(_ nb: Notebook) throws {
        nb.lastOpenedAt = Date()
        try context.save()
    }

    @discardableResult
    func duplicate(_ nb: Notebook) throws -> Notebook {
        let copy = Notebook(title: nb.title + " Kopie", kind: nb.kind, folder: nb.folder)
        copy.cover = nb.cover
        copy.scrollDirection = nb.scrollDirection
        context.insert(copy)
        // Seiten behalten ihre IDs: Dateien liegen pro Notizbuch-Ordner, die Kopie bekommt eine eigene Dateikopie.
        for p in (nb.pages ?? []).sorted(by: { $0.order < $1.order }) {
            let c = Page(order: p.order, paper: p.paper, notebook: copy)
            c.id = p.id
            c.widthPt = p.widthPt
            c.heightPt = p.heightPt
            c.rotation = p.rotation
            c.backgroundFile = p.backgroundFile
            c.backgroundPDFPageIndex = p.backgroundPDFPageIndex
            c.isBookmarked = p.isBookmarked
            context.insert(c)
        }
        try FileStore().copyDirectory(from: nb.id, to: copy.id)
        try context.save()
        return copy
    }

    // MARK: Verschieben

    /// Prüft, ob `target` der Ordner `folder` selbst oder einer seiner Nachfahren ist.
    func isSelfOrDescendant(_ target: Folder?, of folder: Folder) -> Bool {
        var current = target
        while let c = current {
            if c.id == folder.id { return true }
            current = c.parent
        }
        return false
    }

    func move(_ item: LibraryItem, to target: Folder?) throws {
        switch item {
        case .notebook(let n):
            n.folder = target
        case .folder(let f):
            if isSelfOrDescendant(target, of: f) { throw ServiceError.invalidMove }
            f.parent = target
        }
        try context.save()
    }

    // MARK: Papierkorb

    func trash(_ item: LibraryItem) throws {
        switch item {
        case .notebook(let n):
            n.originalFolderID = n.folder?.id
            n.folder = nil
            n.deletedAt = Date()
        case .folder(let f):
            f.originalParentID = f.parent?.id
            f.parent = nil
            f.deletedAt = Date()
        }
        try context.save()
    }

    /// Stellt wieder her. Gibt false zurück, wenn der alte Ort fehlt (Element landet dann oben).
    @discardableResult
    func restore(_ item: LibraryItem) throws -> Bool {
        var foundOriginal = true
        func target(_ id: UUID?) -> Folder? {
            guard let id else { return nil }
            if let f = folder(id: id), !f.isTrashed { return f }
            foundOriginal = false
            return nil
        }
        switch item {
        case .notebook(let n):
            n.folder = target(n.originalFolderID)
            n.deletedAt = nil
            n.originalFolderID = nil
        case .folder(let f):
            f.parent = target(f.originalParentID)
            f.deletedAt = nil
            f.originalParentID = nil
        }
        try context.save()
        return foundOriginal
    }

    func deletePermanently(_ item: LibraryItem) throws {
        let store = try FileStore()
        switch item {
        case .notebook(let n):
            try store.deleteDirectory(for: n.id)
            context.delete(n)
        case .folder(let f):
            for id in notebookIDs(in: f) { try store.deleteDirectory(for: id) }
            context.delete(f)   // Kaskade löscht Unterordner, Notizbücher, Seiten
        }
        try context.save()
    }

    private func notebookIDs(in folder: Folder) -> [UUID] {
        (folder.notebooks ?? []).map(\.id) + (folder.children ?? []).flatMap(notebookIDs(in:))
    }

    func trashedItems() -> [LibraryItem] {
        let fs = (try? context.fetch(FetchDescriptor<Folder>(predicate: #Predicate { $0.deletedAt != nil }))) ?? []
        let ns = (try? context.fetch(FetchDescriptor<Notebook>(predicate: #Predicate { $0.deletedAt != nil }))) ?? []
        return fs.map(LibraryItem.folder) + ns.map(LibraryItem.notebook)
    }

    func emptyTrash() throws {
        for item in trashedItems() { try deletePermanently(item) }
    }

    /// Beim App-Start: Elemente, die länger als `days` Tage im Papierkorb liegen, endgültig löschen.
    func purgeExpired(days: Int) throws {
        guard let limit = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return }
        for item in trashedItems() where (item.deletedAt ?? Date()) < limit {
            try deletePermanently(item)
        }
    }
}
