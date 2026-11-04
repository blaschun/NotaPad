// EditorModel.swift
// Zweck: Bildschirmzustand des Editors (aktuelle Seite, Werkzeug, Rückgängig-Status, Seitenliste) – Plan 5.6.
// Die Seitenoperationen stehen in PageOperations.swift.
import SwiftUI
import SwiftData

struct ScrollRequest: Equatable {
    let index: Int
    let token = UUID()
}

@Observable
@MainActor
final class EditorModel {
    let notebook: Notebook
    var pages: [PageInfo] = []
    var currentIndex = 0
    var revision = 0                       // erhöht sich, wenn die Zeichenfläche Seiten neu aufbauen muss
    var thumbVersions: [UUID: Int] = [:]   // pro Seite: erhöht sich, wenn die Miniatur neu gerendert werden soll
    var canUndo = false
    var canRedo = false
    var readOnly: Bool
    var showSidebar = false
    var scrollRequest: ScrollRequest?
    var errorMessage: String?
    var tool = ToolState()

    @ObservationIgnored weak var controller: DocumentViewController?

    init(notebook: Notebook) {
        self.notebook = notebook
        self.readOnly = notebook.isReadOnly
        self.pages = sortedPages().map(PageInfo.init)
        if let id = notebook.lastPageID, let i = pages.firstIndex(where: { $0.id == id }) { currentIndex = i }
    }

    func sortedPages() -> [Page] {
        (notebook.pages ?? []).sorted { $0.order < $1.order }
    }

    func go(to index: Int) {
        guard pages.indices.contains(index) else { return }
        scrollRequest = ScrollRequest(index: index)
    }

    func undo() { controller?.undo() }
    func redo() { controller?.redo() }

    func toggleReadOnly() {
        readOnly.toggle()
        notebook.isReadOnly = readOnly
        try? notebook.modelContext?.save()
    }

    /// Beim Schließen: speichern und Position/Zoom merken (Plan T3.7).
    func closing() {
        controller?.saveAll()
        if pages.indices.contains(currentIndex) { notebook.lastPageID = pages[currentIndex].id }
        if let z = controller?.relativeZoom { notebook.lastZoom = Double(z) }
        notebook.updatedAt = Date()
        tool.save()
        try? notebook.modelContext?.save()
    }
}
