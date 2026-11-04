// ThumbnailSidebar.swift
// Zweck: Seitenleiste mit Miniaturen (Tickets T3.1, T3.3, T3.4): antippen = Gehe zu, "Bearbeiten" = Umsortieren per Ziehen,
// Kontextmenü mit Seitenoperationen, Lesezeichen-Filter. Miniaturen werden nur für sichtbare Zeilen im Hintergrund gerendert.
import SwiftUI

struct ThumbnailSidebar: View {
    @Bindable var model: EditorModel
    @State private var editMode: EditMode = .inactive
    @State private var onlyBookmarks = false

    private var rows: [(Int, PageInfo)] {
        let all = Array(model.pages.enumerated()).map { ($0.offset, $0.element) }
        return onlyBookmarks ? all.filter { $0.1.isBookmarked } : all
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Anzeige", selection: $onlyBookmarks) {
                    Text("Seiten").tag(false)
                    Text("Lesezeichen").tag(true)
                }
                .pickerStyle(.segmented)
                Button(editMode.isEditing ? "Fertig" : "Ändern") {
                    withAnimation { editMode = editMode.isEditing ? .inactive : .active }
                }
                .disabled(onlyBookmarks)
            }
            .padding(Theme.Spacing.s)

            List {
                ForEach(rows, id: \.1.id) { index, info in
                    ThumbnailRow(model: model, index: index, info: info, isCurrent: index == model.currentIndex)
                        .contentShape(Rectangle())
                        .onTapGesture { model.go(to: index) }
                        .contextMenu {
                            Button("Seite hinzufügen", systemImage: "plus.square") { model.go(to: index); model.addPage() }
                            Button("Duplizieren", systemImage: "plus.square.on.square") { model.duplicatePage(at: index) }
                            Button(info.isBookmarked ? "Lesezeichen entfernen" : "Lesezeichen setzen", systemImage: "bookmark") {
                                model.toggleBookmark(at: index)
                            }
                            Button("Leeren", systemImage: "eraser.line.dashed") { model.clearPage(at: index) }
                            Button("Löschen", systemImage: "trash", role: .destructive) { model.deletePage(at: index) }
                        }
                        .listRowSeparator(.hidden)
                }
                .onMove { model.movePages(from: $0, to: $1) }
            }
            .listStyle(.plain)
            .environment(\.editMode, $editMode)
        }
        .background(Color(.systemBackground))
    }
}

private struct ThumbnailRow: View {
    let model: EditorModel
    let index: Int
    let info: PageInfo
    let isCurrent: Bool
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        Rectangle().fill(Color(.systemGray5))
                            .aspectRatio(info.width / max(info.height, 1), contentMode: .fit)
                    }
                }
                .overlay(Rectangle().stroke(isCurrent ? Color.accentColor : Color(.separator), lineWidth: isCurrent ? 3 : 0.5))
                if info.isBookmarked {
                    Image(systemName: "bookmark.fill").foregroundStyle(.red).padding(4)
                }
            }
            Text("\(index + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
        }
        .frame(maxWidth: .infinity)
        .task(id: Key(version: model.thumbVersions[info.id, default: 0], paper: info.paper)) {
            image = await ThumbnailRenderer.render(info: info, notebookID: model.notebook.id, width: 170)
        }
    }

    private struct Key: Hashable {
        let version: Int
        let paper: PaperTemplate
    }
}
