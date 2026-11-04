// Page.swift
// Zweck: Eine Seite eines Notizbuchs. Koordinaten/Größe in PDF-Punkten (Plan 5.4).
// Die Tinte (.nstk) liegt als Datei im FileStore, hier stehen nur Metadaten.
import Foundation
import SwiftData

@Model
final class Page {
    var id: UUID = UUID()
    var order: Int = 0
    var paper: PaperTemplate = PaperTemplate()
    var widthPt: Double = PageFormat.a4.width
    var heightPt: Double = PageFormat.a4.height
    var rotation: Int = 0                         // 0, 90, 180, 270
    var backgroundFile: String? = nil             // PDF-Seite / Bild (relativ zum Notizbuch-Ordner)
    var backgroundPDFPageIndex: Int? = nil
    var isBookmarked: Bool = false
    var thumbnailFile: String? = nil
    var thumbnailUpdatedAt: Date? = nil
    var ocrStatus: String = "pending"

    var notebook: Notebook? = nil

    init(order: Int, paper: PaperTemplate = PaperTemplate(), notebook: Notebook? = nil) {
        self.order = order
        self.paper = paper
        self.notebook = notebook
    }
}
