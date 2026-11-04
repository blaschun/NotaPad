// NewNotebookSheet.swift
// Zweck: Neues Notizbuch mit Titel, Cover, Papier, Format, Ausrichtung (T1.8; Galerien folgen in P4, T4.4/T4.5).
// Die letzte Auswahl wird als Vorschlag für das nächste Mal gemerkt (Plan 4c.2).
import SwiftUI

extension PaperTemplate.Kind {
    var title: String {
        switch self {
        case .blank: return "Leer"
        case .lined: return "Liniert"
        case .narrowLined: return "Eng liniert"
        case .wideLined: return "Weit liniert"
        case .grid: return "Kariert"
        case .dotted: return "Gepunktet"
        case .cornell: return "Cornell"
        case .music: return "Notenpapier"
        case .checklist: return "Checkliste"
        case .weekly: return "Wochenplaner"
        case .millimeter: return "Millimeterpapier"
        }
    }
    var defaultLineSpacingMm: Double {
        switch self {
        case .narrowLined: return 6
        case .wideLined: return 10
        case .grid, .dotted: return 5
        case .millimeter: return 1
        default: return 8
        }
    }
}

private enum SheetFormat: String, CaseIterable, Identifiable {
    case a4, a5, letter, square, wide
    var id: String { rawValue }
    var title: String {
        switch self {
        case .a4: return "A4"
        case .a5: return "A5"
        case .letter: return "US Letter"
        case .square: return "Quadrat"
        case .wide: return "16:9"
        }
    }
    /// Hochformat-Größe in Punkten
    var size: (w: Double, h: Double) {
        switch self {
        case .a4: return PageFormat.a4.width < PageFormat.a4.height ? (PageFormat.a4.width, PageFormat.a4.height) : (PageFormat.a4.height, PageFormat.a4.width)
        case .a5: return (PageFormat.a5.width, PageFormat.a5.height)
        case .letter: return (PageFormat.usLetter.width, PageFormat.usLetter.height)
        case .square: return (595, 595)
        case .wide: return (474, 842)
        }
    }
}

struct NewNotebookSheet: View {
    let folder: Folder?
    let onCreate: (Notebook) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("new.coverHex") private var coverHex = Theme.defaultCoverHex
    @AppStorage("new.useCover") private var useCover = true
    @AppStorage("new.paperKind") private var paperKindRaw = PaperTemplate.Kind.lined.rawValue
    @AppStorage("new.paperColor") private var paperColor = Theme.Paper.white
    @AppStorage("new.format") private var formatRaw = SheetFormat.a4.rawValue
    @AppStorage("new.landscape") private var landscape = false
    @State private var title = "Notizbuch " + NewNotebookSheet.dateText()
    @State private var errorMessage: String?

    private static func dateText() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_AT")
        f.dateFormat = "d. MMM yyyy"
        return f.string(from: Date())
    }

    private let coverColors = ["#3A6FD8", "#2E9E5B", "#D7263D", "#F28C28", "#F2C230", "#8E5BD8", "#E0589B", "#16A6B6",
                               "#7A7A7A", "#A0522D", "#34495E", "#6BBF59", "#1C1C1E", "#5AC8FA", "#FF9F9F", "#B5A642"]
    private let paperColors = [Theme.Paper.white, Theme.Paper.ivory, Theme.Paper.lightGray, Theme.Paper.slate, Theme.Paper.black]

    private var kind: PaperTemplate.Kind { PaperTemplate.Kind(rawValue: paperKindRaw) ?? .lined }
    private var format: SheetFormat { SheetFormat(rawValue: formatRaw) ?? .a4 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titel", text: $title)
                }
                Section("Cover") {
                    Toggle("Cover verwenden", isOn: $useCover)
                    if useCover {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: Theme.Spacing.s) {
                            ForEach(coverColors, id: \.self) { hex in swatch(hex, selected: coverHex == hex) { coverHex = hex } }
                        }
                    }
                }
                Section("Papier") {
                    Picker("Vorlage", selection: $paperKindRaw) {
                        ForEach(PaperTemplate.Kind.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                    }
                    Picker("Format", selection: $formatRaw) {
                        ForEach(SheetFormat.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    Picker("Ausrichtung", selection: $landscape) {
                        Label("Hoch", systemImage: "rectangle.portrait").tag(false)
                        Label("Quer", systemImage: "rectangle").tag(true)
                    }
                    .pickerStyle(.segmented)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: Theme.Spacing.s) {
                        ForEach(paperColors, id: \.self) { hex in swatch(hex, selected: paperColor == hex) { paperColor = hex } }
                    }
                }
            }
            .navigationTitle("Neues Notizbuch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Erstellen", action: create) }
            }
            .alert("Das hat nicht geklappt", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Verstanden", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
        .presentationDetents([.large])
    }

    private func swatch(_ hex: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle().fill(Color(hex: hex)).frame(width: 34, height: 34)
                .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                .overlay(Circle().stroke(Color.accentColor, lineWidth: selected ? 3 : 0).padding(-3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Farbe \(hex)")
    }

    private func create() {
        var paper = PaperTemplate()
        paper.kind = kind
        paper.colorHex = paperColor
        paper.lineSpacingMm = kind.defaultLineSpacingMm
        var cover = CoverStyle()
        cover.kind = useCover ? .solid : .none
        cover.colorHex = coverHex
        let size = format.size
        let (w, h) = landscape ? (size.h, size.w) : (size.w, size.h)
        do {
            let nb = try LibraryService(context: context).createNotebook(title: title, cover: cover, paper: paper, width: w, height: h, in: folder)
            dismiss()
            onCreate(nb)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
