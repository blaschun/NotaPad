// EditorView.swift
// Zweck: Editor-Bildschirm: Seitenleiste, Kopfzeile, Unterleiste, Zeichenfläche, Seitenzahl-Pille (Tickets T2.5, T3.x).
// Aufbau nach Plan 4c.3. Die Leisten liegen als Glas über dem Blatt; das Blatt selbst bleibt opak.
import SwiftUI
import SwiftData

struct EditorView: View {
    let notebook: Notebook
    @State private var model: EditorModel
    @Environment(\.dismiss) private var dismiss
    @State private var showGoto = false
    @State private var gotoText = ""

    init(notebook: Notebook) {
        self.notebook = notebook
        _model = State(initialValue: EditorModel(notebook: notebook))
    }

    var body: some View {
        HStack(spacing: 0) {
            if model.showSidebar {
                ThumbnailSidebar(model: model)
                    .frame(width: 230)
                    .transition(.move(edge: .leading))
                Divider()
            }
            VStack(spacing: 0) {
                EditorTopBar(model: model, title: notebook.title, onClose: close)
                EditorSubBar(model: model)
                ZStack(alignment: .bottom) {
                    DocumentRepresentable(model: model)
                    pagePill
                }
            }
        }
        .animation(Theme.Motion.standard, value: model.showSidebar)
        .onAppear { CrashReporter.step = "Editor geöffnet" }
        .background(Color(.secondarySystemBackground))
        .onChange(of: model.tool.settings) { model.tool.save() }
        .alert("Gehe zu Seite", isPresented: $showGoto) {
            TextField("Seitenzahl", text: $gotoText).keyboardType(.numberPad)
            Button("Gehe zu") { if let n = Int(gotoText) { model.go(to: n - 1) } }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("1 bis \(model.pages.count)") }
        .alert("Das hat nicht geklappt", isPresented: Binding(get: { model.errorMessage != nil },
                                                               set: { if !$0 { model.errorMessage = nil } })) {
            Button("Verstanden", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }

    private var pagePill: some View {
        Button {
            gotoText = ""
            showGoto = true
        } label: {
            Text("\(model.currentIndex + 1) / \(model.pages.count)")
                .font(.subheadline.monospacedDigit())
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.xs)
                .notaGlass(cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .padding(.bottom, Theme.Spacing.m)
        .accessibilityLabel("Seite \(model.currentIndex + 1) von \(model.pages.count). Gehe zu Seite")
    }

    private func close() {
        model.closing()
        dismiss()
    }
}
