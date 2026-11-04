// DocumentViewController.swift
// Zweck: Mehrseitige Ansicht mit Zoom und Scrollen (Tickets T2.3, T2.8, T2.9). Zoom-Variante A aus Plan 5.8:
// eine äußere UIScrollView zoomt/scrollt, darin liegen die Seiten (PageView) untereinander.
// Papier bleibt durch CATiledLayer scharf; die Tinte kommt von PencilKit (Schärfe bei hohem Zoom = offene Prüfung T2.0).
// Autosave: 1 s nach der letzten Änderung, beim Verlassen und beim Wechsel in den Hintergrund.
import SwiftUI
import UIKit
import PencilKit

final class DocumentViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    private let scrollView = UIScrollView()
    private let content = UIView()
    private var pageViews: [PageView] = []
    private var infos: [PageInfo]
    private let notebookID: UUID
    private let store = try? FileStore()
    private var active: ActiveTool?
    private weak var lastCanvas: PKCanvasView?

    private var fitScale: CGFloat = 1
    private var lastWidth: CGFloat = 0
    private var pendingRelativeZoom: CGFloat
    private var pendingPageIndex: Int
    private var saveWork: DispatchWorkItem?
    private var handledScrollToken: UUID?
    private(set) var currentIndex = 0

    var revision = 0
    var onPageChanged: ((Int) -> Void)?
    var onUndoState: ((Bool, Bool) -> Void)?
    var onPageSaved: ((UUID) -> Void)?

    private let margin: CGFloat = 24
    private let spacing: CGFloat = 20

    init(notebookID: UUID, pages: [PageInfo], startPage: Int, relativeZoom: CGFloat) {
        self.notebookID = notebookID
        self.infos = pages
        self.pendingPageIndex = startPage
        self.pendingRelativeZoom = relativeZoom > 0 ? relativeZoom : 1
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) wird nicht benutzt") }

    var relativeZoom: CGFloat { fitScale > 0 ? scrollView.zoomScale / fitScale : 1 }

    // MARK: Aufbau

    override func viewDidLoad() {
        super.viewDidLoad()
        CrashReporter.step = "Zeichenfläche wird aufgebaut"
        view.backgroundColor = .secondarySystemBackground
        scrollView.delegate = self
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.showsVerticalScrollIndicator = true
        scrollView.decelerationRate = .normal
        scrollView.bouncesZoom = true
        // Nur Finger scrollen – der Pencil zeichnet (Plan 4c.3)
        scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        view.addSubview(scrollView)
        scrollView.addSubview(content)

        let two = UITapGestureRecognizer(target: self, action: #selector(twoFingerTap))
        two.numberOfTouchesRequired = 2
        two.delegate = self
        scrollView.addGestureRecognizer(two)
        let three = UITapGestureRecognizer(target: self, action: #selector(threeFingerTap))
        three.numberOfTouchesRequired = 3
        three.delegate = self
        scrollView.addGestureRecognizer(three)

        buildPages()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appWillBackground), name: UIApplication.willResignActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        for name in [Notification.Name.NSUndoManagerDidUndoChange, .NSUndoManagerDidRedoChange, .NSUndoManagerDidCloseUndoGroup] {
            nc.addObserver(self, selector: #selector(undoStateChanged), name: name, object: nil)
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func buildPages() {
        pageViews.forEach { $0.removeFromSuperview() }
        pageViews = []
        let maxWidth = infos.map(\.width).max() ?? 595
        let contentWidth = maxWidth + margin * 2
        var y = margin
        for info in infos {
            let pv = PageView(info: info, notebookID: notebookID, store: store)
            pv.frame.origin = CGPoint(x: (contentWidth - info.width) / 2, y: y)
            pv.onChange = { [weak self] _ in self?.pageChanged($0) }
            pv.onFocus = { [weak self] canvas in self?.lastCanvas = canvas; self?.reportUndoState() }
            content.addSubview(pv)
            pageViews.append(pv)
            y += info.height + spacing
        }
        content.frame = CGRect(x: 0, y: 0, width: contentWidth, height: y - spacing + margin)
        scrollView.contentSize = content.frame.size
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        guard w > 0 else { return }
        if abs(w - lastWidth) > 1 {
            let relative = lastWidth == 0 ? pendingRelativeZoom : relativeZoom
            lastWidth = w
            configureZoom(relative: relative)
            if pendingPageIndex >= 0 {
                scrollTo(pendingPageIndex, animated: false)
                pendingPageIndex = -1
            }
        }
        updateInsets()
        updateVisiblePages()
    }

    private func configureZoom(relative: CGFloat) {
        guard content.bounds.width > 0 else { return }
        fitScale = view.bounds.width / content.bounds.width
        scrollView.minimumZoomScale = fitScale * 0.35
        scrollView.maximumZoomScale = fitScale * 8
        scrollView.zoomScale = min(max(fitScale * relative, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
    }

    /// Seiten neu aufbauen (nach Hinzufügen/Löschen/Umsortieren/Papierwechsel). Position und Zoom bleiben.
    func reload(pages: [PageInfo]) {
        saveAll()
        let relative = relativeZoom
        let keepIndex = min(currentIndex, max(pages.count - 1, 0))
        scrollView.zoomScale = 1
        infos = pages
        buildPages()
        configureZoom(relative: relative)
        scrollTo(keepIndex, animated: false)
        updateInsets()
        updateVisiblePages()
    }

    // MARK: Zoom & Scrollen

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { content }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateInsets()
        updateVisiblePages()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) { updateVisiblePages() }

    private func updateInsets() {
        let x = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let y = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
    }

    func scrollTo(_ index: Int, animated: Bool) {
        guard pageViews.indices.contains(index) else { return }
        let z = scrollView.zoomScale
        let targetY = pageViews[index].frame.minY * z - margin * z
        let minY = -scrollView.contentInset.top
        let maxY = max(scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom, minY)
        let x = scrollView.contentOffset.x
        scrollView.setContentOffset(CGPoint(x: x, y: min(max(targetY, minY), maxY)), animated: animated)
    }

    func handleScrollRequest(index: Int, token: UUID) {
        guard handledScrollToken != token else { return }
        handledScrollToken = token
        scrollTo(index, animated: true)
    }

    /// Welche Seiten sind sichtbar? Nur diese (plus Puffer, maximal 8) bekommen echte Zeichenflächen.
    private func updateVisiblePages() {
        guard !pageViews.isEmpty else { return }
        let visible = scrollView.convert(scrollView.bounds, to: content)
        let buffer = visible.insetBy(dx: 0, dy: -visible.height * 0.6)
        let center = visible.midY
        let wanted = pageViews.filter { $0.frame.intersects(buffer) }
            .sorted { abs($0.frame.midY - center) < abs($1.frame.midY - center) }
            .prefix(8)
        let wantedSet = Set(wanted.map { ObjectIdentifier($0) })
        CrashReporter.step = "Seiten aktivieren (Zeichenflächen laden)"
        for pv in pageViews {
            if wantedSet.contains(ObjectIdentifier(pv)) { pv.activate(active) } else { pv.deactivate() }
        }
        // aktuelle Seite = größte Überlappung mit dem sichtbaren Bereich
        var best = currentIndex
        var bestOverlap: CGFloat = -1
        for (i, pv) in pageViews.enumerated() {
            let o = pv.frame.intersection(visible)
            let overlap = o.isNull ? 0 : o.height
            if overlap > bestOverlap { bestOverlap = overlap; best = i }
        }
        if best != currentIndex {
            currentIndex = best
            onPageChanged?(best)
        }
    }

    // MARK: Werkzeug, Speichern, Rückgängig

    func apply(_ tool: ActiveTool) {
        active = tool
        pageViews.forEach { $0.apply(tool) }
    }

    private func pageChanged(_ pv: PageView) {
        reportUndoState()
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveAll() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    func saveAll() {
        saveWork?.cancel()
        for pv in pageViews where pv.save() { onPageSaved?(pv.info.id) }
    }

    /// Verwirft eine Seite (vor dem Löschen ihrer Dateien).
    func discardPage(_ id: UUID) {
        pageViews.first { $0.info.id == id }?.discard()
    }

    @objc private func appWillBackground() { saveAll() }

    private var currentUndoManager: UndoManager? { lastCanvas?.undoManager ?? undoManager }

    @objc private func undoStateChanged() { reportUndoState() }

    private func reportUndoState() {
        let um = currentUndoManager
        let canUndo = um?.canUndo ?? false
        let canRedo = um?.canRedo ?? false
        DispatchQueue.main.async { [weak self] in self?.onUndoState?(canUndo, canRedo) }
    }

    func undo() { currentUndoManager?.undo(); reportUndoState() }
    func redo() { currentUndoManager?.redo(); reportUndoState() }

    @objc private func twoFingerTap() { undo() }
    @objc private func threeFingerTap() { redo() }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

// MARK: - SwiftUI-Brücke

struct DocumentRepresentable: UIViewControllerRepresentable {
    let model: EditorModel

    func makeUIViewController(context: Context) -> DocumentViewController {
        let vc = DocumentViewController(notebookID: model.notebook.id, pages: model.pages,
                                        startPage: model.currentIndex, relativeZoom: CGFloat(model.notebook.lastZoom))
        vc.onPageChanged = { [weak model] i in DispatchQueue.main.async { model?.currentIndex = i } }
        vc.onUndoState = { [weak model] u, r in model?.canUndo = u; model?.canRedo = r }
        vc.onPageSaved = { [weak model] id in DispatchQueue.main.async { model?.thumbVersions[id, default: 0] += 1 } }
        model.controller = vc
        vc.apply(model.tool.activeTool(readOnly: model.readOnly))
        return vc
    }

    func updateUIViewController(_ vc: DocumentViewController, context: Context) {
        if vc.revision != model.revision {
            vc.revision = model.revision
            vc.reload(pages: model.pages)
        }
        vc.apply(model.tool.activeTool(readOnly: model.readOnly))
        if let req = model.scrollRequest { vc.handleScrollRequest(index: req.index, token: req.token) }
    }
}
