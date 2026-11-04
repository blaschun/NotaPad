// LibraryItem.swift
// Zweck: Einheitlicher Typ für "Ordner ODER Notizbuch" in der Bibliothek + Sortierung + Datumstexte (T1.6/T1.7, Plan 4c.1).
import Foundation

enum LibraryItem: Identifiable, Hashable {
    case folder(Folder)
    case notebook(Notebook)

    var id: UUID {
        switch self {
        case .folder(let f): return f.id
        case .notebook(let n): return n.id
        }
    }
    var isFolder: Bool { if case .folder = self { return true } else { return false } }
    var name: String {
        switch self {
        case .folder(let f): return f.name
        case .notebook(let n): return n.title
        }
    }
    var createdAt: Date {
        switch self {
        case .folder(let f): return f.createdAt
        case .notebook(let n): return n.createdAt
        }
    }
    var updatedAt: Date {
        switch self {
        case .folder(let f): return f.updatedAt
        case .notebook(let n): return n.updatedAt
        }
    }
    var lastOpenedAt: Date {
        switch self {
        case .folder: return .distantPast
        case .notebook(let n): return n.lastOpenedAt ?? .distantPast
        }
    }
    var deletedAt: Date? {
        switch self {
        case .folder(let f): return f.deletedAt
        case .notebook(let n): return n.deletedAt
        }
    }
    var isFavorite: Bool {
        switch self {
        case .folder(let f): return f.isFavorite
        case .notebook(let n): return n.isFavorite
        }
    }
    var isTrashed: Bool { deletedAt != nil }
    private var kindOrder: Int {
        if case .notebook(let n) = self { return NotebookKind.allCases.firstIndex(of: n.kind) ?? 0 }
        return -1
    }

    /// Sortiert nach Feld/Richtung; optional Ordner zuerst (Plan 4c.1 "Sortiermenü").
    static func sort(_ items: [LibraryItem], field: LibrarySortField, ascending: Bool, foldersFirst: Bool) -> [LibraryItem] {
        items.sorted { a, b in
            if foldersFirst, a.isFolder != b.isFolder { return a.isFolder }
            let result: ComparisonResult
            switch field {
            case .name: result = a.name.localizedStandardCompare(b.name)
            case .createdAt: result = compare(a.createdAt, b.createdAt)
            case .updatedAt: result = compare(a.updatedAt, b.updatedAt)
            case .lastOpenedAt: result = compare(a.lastOpenedAt, b.lastOpenedAt)
            case .kind:
                result = a.kindOrder == b.kindOrder ? a.name.localizedStandardCompare(b.name) : compare(a.kindOrder, b.kindOrder)
            }
            if result == .orderedSame { return false }
            return ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }

    private static func compare<T: Comparable>(_ a: T, _ b: T) -> ComparisonResult {
        a < b ? .orderedAscending : (a > b ? .orderedDescending : .orderedSame)
    }
}

extension LibrarySortField: Identifiable {
    var id: String { rawValue }
    var title: String {
        switch self {
        case .updatedAt: return "Datum geändert"
        case .createdAt: return "Datum erstellt"
        case .name: return "Name"
        case .lastOpenedAt: return "Zuletzt geöffnet"
        case .kind: return "Typ"
        }
    }
}

extension Folder {
    /// Liegt der Ordner selbst oder einer seiner Vorfahren im Papierkorb?
    var isTrashed: Bool {
        var current: Folder? = self
        while let c = current {
            if c.deletedAt != nil { return true }
            current = c.parent
        }
        return false
    }
}

extension Notebook {
    var isTrashed: Bool { deletedAt != nil || (folder?.isTrashed ?? false) }
}

/// Datumstexte nach Plan 4c.1: "Heute, 14:32" · "Gestern" · "Mo." · "2. Nov." · "2. Nov. 2025"
enum DateLabel {
    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_AT")
        f.dateFormat = format
        return f
    }

    static func text(_ date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        if cal.isDate(date, inSameDayAs: now) { return "Heute, " + formatter("HH:mm").string(from: date) }
        if let y = cal.date(byAdding: .day, value: -1, to: now), cal.isDate(date, inSameDayAs: y) { return "Gestern" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 99
        if days > 0 && days < 7 { return formatter("EEE").string(from: date) }
        if cal.component(.year, from: date) == cal.component(.year, from: now) { return formatter("d. MMM").string(from: date) }
        return formatter("d. MMM yyyy").string(from: date)
    }
}
