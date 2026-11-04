// EditorToolbar.swift
// Zweck: Kopfzeile (Zurück, Seitenleiste, Werkzeuge, Rückgängig, Mehr-Menü) und Unterleiste (Farb- und Stärken-Favoriten)
// – Tickets T2.5, T2.6, T3.6. Zweites Antippen des aktiven Werkzeugs öffnet das Options-Popover (Plan 4.3).
import SwiftUI

struct EditorTopBar: View {
    @Bindable var model: EditorModel
    let title: String
    let onClose: () -> Void
    @State private var popoverTool: EditorTool?

    private let tools: [(EditorTool, String, String)] = [
        (.pen, "pencil.tip", "Stift"),
        (.highlighter, "highlighter", "Textmarker"),
        (.eraser, "eraser", "Radierer"),
        (.lasso, "lasso", "Lasso"),
    ]

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Button(action: onClose) {
                Image(systemName: "chevron.left").frame(width: Theme.Hit.minimum, height: Theme.Hit.minimum)
            }
            .accessibilityLabel("Zurück zur Bibliothek")

            Button { model.showSidebar.toggle() } label: {
                Image(systemName: "sidebar.left").frame(width: Theme.Hit.minimum, height: Theme.Hit.minimum)
            }
            .accessibilityLabel("Seitenleiste ein- oder ausblenden")

            Text(title).font(.headline).lineLimit(1).frame(maxWidth: 220, alignment: .leading)

            Spacer(minLength: Theme.Spacing.s)

            HStack(spacing: 2) {
                ForEach(tools, id: \.0) { tool, symbol, name in
                    toolButton(tool, symbol, name)
                }
                Button {
                    model.tool.settings.ruler.toggle()
                } label: {
                    Image(systemName: "ruler")
                        .frame(width: Theme.Hit.tool, height: Theme.Hit.tool)
                        .background(RoundedRectangle.nota(12).fill(model.tool.settings.ruler ? Color.accentColor.opacity(0.2) : .clear))
                }
                .accessibilityLabel("Lineal")
            }
            .padding(.horizontal, Theme.Spacing.xs)
            .notaGlass(cornerRadius: 26)

            Spacer(minLength: Theme.Spacing.s)

            Button { model.undo() } label: {
                Image(systemName: "arrow.uturn.backward").frame(width: Theme.Hit.minimum, height: Theme.Hit.minimum)
            }
            .disabled(!model.canUndo)
            .accessibilityLabel("Rückgängig")
            Button { model.redo() } label: {
                Image(systemName: "arrow.uturn.forward").frame(width: Theme.Hit.minimum, height: Theme.Hit.minimum)
            }
            .disabled(!model.canRedo)
            .accessibilityLabel("Wiederholen")

