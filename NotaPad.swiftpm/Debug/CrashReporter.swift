// CrashReporter.swift
// Zweck: Ohne Xcode/Debugger sichtbar machen, WARUM und WO die App abstürzt (Plan 2b "Debugging", Risiko 1).
// So geht's: Beim Start wird die Konsole (stderr, dort steht z. B. "Fatal error: …") in eine Datei umgeleitet und
// Signal-/Ausnahme-Handler schreiben bei einem Absturz die Aufrufliste samt "letztem Schritt" in eine zweite Datei.
// Beim nächsten Start zeigt CrashReportView diesen Bericht an (kopierbar), bevor irgendetwas anderes passiert.
import Foundation

enum CrashReporter {
    /// Wird an wichtigen Stellen gesetzt; steht im Bericht als "Letzter Schritt".
    nonisolated(unsafe) static var step = "App-Start"
    nonisolated(unsafe) private static var prepared = false
    nonisolated(unsafe) private static var cachedReport: String?

    private static var directory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private static var crashURL: URL { directory.appendingPathComponent("letzter-absturz.txt") }
    private static var consoleURL: URL { directory.appendingPathComponent("konsole.log") }

    /// Liest einen eventuellen Bericht vom letzten Absturz und aktiviert die Überwachung. Mehrfach aufrufbar.
    static func prepare() -> String? {
        if prepared { return cachedReport }
        prepared = true

        if let crash = try? String(contentsOf: crashURL, encoding: .utf8) {
            let console = (try? String(contentsOf: consoleURL, encoding: .utf8)) ?? ""
            cachedReport = crash + "\n\n--- Konsole (Ende) ---\n" + String(console.suffix(3000))
            try? FileManager.default.removeItem(at: crashURL)
        }

        // Konsole in Datei umleiten, damit "Fatal error: …" nach einem Absturz lesbar bleibt
        freopen(consoleURL.path, "w", stderr)

        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.write("Ausnahme: \(exception.name.rawValue)\n\(exception.reason ?? "")\n"
                                + exception.callStackSymbols.joined(separator: "\n"))
        }
        for sig in [SIGABRT, SIGILL, SIGTRAP, SIGSEGV, SIGBUS, SIGFPE] {
            signal(sig) { s in
                CrashReporter.write("Signal \(s)\n" + Thread.callStackSymbols.joined(separator: "\n"))
                signal(s, SIG_DFL)
                raise(s)
            }
        }
        return cachedReport
    }

    private static func write(_ text: String) {
        let full = "Letzter Schritt: \(step)\nZeit: \(Date())\n\n\(text)"
        try? full.write(to: crashURL, atomically: true, encoding: .utf8)
    }
}
