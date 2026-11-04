// LibraryContentView.swift
// Zweck: Inhaltsbereich der Bibliothek: Raster/Liste, Toolbar, Auswahlmodus, Sheets (T1.6–T1.13).
// Aufgeteilt: Zustand + Aufbau (hier) · Elementlisten/Sortierung (+Items) · Aktionen/Menüs (+Actions).
// Die Properties sind absichtlich nicht `private`, damit die Erweiterungen in anderen Dateien sie nutzen können.
import SwiftUI
import SwiftData

enum PendingConfirm {
    case deletePermanently([LibraryItem])
    case emptyTrash
    case trashFolder(Folder)
}

struct LibraryContentView: View {
    @Binding var selection: SidebarItem
    @Binding var openNotebook: Notebook?

    @Environment(\.modelContext) var context
    @Query var allFolders: [Folder]
    @Query var allNotebooks: [Notebook]

    @AppStorage("library.viewMode") var viewModeRaw = "grid"
    @AppStorage("library.root.sortField") var rootSortField = LibrarySortField.updatedAt.rawValue
    @AppStorage("library.root.sortAscending") var rootSortAscending = false
    @AppStorage("library.root.foldersFirst") var rootFoldersFirst = true
    @AppStorage("trash.days") var trashDays = 30

    @State var searchText = ""
    @State var selecting = false
    @State var selected = Set<UUID>()
    @State var showNewNotebook = false
    @State var showNewFolder = false
    @State var showMove = false
    @State var moveItems: [LibraryItem] = []
    @State var renameTarget: LibraryItem?
    @State var renameText = ""
    @State var pending: PendingConfirm?
    @State var errorMessage: String?
    @State var toast: Toast?
    @State var dropTarget: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else if viewModeRaw == "list" {
                    listView
                } else {
                    gridView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(selecting ? "\(selected.count) ausgewählt" : title)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Titel und Ordner durchsuchen")
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .top, spacing: 0) { breadcrumbs }
            .overlay(alignment: .bottom) {
                if let toast { ToastView(toast: toast) { withAnimation { self.toast = nil } } }
            }
            .animation(Theme.Motion.standard, value: toast?.id)
            .sensoryFeedback(.impact(weight: .light), trigger: dropTarget)
        }
        .sheet(isPresented: $showNewNotebook) {
            NewNotebookSheet(folder: currentFolder) { nb in open(nb) }
        }
        .sheet(isPresented: $showNewFolder) {
            NewFolderSheet(parent: currentFolder)
        }
        .sheet(isPresented: $showMove) {
            MoveSheet(items: moveItems) { target in
                perform { for i in moveItems { try service.move(i, to: target) } }
                endSelection()
            }
        }
        .alert("Umbenennen", isPresented: Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })) {
            TextField("Name", text: $renameText)
            Button("Sichern") {
                if let t = renameTarget { perform { try service.rename(t, to: renameText) } }
                renameTarget = nil
            }
            Button("Abbrechen", role: .cancel) { renameTarget = nil }
        }
        .alert(confirmTitle, isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
            Button(confirmButton, role: .destructive) { confirmPending() }
            Button("Abbrechen", role: .cancel) { pending = nil }
        } message: { Text(confirmMessage) }
        .alert("Das hat nicht geklappt", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Verstanden", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if selecting {
            ToolbarItem(placement: .topBarLeading) {
                Button(selected.count == items.count ? "Keine auswählen" : "Alle auswählen") {
                    selected = selected.count == items.count ? [] : Set(items.map(\.id))
                }
            }
            ToolbarItem(placement: .topBarTrailing) { Button("Fertig") { endSelection() } }
            ToolbarItemGroup(placement: .bottomBar) { selectionActions }
        } else {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModeRaw = viewModeRaw == "grid" ? "list" : "grid"
                } label: {
                    Image(systemName: viewModeRaw == "grid" ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(viewModeRaw == "grid" ? "Als Liste anzeigen" : "Als Raster anzeigen")
                sortMenu
                Button("Auswählen") { selecting = true }
                    .disabled(items.isEmpty)
                if selection != .trash { plusMenu }
            }
        }
    }

    var sortMenu: some View {
        Menu {
            Picker("Sortieren nach", selection: sortFieldBinding) {
                ForEach(LibrarySortField.allCases) { Text($0.title).tag($0) }
            }
            Picker("Reihenfolge", selection: sortAscendingBinding) {
                Text("Aufsteigend").tag(true)
                Text("Absteigend").tag(false)
            }
            Toggle("Ordner oben anzeigen", isOn: foldersFirstBinding)
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sortieren")
    }

    var plusMenu: some View {
        Menu {
            Button("Notizbuch", systemImage: "book.closed") { showNewNotebook = true }
            Button("Quicknote", systemImage: "bolt") { createQuicknote() }
            Button("Ordner", systemImage: "folder.badge.plus") { showNewFolder = true }
        } label: {
            Image(systemName: "plus")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Neu")
    }

    @ViewBuilder
    var selectionActions: some View {
        let chosen = items.filter { selected.contains($0.id) }
        if selection == .trash {
            Button("Wiederherstellen") { restore(chosen); endSelection() }.disabled(chosen.isEmpty)
            Spacer()
            Button("Endgültig löschen", role: .destructive) { pending = .deletePermanently(chosen) }.disabled(chosen.isEmpty)
        } else {
            Button("Verschieben") { moveItems = chosen; showMove = true }.disabled(chosen.isEmpty)
            Spacer()
            Button("Duplizieren") { duplicate(chosen); endSelection() }
                .disabled(chosen.isEmpty || chosen.contains { $0.isFolder })
            Spacer()
            Button("Favorit") { perform { for i in chosen { try service.toggleFavorite(i) } }; endSelection() }
                .disabled(chosen.isEmpty)
            Spacer()
            Button("Löschen", role: .destructive) { trash(chosen); endSelection() }.disabled(chosen.isEmpty)
        }
    }

    // MARK: Pfad & Papierkorb-Hinweis

    @ViewBuilder
    var breadcrumbs: some View {
        if selection == .trash {
            HStack {
                Text("Elemente werden nach \(trashDays) Tagen endgültig gelöscht.")
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Button("Papierkorb leeren", role: .destructive) { pending = .emptyTrash }
                    .font(.footnote.weight(.semibold))
                    .disabled(items.isEmpty)
            }
            .padding(.horizontal, Theme.Spacing.l).padding(.vertical, Theme.Spacing.xs)
            .background(.bar)
        } else if let folder = currentFolder, searchText.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    Button("Dokumente") { selection = .documents }
                    ForEach(path(to: folder)) { f in
                        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                        Button(f.name) { selection = .folder(f.id) }
                    }
                }
                .font(.subheadline)
                .padding(.horizontal, Theme.Spacing.l).padding(.vertical, Theme.Spacing.xs)
            }
            .background(.bar)
        }
    }

    // MARK: Raster, Liste, leer

    var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 28, alignment: .top)], spacing: 32) {
                ForEach(items) { item in cell(item) }
            }
            .padding(24)
        }
    }

    var listView: some View {
        List {
            ForEach(items) { item in
                LibraryRow(item: item, isSelecting: selecting, isSelected: selected.contains(item.id))
                    .onTapGesture { tap(item) }
                    .contextMenu { itemMenu(item) }
                    .swipeActions(edge: .trailing) {
                        if item.isTrashed {
                            Button("Löschen", role: .destructive) { pending = .deletePermanently([item]) }
                        } else {
                            Button("Papierkorb", role: .destructive) { trash([item]) }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if !item.isTrashed {
                            Button(item.isFavorite ? "Entfernen" : "Favorit", systemImage: "star") {
                                perform { try service.toggleFavorite(item) }
                            }.tint(.yellow)
                        }
                    }
            }
        }
    }

    @ViewBuilder
    func cell(_ item: LibraryItem) -> some View {
        let base = Group {
            switch item {
            case .folder(let f):
                FolderCard(folder: f, isSelecting: selecting, isSelected: selected.contains(f.id),
                           isDropTarget: dropTarget == f.id, trashDays: selection == .trash ? trashDays : nil)
            case .notebook(let n):
                NotebookCard(notebook: n, isSelecting: selecting, isSelected: selected.contains(n.id),
                             trashDays: selection == .trash ? trashDays : nil)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { tap(item) }
        .contextMenu { itemMenu(item) }
        .draggable(item.id.uuidString)

        if case .folder(let f) = item, selection != .trash {
            base.dropDestination(for: String.self) { ids, _ in
                moveDropped(ids, to: f)
            } isTargeted: { dropTarget = $0 ? f.id : nil }
        } else {
            base
        }
    }

    @ViewBuilder
    var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView("Keine Treffer für „\(searchText)“", systemImage: "magnifyingglass",
                                   description: Text("Prüfe die Schreibweise oder suche nach einem anderen Wort."))
        } else {
            switch selection {
            case .documents:
                ContentUnavailableView {
                    Label("Noch keine Notizen", systemImage: "book.closed")
                } description: {
                    Text("Erstelle dein erstes Notizbuch oder importiere ein PDF.")
                } actions: {
                    Button("Notizbuch erstellen") { showNewNotebook = true }.buttonStyle(.borderedProminent)
                }
            case .folder:
                ContentUnavailableView {
                    Label("Dieser Ordner ist leer", systemImage: "folder")
                } description: {
                    Text("Zieh Dokumente hierher oder erstelle ein neues.")
                } actions: {
                    Button("Neu") { showNewNotebook = true }.buttonStyle(.borderedProminent)
                }
            case .favorites:
                ContentUnavailableView("Keine Favoriten", systemImage: "star",
                                       description: Text("Tippe bei einem Dokument auf ⭐, um es hier zu sehen."))
            case .recents:
                ContentUnavailableView("Noch nichts geöffnet", systemImage: "clock",
                                       description: Text("Deine zuletzt geöffneten Dokumente erscheinen hier."))
            case .quicknotes:
                ContentUnavailableView {
                    Label("Keine Quicknotes", systemImage: "bolt")
                } description: {
                    Text("Eine Quicknote ist eine schnelle Notiz ohne Ordner.")
                } actions: {
                    Button("Quicknote erstellen") { createQuicknote() }.buttonStyle(.borderedProminent)
                }
            case .trash:
                ContentUnavailableView("Papierkorb ist leer", systemImage: "trash",
                                       description: Text("Gelöschte Dokumente bleiben hier \(trashDays) Tage."))
            }
        }
    }
}
