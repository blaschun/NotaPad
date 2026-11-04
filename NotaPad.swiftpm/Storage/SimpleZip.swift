// SimpleZip.swift
// Zweck: Minimaler ZIP-Schreiber (Methode "gespeichert", ohne Kompression) für den Notfall-Export (T4.8).
// Warum selbst: iPadOS hat keine öffentliche ZIP-Schnittstelle (Plan 5.4). Die Tinte ist ohnehin schon zlib-komprimiert.
// Dateien werden einzeln gelesen und sofort geschrieben, damit der Speicher nicht explodiert.
import Foundation

enum SimpleZip {
    private static let crcTable: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
        return c
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        for b in data { c = crcTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        return c ^ 0xFFFFFFFF
    }

    private struct Entry { let name: String; let crc: UInt32; let size: UInt32; let offset: UInt32 }

    private static func le16(_ v: UInt16) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
    private static func le32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }

    enum ZipError: LocalizedError {
        case tooLarge(String)
        var errorDescription: String? {
            switch self {
            case .tooLarge(let n): return "Die Datei „\(n)“ ist für den ZIP-Export zu groß (über 4 GB)."
            }
        }
    }

    /// Packt `files` (Pfad im ZIP -> Quelldatei oder direkte Daten) in `destination`.
    static func write(to destination: URL, files: [(path: String, source: URL)], extra: [(path: String, data: Data)] = []) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: destination.path) { try fm.removeItem(at: destination) }
        fm.createFile(atPath: destination.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destination)
        defer { try? handle.close() }

        var entries: [Entry] = []
        var offset: UInt64 = 0

        func add(name: String, data: Data) throws {
            guard data.count < Int(UInt32.max), offset < UInt64(UInt32.max) else { throw ZipError.tooLarge(name) }
            let nameData = Data(name.utf8)
            let crc = crc32(data)
            var header = Data()
            header += le32(0x04034b50); header += le16(20); header += le16(0x0800); header += le16(0)
            header += le16(0); header += le16(0x21)               // Zeit 00:00, Datum 1980-01-01
            header += le32(crc); header += le32(UInt32(data.count)); header += le32(UInt32(data.count))
            header += le16(UInt16(nameData.count)); header += le16(0)
            header += nameData
            try handle.write(contentsOf: header)
            try handle.write(contentsOf: data)
            entries.append(Entry(name: name, crc: crc, size: UInt32(data.count), offset: UInt32(offset)))
            offset += UInt64(header.count + data.count)
        }

        for f in files { try add(name: f.path, data: try Data(contentsOf: f.source, options: .mappedIfSafe)) }
        for e in extra { try add(name: e.path, data: e.data) }

        let centralStart = offset
        var central = Data()
        for e in entries {
            let nameData = Data(e.name.utf8)
            central += le32(0x02014b50); central += le16(20); central += le16(20); central += le16(0x0800); central += le16(0)
            central += le16(0); central += le16(0x21)
            central += le32(e.crc); central += le32(e.size); central += le32(e.size)
            central += le16(UInt16(nameData.count)); central += le16(0); central += le16(0)
            central += le16(0); central += le16(0); central += le32(0); central += le32(e.offset)
            central += nameData
        }
        try handle.write(contentsOf: central)

        var end = Data()
        end += le32(0x06054b50); end += le16(0); end += le16(0)
        end += le16(UInt16(entries.count)); end += le16(UInt16(entries.count))
        end += le32(UInt32(central.count)); end += le32(UInt32(centralStart)); end += le16(0)
        try handle.write(contentsOf: end)
    }
}
