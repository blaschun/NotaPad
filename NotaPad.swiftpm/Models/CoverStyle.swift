// CoverStyle.swift
// Zweck: Aussehen des Notizbuch-Covers (Plan 3.3 / 5.4 "cover"). Codable -> direkt in SwiftData und .notapad nutzbar.
import Foundation

struct CoverStyle: Codable, Hashable {
    enum Kind: String, Codable { case solid, pattern, photo, none }

    var kind: Kind = .solid
    var colorHex: String = Theme.defaultCoverHex
    var pattern: String? = nil          // Name des Musters (kind == .pattern)
    var photoFile: String? = nil        // relativer Dateiname (kind == .photo)
    var showTitle: Bool = true
}
