// NotebookCard.swift
// Zweck: Kacheln (Raster) und Zeilen (Liste) für Notizbücher und Ordner (T1.6, Plan 4c.1).
import SwiftUI

/// Gemeinsamer Auswahlkreis unten rechts auf einer Kachel.
private struct SelectionBadge: View {
    let isSelected: Bool
    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .symbolRenderingMode(.palette)
            .foregroundStyle(isSelected ? Color.white : Color.secondary, isSelected ? Color.accentColor : Color.clear)
            .background(Circle().fill(.thinMaterial))
            .padding(6)
    }
}

struct NotebookCard: View {
    let notebook: Notebook
    var isSelecting = false
    var isSelected = false
    var trashDays: Int? = nil     // gesetzt = Papierkorb: "Noch X Tage"

    private var aspect: CGFloat {
        guard let p = (notebook.pages ?? []).min(by: { $0.order < $1.order }), p.heightPt > 0 else { return 1 / 1.414 }
        return p.widthPt / p.heightPt
    }

    private var subtitle: String {
        if let days = trashDays, let deleted = notebook.deletedAt {
            let left = max(0, days - (Calendar.current.dateComponents([.day], from: deleted, to: Date()).day ?? 0))
            return "Noch \(left) Tage"
        }
        return DateLabel.text(notebook.updatedAt)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            CoverView(cover: notebook.cover, title: notebook.title, aspect: aspect)
                .blur(radius: notebook.isLocked ? 8 : 0)
                .overlay(alignment: .bottomTrailing) { if isSelecting { SelectionBadge(isSelected: isSelected) } }
                .overlay(RoundedRectangle.nota(Theme.Radius.cover).stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0))
                .frame(maxHeight: 230)
            HStack(spacing: 4) {
                if notebook.isFavorite { Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow) }
                if notebook.isLocked { Image(systemName: "lock.fill").font(.caption2) }
                Text(notebook.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct FolderCard: View {
    let folder: Folder
    var isSelecting = false
    var isSelected = false
    var isDropTarget = false
    var trashDays: Int? = nil

    private var count: Int { (folder.children ?? []).count + (folder.notebooks ?? []).count }

    private var subtitle: String {
        if let days = trashDays, let deleted = folder.deletedAt {
            let left = max(0, days - (Calendar.current.dateComponents([.day], from: deleted, to: Date()).day ?? 0))
            return "Noch \(left) Tage"
        }
        return count == 1 ? "1 Element" : "\(count) Elemente"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                Image(systemName: "folder.fill")
                    .resizable().scaledToFit()
                    .foregroundStyle(Color(hex: folder.colorHex))
                if folder.symbolName != "folder.fill" {
                    Image(systemName: folder.symbolName)
                        .font(.title3).foregroundStyle(.white).offset(y: 6)
                }
            }
            .padding(Theme.Spacing.m)
            .frame(height: 150)
            .overlay(alignment: .bottomTrailing) { if isSelecting { SelectionBadge(isSelected: isSelected) } }
            .overlay(RoundedRectangle.nota(Theme.Radius.card).stroke(Color.accentColor, lineWidth: (isSelected || isDropTarget) ? 2 : 0))
            .scaleEffect(isDropTarget ? 1.05 : 1)
            .animation(Theme.Motion.standard, value: isDropTarget)
            HStack(spacing: 4) {
                if folder.isFavorite { Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow) }
                Text(folder.name).font(.subheadline.weight(.semibold)).lineLimit(2).truncationMode(.middle)
            }
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Zeile für die Listenansicht.
struct LibraryRow: View {
    let item: LibraryItem
    var isSelecting = false
    var isSelected = false

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            switch item {
            case .folder(let f):
                Image(systemName: "folder.fill").font(.title).foregroundStyle(Color(hex: f.colorHex)).frame(width: 34, height: 44)
            case .notebook(let n):
                CoverView(cover: n.cover, title: n.title).frame(height: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if item.isFavorite { Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow) }
                    Text(item.name).font(.body)
                }
                Text(DateLabel.text(item.updatedAt)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if item.isFolder { Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary) }
        }
        .frame(minHeight: Theme.Hit.minimum)
        .contentShape(Rectangle())
    }
}
