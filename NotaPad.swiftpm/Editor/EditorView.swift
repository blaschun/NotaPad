// EditorView.swift
// Zweck: Platzhalter für den Editor (T1.14). Zeigt Titel und erste Seite als Papier; das echte Zeichnen kommt in P2.
import SwiftUI

struct EditorView: View {
    let notebook: Notebook
    @Environment(\.dismiss) private var dismiss

    private var firstPage: Page? { (notebook.pages ?? []).min { $0.order < $1.order } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Label("Bibliothek", systemImage: "chevron.left").frame(minHeight: Theme.Hit.minimum)
                }
                Spacer()
                Text(notebook.title).font(.headline)
                Spacer()
                Color.clear.frame(width: 100, height: 1)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .notaGlass(cornerRadius: 0)

            ZStack {
                Color(.secondarySystemBackground)
                if let page = firstPage {
                    Rectangle()
                        .fill(Color(hex: page.paper.colorHex))
                        .aspectRatio(page.widthPt / max(page.heightPt, 1), contentMode: .fit)
                        .overlay(RoundedRectangle.nota(2).stroke(Color(.separator), lineWidth: 0.5))
                        .padding(Theme.Spacing.xl)
                        .overlay {
                            Text("Hier entsteht der Editor (Phase P2)")
                                .foregroundStyle(.secondary)
                        }
                }
            }
        }
    }
}
