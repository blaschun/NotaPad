// LibraryContentView+Actions.swift
// Zweck: Aktionen und Kontextmenüs der Bibliothek (T1.9–T1.12). Fehler landen immer im Fehler-Alert.
import SwiftUI
import SwiftData

extension LibraryContentView {
    func perform(_ work: () throws -> Void) {
        do { try work() } catch { errorMessage = error.localizedDescription }
    }

    func endSelection() {
        selecting = false
        selected = []
    }

    func tap(_ item: LibraryItem) {
        if selecting {
            if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
            return
        }
        switch item {
        case .folder(let f):
            if selection != .trash { searchText = ""; selection = .folder(f.id) }
        case .notebook(let n):
            open(n)
        }
    }

    func open(_ nb: Notebook) {
        perform { try service.markOpened(nb) }
        openNotebook = nb
    }

    func createQuicknote() {
        perform {
            let title = "Quicknote " + DateLabel.text(Date())
            let nb = try service.createNotebook(title: title, kind: .quicknote, in: nil)
            open(nb)
        }
    }

    // MARK: Papierkorb

    func trash(_ list: [LibraryItem]) {
        // Ordner mit Inhalt: erst nachfragen (Plan 4c.1)
        if list.count == 1, case .folder(let f) = list[0], !((f.children ?? []).isEmpty && (f.notebooks ?? []).isEmpty) {
            pending = .trashFolder(f)
            return
        }
        moveToTrash(list)
    }

    func moveToTrash(_ list: [LibraryItem]) {
        perform { for i in list { try service.trash(i) } }
        let message = list.count == 1 ? "„\(list[0].name)“ in den Papierkorb gelegt" : "\(list.count) Elemente in den Papierkorb gelegt"
        toast = Toast(message: message) {
            perform { for i in list { try service.restore(i) } }
        }
    }

    func restore(_ list: [LibraryItem]) {
        var allFound = true
        perform { for i in list { if try !service.restore(i) { allFound = false } } }
        toast = Toast(message: allFound ? "Wiederhergestellt" : "Alter Ort fehlt – oben in Dokumente abgelegt")
    }

    func duplicate(_ list: [LibraryItem]) {
        perform {
            for case .notebook(let n) in list { try service.duplicate(n) }
        }
    }

    func moveDropped(_ ids: [String], to folder: Folder) -> Bool {
        let uuids = ids.compactMap(UUID.init(uuidString:))
        let dragged = (liveFolders.map(LibraryItem.folder) + liveNotebooks.map(LibraryItem.notebook)).filter { uuids.contains($0.id) }
        guard !dragged.isEmpty else { return false }
        perform { for i in dragged { try service.move(i, to: folder) } }
        return true
    }

    // MARK: Bestätigungen

    var confirmTitle: String {
        switch pending {
        case .deletePermanently(let l)?: return l.count == 1 ? "„\(l[0].name)“ endgültig löschen?" : "\(l.count) Elemente endgültig löschen?"
        case .emptyTrash?: return "Papierkorb leeren?"
        case .trashFolder(let f)?: return "Ordner mit \((f.children ?? []).count + (f.notebooks ?? []).count) Elementen in den Papierkorb legen?"
        case nil: return ""
        }
    }

    var confirmMessage: String {
        switch pending {
        case .deletePermanently?: return "Das kann nicht rückgängig gemacht werden."
        case .emptyTrash?: return "\(items.count) Elemente werden endgültig gelöscht."
        case .trashFolder?: return "Du kannst sie 30 Tage lang wiederherstellen."
        case nil: return ""
        }
    }

    var confirmButton: String {
        switch pending {
        case .deletePermanently?: return "Löschen"
        case .emptyTrash?: return "Leeren"
        case .trashFolder?: return "In den Papierkorb"
        case nil: return "OK"
        }
    }

    func confirmPending() {
        guard let p = pending else { return }
        pending = nil
        switch p {
        case .deletePermanently(let l):
            perform { for i in l { try service.deletePermanently(i) } }
            endSelection()
        case .emptyTrash:
            perform { try service.emptyTrash() }
        case .trashFolder(let f):
            moveToTrash([.folder(f)])
        }
    }

    // MARK: Kontextmenü

    @ViewBuilder
    func itemMenu(_ item: LibraryItem) -> some View {
        if item.isTrashed {
            Button("Wiederherstellen", systemImage: "arrow.uturn.backward") { restore([item]) }
            Button("Endgültig löschen", systemImage: "trash", role: .destructive) { pending = .deletePermanently([item]) }
        } else {
            Button("Umbenennen", systemImage: "pencil") { renameText = item.name; renameTarget = item }
            Button(item.isFavorite ? "Aus Favoriten" : "Zu Favoriten", systemImage: item.isFavorite ? "star.slash" : "star") {
                perform { try service.toggleFavorite(item) }
            }
            if case .notebook = item {
                Button("Duplizieren", systemImage: "plus.square.on.square") { duplicate([item]) }
            }
            Button("Verschieben …", systemImage: "folder") { moveItems = [item]; showMove = true }
            Divider()
            Button("In den Papierkorb", systemImage: "trash", role: .destructive) { trash([item]) }
        }
    }
}
