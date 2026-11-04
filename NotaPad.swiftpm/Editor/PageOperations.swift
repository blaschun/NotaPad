// PageOperations.swift
// Zweck: Seiten hinzufügen, duplizieren, löschen, leeren, umsortieren, Lesezeichen, Papier ändern (Ticket T3.2/T3.3/T4.4).
// Vor jeder Operation wird gespeichert; danach baut die Zeichenfläche die Seiten neu auf (revision).
// Offen: Rückgängig für Seitenoperationen und Seite drehen (Plan 4c.5) folgen später.
import SwiftUI
import SwiftData

extension EditorModel {
    private var context: ModelContext? { notebook.modelContext }

    private func renumber(_ list: [Page]) {
        for (i, p) in list.enumerated() { p.order = i }
    }

    /// Liest die Seitenliste neu ein und stößt den Neuaufbau an.
    private func refresh(bumpThumbnails: Bool = false, goTo: Int? = nil) {
        pages = sortedPages().map(PageInfo.init)
        currentIndex = min(goTo ?? currentIndex, max(pages.count - 1, 0))
        revision += 1
        if bumpThumbnails { for p in pages { thumbVersions[p.id, default: 0] += 1 } }
        notebook.updatedAt = Date()
        try? context?.save()
        if let goTo { scrollRequest = ScrollRequest(index: goTo) }
    }

    private func run(_ work: () throws -> Void) {
        do { try work() } catch { errorMessage = error.localizedDescription }
    }

    func addPage() {
        guard let ctx = context else { return }
        controller?.saveAll()
        run {
            var list = sortedPages()
            guard list.indices.contains(currentIndex) else { return }
            let ref = list[currentIndex]
            let page = Page(order: 0, paper: ref.paper, notebook: notebook)
            page.widthPt = ref.widthPt
            page.heightPt = ref.heightPt
            ctx.insert(page)
            list.insert(page, at: currentIndex + 1)
            renumber(list)
            refresh(goTo: currentIndex + 1)
        }
    }

    func duplicatePage(at index: Int) {
        guard let ctx = context else { return }
        controller?.saveAll()
        run {
            var list = sortedPages()
            guard list.indices.contains(index) else { return }
            let src = list[index]
            let copy = Page(order: 0, paper: src.paper, notebook: notebook)
            copy.widthPt = src.widthPt
            copy.heightPt = src.heightPt
            copy.backgroundFile = src.backgroundFile
            copy.backgroundPDFPageIndex = src.backgroundPDFPageIndex
            ctx.insert(copy)
            try FileStore().copyItem(notebookID: notebook.id, from: "pages/\(src.id.uuidString)", to: "pages/\(copy.id.uuidString)")
            list.insert(copy, at: index + 1)
            renumber(list)
            refresh(goTo: index + 1)
        }
    }

    func deletePage(at index: Int) {
        guard let ctx = context else { return }
        var list = sortedPages()
        guard list.indices.contains(index) else { return }
        guard list.count > 1 else {
            errorMessage = "Ein Notizbuch braucht mindestens eine Seite. Du kannst die Seite stattdessen leeren."
            return
        }
        controller?.saveAll()
        run {
            let page = list.remove(at: index)
            controller?.discardPage(page.id)
            try FileStore().deleteItem(notebookID: notebook.id, relativePath: "pages/\(page.id.uuidString)")
            ctx.delete(page)
            renumber(list)
            refresh(goTo: min(index, list.count - 1))
        }
    }

    func clearPage(at index: Int) {
        let list = sortedPages()
        guard list.indices.contains(index) else { return }
        run {
            let id = list[index].id
            controller?.discardPage(id)
            try FileStore().deleteItem(notebookID: notebook.id, relativePath: "pages/\(id.uuidString)")
            thumbVersions[id, default: 0] += 1
            refresh()
        }
    }

    func movePages(from source: IndexSet, to destination: Int) {
        controller?.saveAll()
        var list = sortedPages()
        let currentID = pages.indices.contains(currentIndex) ? pages[currentIndex].id : nil
        list.move(fromOffsets: source, toOffset: destination)
        renumber(list)
        let newIndex = list.firstIndex { $0.id == currentID } ?? currentIndex
        refresh(goTo: newIndex)
    }

    func toggleBookmark(at index: Int) {
        let list = sortedPages()
        guard list.indices.contains(index) else { return }
        list[index].isBookmarked.toggle()
        pages = list.map(PageInfo.init)
        try? context?.save()
    }

    /// Papiervorlage ändern: nur diese Seite oder alle (Plan 3.3 "Vorlage ändern").
    func setPaper(kind: PaperTemplate.Kind, scope: PaperScope) {
        controller?.saveAll()
        let list = sortedPages()
        let targets: [Page]
        switch scope {
        case .current: targets = list.indices.contains(currentIndex) ? [list[currentIndex]] : []
        case .fromCurrent: targets = Array(list.dropFirst(currentIndex))
        case .all: targets = list
        }
        for p in targets {
            p.paper.kind = kind
            p.paper.lineSpacingMm = kind.defaultLineSpacingMm
        }
        refresh(bumpThumbnails: true)
    }

    func setPaperColor(_ hex: String) {
        controller?.saveAll()
        for p in sortedPages() { p.paper.colorHex = hex }
        refresh(bumpThumbnails: true)
    }
}

enum PaperScope { case current, fromCurrent, all }
