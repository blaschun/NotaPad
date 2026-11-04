// SidebarView.swift
// Zweck: Seitenleiste der Bibliothek (T1.5, Plan 4c.1): Dokumente, Zuletzt, Favoriten, Quicknotes, Ordnerbaum, Papierkorb.
import SwiftUI
import SwiftData

enum SidebarItem: Hashable {
    case documents, recents, favorites, quicknotes, trash
    case folder(UUID)
}

struct SidebarView: View {
    @Binding var selection: SidebarItem
    @Binding var showSettings: Bool
    @Query(filter: #Predicate<Folder> { $0.deletedAt == nil && $0.parent == nil }, sort: \Folder.name)
    private var rootFolders: [Folder]
    @Query(filter: #Predicate<Notebook> { $0.deletedAt != nil }) private var trashedNotebooks: [Notebook]
    @Query(filter: #Predicate<Folder> { $0.deletedAt != nil }) private var trashedFolders: [Folder]

    var body: some View {
        List {
            Section {
                row("Dokumente", "doc.on.doc", .documents)
                row("Zuletzt", "clock", .recents)
                row("Favoriten", "star", .favorites)
                row("Quicknotes", "bolt", .quicknotes)
            }
            if !rootFolders.isEmpty {
                Section("Ordner") {
                    ForEach(rootFolders) { FolderBranch(folder: $0, selection: $selection, depth: 0) }
                }
            }
            Section {
                row("Papierkorb", "trash", .trash, badge: trashedNotebooks.count + trashedFolders.count)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("NotaPad")
        .safeAreaInset(edge: .bottom) {
            Button { showSettings = true } label: {
                Label("Einstellungen", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.m)
            }
            .buttonStyle(.plain)
            .background(.bar)
        }
    }

    private func row(_ title: String, _ symbol: String, _ item: SidebarItem, badge: Int = 0) -> some View {
        Button { selection = item } label: {
            HStack {
                Label(title, systemImage: symbol)
                Spacer()
                if badge > 0 { Text("\(badge)").foregroundStyle(.secondary).monospacedDigit() }
            }
            .frame(minHeight: Theme.Hit.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selection == item ? Color.accentColor.opacity(0.18) : Color.clear)
    }
}

/// Ein Ordner im Baum, aufklappbar wenn er Unterordner hat.
private struct FolderBranch: View {
    let folder: Folder
    @Binding var selection: SidebarItem
    let depth: Int
    @State private var expanded = false

    private var children: [Folder] {
        (folder.children ?? []).filter { $0.deletedAt == nil }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Group {
            HStack(spacing: 4) {
                if children.isEmpty {
                    Color.clear.frame(width: 22)
                } else {
                    Button { withAnimation(Theme.Motion.standard) { expanded.toggle() } } label: {
                        Image(systemName: "chevron.right").rotationEffect(.degrees(expanded ? 90 : 0))
                            .font(.footnote.weight(.semibold)).frame(width: 22, height: 30)
                    }
                    .buttonStyle(.plain)
                }
                Button { selection = .folder(folder.id) } label: {
                    Label { Text(folder.name) } icon: { Image(systemName: "folder.fill").foregroundStyle(Color(hex: folder.colorHex)) }
                        .frame(maxWidth: .infinity, minHeight: Theme.Hit.minimum, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, CGFloat(depth) * 16)
            .listRowBackground(selection == .folder(folder.id) ? Color.accentColor.opacity(0.18) : Color.clear)
            if expanded {
                ForEach(children) { FolderBranch(folder: $0, selection: $selection, depth: depth + 1) }
            }
        }
    }
}