            moreMenu
        }
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.xxs)
    }

    private func toolButton(_ tool: EditorTool, _ symbol: String, _ name: String) -> some View {
        let isActive = model.tool.settings.tool == tool
        return Button {
            if isActive, tool != .lasso {
                popoverTool = tool
            } else {
                withAnimation(Theme.Motion.toolSwitch) { model.tool.settings.tool = tool }
            }
        } label: {
            Image(systemName: symbol)
                .symbolVariant(isActive ? .fill : .none)
                .font(.title3)
                .frame(width: Theme.Hit.tool, height: Theme.Hit.tool)
                .background(RoundedRectangle.nota(12).fill(isActive ? Color.accentColor.opacity(0.2) : .clear))
        }
        .sensoryFeedback(.selection, trigger: model.tool.settings.tool)
        .accessibilityLabel(name)
        .popover(isPresented: Binding(get: { popoverTool == tool }, set: { if !$0 { popoverTool = nil } })) {
            ToolOptionsPopover(tool: model.tool)
                .presentationCompactAdaptation(.popover)
        }
    }

    private var moreMenu: some View {
        Menu {
            Section("Seite") {
                Button("Seite hinzufügen", systemImage: "plus.square") { model.addPage() }
                Button("Seite duplizieren", systemImage: "plus.square.on.square") { model.duplicatePage(at: model.currentIndex) }
                Button(model.pages.indices.contains(model.currentIndex) && model.pages[model.currentIndex].isBookmarked
                       ? "Lesezeichen entfernen" : "Lesezeichen setzen", systemImage: "bookmark") {
                    model.toggleBookmark(at: model.currentIndex)
                }
                Button("Seite leeren", systemImage: "eraser.line.dashed") { model.clearPage(at: model.currentIndex) }
                Button("Seite löschen", systemImage: "trash", role: .destructive) { model.deletePage(at: model.currentIndex) }
            }
            Section("Papier") {
                Menu("Vorlage für diese Seite") {
                    ForEach(PaperTemplate.Kind.allCases, id: \.rawValue) { k in
                        Button(k.title) { model.setPaper(kind: k, scope: .current) }
                    }
                }
                Menu("Vorlage für alle Seiten") {
                    ForEach(PaperTemplate.Kind.allCases, id: \.rawValue) { k in
                        Button(k.title) { model.setPaper(kind: k, scope: .all) }
                    }
                }
                Menu("Papierfarbe (alle Seiten)") {
                    Button("Weiß") { model.setPaperColor(Theme.Paper.white) }
                    Button("Elfenbein") { model.setPaperColor(Theme.Paper.ivory) }
                    Button("Hellgrau") { model.setPaperColor(Theme.Paper.lightGray) }
                    Button("Schiefer") { model.setPaperColor(Theme.Paper.slate) }
                    Button("Schwarz") { model.setPaperColor(Theme.Paper.black) }
                }
            }
            Section("Ansicht & Eingabe") {
                Toggle("Nur Lesen", isOn: Binding(get: { model.readOnly }, set: { _ in model.toggleReadOnly() }))
                Toggle("Mit Finger zeichnen", isOn: $model.tool.settings.fingerDrawing)
            }
        } label: {
            Image(systemName: "ellipsis.circle").frame(width: Theme.Hit.minimum, height: Theme.Hit.minimum)
        }
        .accessibilityLabel("Mehr")
    }
}

struct EditorSubBar: View {
    @Bindable var model: EditorModel

    var body: some View {
        let tool = model.tool
        Group {
            switch tool.settings.tool {
            case .pen, .highlighter:
                HStack(spacing: Theme.Spacing.m) {
                    ForEach(Array(tool.colors.enumerated()), id: \.offset) { i, hex in
                        Button { tool.selectColor(i) } label: {
                            Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: tool.colorIndex == i ? 3 : 0).padding(-4))
                                .frame(width: Theme.Hit.minimum, height: Theme.Hit.minimum)
                        }
                        .accessibilityLabel("Farbe \(i + 1)")
                    }
                    Divider().frame(height: 26)
                    ForEach(Array(tool.widths.enumerated()), id: \.offset) { i, mm in
                        Button { tool.selectWidth(i) } label: {
                            Circle().fill(Color.primary)
                                .frame(width: dotSize(mm), height: dotSize(mm))
                                .frame(width: Theme.Hit.minimum, height: Theme.Hit.minimum)
                                .background(Circle().fill(tool.widthIndex == i ? Color.accentColor.opacity(0.2) : .clear).padding(4))
                        }
                        .accessibilityLabel("Stärke \(String(format: "%.1f", mm)) Millimeter")
                    }
                }
            case .eraser:
                Picker("Radieren auf", selection: $model.tool.settings.eraserTarget) {
                    ForEach(EraserTarget.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            case .lasso:
                Text("Zeichne einen Kreis um Striche, um sie zu verschieben.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .frame(minHeight: 48)
        .notaGlass(cornerRadius: 24)
        .padding(.bottom, Theme.Spacing.xxs)
        .animation(Theme.Motion.toolSwitch, value: tool.settings.tool)
    }

    private func dotSize(_ mm: Double) -> CGFloat { CGFloat(min(max(mm * 6 + 4, 6), 26)) }
}
