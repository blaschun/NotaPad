// FileStore.swift
// Zweck: Dateiablage im App-Container: Documents/Notebooks/<id>/… (Ticket T1.3, Plan 5.3).
// Warum atomar: erst in eine temporäre Datei schreiben, dann austauschen -> nie eine halb geschriebene Datei.
import Foundation

struct FileStore {
    enum StoreError: LocalizedError {
        case containerMissing
        var errorDescription: String? { "Der Speicherordner der App wurde nicht gefunden." }
    }

    let root: URL

    /// Standard: <Documents>/Notebooks
    init() throws {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StoreError.containerMissing
        }
        self.root = docs.appendingPathComponent("Notebooks", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    /// Eigener Wurzelordner (für Tests)
    init(root: URL) throws {
        self.root = root
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func directory(for notebookID: UUID) -> URL {
        root.appendingPathComponent(notebookID.uuidString, isDirectory: true)
    }

    @discardableResult
    func createDirectory(for notebookID: UUID) throws -> URL {
        let dir = directory(for: notebookID)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Schreibt Daten atomar in eine Datei unterhalb des Notizbuch-Ordners (Unterordner werden angelegt).
    func write(_ data: Data, notebookID: UUID, relativePath: String) throws {
        let url = directory(for: notebookID).appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    func read(notebookID: UUID, relativePath: String) throws -> Data {
        try Data(contentsOf: directory(for: notebookID).appendingPathComponent(relativePath))
    }

    /// Kopiert den kompletten Notizbuch-Ordner (Duplizieren).
    func copyDirectory(from source: UUID, to target: UUID) throws {
        let fm = FileManager.default
        let src = directory(for: source)
        let dst = directory(for: target)
        if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
        if fm.fileExists(atPath: src.path) {
            try fm.copyItem(at: src, to: dst)
        } else {
            try fm.createDirectory(at: dst, withIntermediateDirectories: true)
        }
    }

    /// Kopiert eine Datei/einen Ordner innerhalb eines Notizbuch-Ordners (z. B. Seite duplizieren). Fehlt die Quelle: nichts tun.
    func copyItem(notebookID: UUID, from source: String, to target: String) throws {
        let fm = FileManager.default
        let base = directory(for: notebookID)
        let src = base.appendingPathComponent(source)
        let dst = base.appendingPathComponent(target)
        guard fm.fileExists(atPath: src.path) else { return }
        try fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
        try fm.copyItem(at: src, to: dst)
    }

    /// Löscht eine Datei/einen Ordner innerhalb eines Notizbuch-Ordners. Fehlt sie, ist das kein Fehler.
    func deleteItem(notebookID: UUID, relativePath: String) throws {
        let url = directory(for: notebookID).appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    /// Löscht den Ordner eines Notizbuchs (endgültiges Löschen). Fehlt er, ist das kein Fehler.
    func deleteDirectory(for notebookID: UUID) throws {
        let dir = directory(for: notebookID)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }
}
