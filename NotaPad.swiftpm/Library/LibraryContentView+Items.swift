// LibraryContentView+Items.swift
// Zweck: Welche Elemente zeigt die Bibliothek gerade (Bereich, Suche, Sortierung)? (T1.7, T1.13)
import SwiftUI
import SwiftData

extension LibraryContentView {
    var service: LibraryService { LibraryService(context: context) }

    var liveFolders: [Folder] { allFolders.filter { !$0.isTrashed } }
    var liveNotebooks: [Notebook] { allNotebooks.filter { !$0.isTrashed } }

    var currentFolder: Folder? {
        if case .folder(let id) = selection { return allFolders.first { $0.id == id } }
        return nil
    }

    var title: String {
        switch selection {
        case .documents: return "Dokumente"
        case .recents: return "Zuletzt"
        case .favorites: return "Favoriten"
        case .quicknotes: return "Quicknotes"
        case .trash: return "Papierkorb"
        case .folder: return currentFolder?.name ?? "Ordner"
        }
    }

    /// Vorfahren-Kette inklusive des Ordners selbst, von oben nach unten.
    func path(to folder: Folder) -> [Folder] {
        var chain: [Folder] = []
        var current: Folder? = folder
        while let c = current { chain.insert(c, at: 0); current = c.parent }
        return chain
    }

    var items: [LibraryItem] {
        // Suche: über alle nicht gelöschten Ordner und Notizbücher (Titel, Umlaut- und Groß/Klein-tolerant)
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty, selection != .trash {
            let q = searchText.trimmingCharacters(in: .whitespaces)
            let found = liveFolders.filter { $0.name.localizedStandardContains(q) }.map(LibraryItem.folder)
                + liveNotebooks.filter { $0.title.localizedStandardContains(q) }.map(LibraryItem.notebook)
            return LibraryItem.sort(found, field: .name, ascending: true, foldersFirst: true)
        }

        switch selection {
        case .recents:
            let recent = liveNotebooks.filter { $0.lastOpenedAt != nil }
                .sorted { ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
            return recent.prefix(30).map(LibraryItem.notebook)
        case .trash:
            let all = allFolders.filter { $0.deletedAt != nil }.map(LibraryItem.folder)
                + allNotebooks.filter { $0.deletedAt != nil }.map(LibraryItem.notebook)
            return all.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
        default:
            break
        }

        let base: [LibraryItem]
        switch selection {
        case .documents:
            base = liveFolders.filter { $0.parent == nil }.map(LibraryItem.folder)
                + liveNotebooks.filter { $0.folder == nil && $0.kind != .quicknote }.map(LibraryItem.notebook)
        case .favorites:
            base = liveFolders.filter(\.isFavorite).map(LibraryItem.folder)
                + liveNotebooks.filter(\.isFavorite).map(LibraryItem.notebook)
        case .quicknotes:
            base = liveNotebooks.filter { $0.kind == .quicknote }.map(LibraryItem.notebook)
        case .folder:
            guard let f = currentFolder else { return [] }
            base = (f.children ?? []).filter { $0.deletedAt == nil }.map(LibraryItem.folder)
                + (f.notebooks ?? []).filter { $0.deletedAt == nil }.map(LibraryItem.notebook)
        default:
            base = []
        }
        return LibraryItem.sort(base, field: sortField, ascending: sortAscending, foldersFirst: foldersFirst)
    }

    // MARK: Sortierung pro Ordner gemerkt (Wurzel + Sonderbereiche: AppStorage)

    var sortField: LibrarySortField { LibrarySortField(rawValue: currentFolder?.sortField ?? rootSortField) ?? .updatedAt }
    var sortAscending: Bool { currentFolder?.sortAscending ?? rootSortAscending }
    var foldersFirst: Bool { currentFolder?.foldersFirst ?? rootFoldersFirst }

    var sortFieldBinding: Binding<LibrarySortField> {
        Binding(get: { sortField }, set: { v in
            if let f = currentFolder { f.sortField = v.rawValue } else { rootSortField = v.rawValue }
        })
    }
    var sortAscendingBinding: Binding<Bool> {
        Binding(get: { sortAscending }, set: { v in
            if let f = currentFolder { f.sortAscending = v } else { rootSortAscending = v }
        })
    }
    var foldersFirstBinding: Binding<Bool> {
        Binding(get: { foldersFirst }, set: { v in
            if let f = currentFolder { f.foldersFirst = v } else { rootFoldersFirst = v }
        })
    }
}
