// PageInfo.swift
// Zweck: Leichter, unveränderlicher Auszug einer Seite für Zeichenfläche und Miniaturen (kein SwiftData-Objekt,
// daher in Hintergrund-Aufgaben nutzbar).
import Foundation

struct PageInfo: Identifiable, Hashable, Sendable {
    let id: UUID
    var width: Double
    var height: Double
    var paper: PaperTemplate
    var isBookmarked: Bool = false

    init(_ page: Page) {
        id = page.id
        width = page.widthPt
        height = page.heightPt
        paper = page.paper
        isBookmarked = page.isBookmarked
    }
}
