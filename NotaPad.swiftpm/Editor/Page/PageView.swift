// PageView.swift
// Zweck: Eine Seite = Papier (PaperView) + Marker-Ebene + Tinten-Ebene, deckungsgleich übereinander (Ticket T2.2, Plan 5.2).
// Die Marker-Ebene liegt HINTER der Tinte, damit Textmarker nie über Schrift liegt.
// Canvases werden nur für sichtbare Seiten angelegt (Lazy Loading) und beim Verlassen gespeichert + abgebaut.
// Sicherheit: Lässt sich eine vorhandene Datei nicht lesen, wird sie NIE überschrieben (loadFailed).
import UIKit
import PencilKit
import OSLog

final class PageView: UIView, PKCanvasViewDelegate {
    let info: PageInfo
    private let notebookID: UUID
    private let store: FileStore?
    private let paperView: PaperView
    private(set) var inkCanvas: PKCanvasView?
    private(set) var markerCanvas: PKCanvasView?
    private var dirty = false
    private var loadFailed = false
    private var suppress = false
    private var active: ActiveTool?
    private let log = Logger(subsystem: "NotaPad", category: "Speichern")

    var onChange: ((PageView) -> Void)?
    var onFocus: ((PKCanvasView) -> Void)?

    var isActive: Bool { inkCanvas != nil }

    init(info: PageInfo, notebookID: UUID, store: FileStore?) {
        self.info = info
        self.notebookID = notebookID
        self.store = store
        let size = CGSize(width: info.width, height: info.height)
        self.paperView = PaperView(paper: info.paper, size: size)
        super.init(frame: CGRect(origin: .zero, size: size))
        backgroundColor = .clear
        addSubview(paperView)
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) wird nicht benutzt") }

    // MARK: Laden / Speichern

    private func path(_ file: String) -> String { "pages/\(info.id.uuidString)/\(file)" }

    private func loadDrawing(_ file: String) -> PKDrawing {
        guard let store, let data = try? store.read(notebookID: notebookID, relativePath: path(file)) else {
            return PKDrawing()   // Datei fehlt = leere Seite (normal)
        }
        do {
            return PencilKitBridge.drawing(from: try NotaStrokeCodec.decode(data))
        } catch {
            loadFailed = true     // beschädigt: nichts überschreiben!
            log.error("Zeichnung nicht lesbar (\(file)): \(error.localizedDescription)")
            return PKDrawing()
        }
    }

    private func makeCanvas(file: String) -> PKCanvasView {
        let c = PKCanvasView(frame: bounds)
        c.backgroundColor = .clear
        c.isOpaque = false
        c.isScrollEnabled = false
        c.bounces = false
        c.overrideUserInterfaceStyle = .light   // Tintenfarben bleiben im Dunkelmodus wie gewählt
        c.drawing = loadDrawing(file)
        c.delegate = self
        return c
    }

    func activate(_ tool: ActiveTool?) {
        guard inkCanvas == nil else { apply(tool); return }
        suppress = true
        let marker = makeCanvas(file: "marker.nstk")
        let ink = makeCanvas(file: "ink.nstk")
        addSubview(marker)
        addSubview(ink)
        markerCanvas = marker
        inkCanvas = ink
        suppress = false
        apply(tool)
    }

    func deactivate() {
        guard inkCanvas != nil else { return }
        save()
        removeCanvases()
    }

    /// Verwirft ungespeicherte Änderungen (z. B. vor "Seite leeren").
    func discard() {
        dirty = false
        removeCanvases()
    }

    private func removeCanvases() {
        inkCanvas?.removeFromSuperview()
        markerCanvas?.removeFromSuperview()
        inkCanvas = nil
        markerCanvas = nil
    }

    /// Gibt true zurück, wenn tatsächlich geschrieben wurde.
    @discardableResult
    func save() -> Bool {
        guard dirty, !loadFailed, let store, let ink = inkCanvas, let marker = markerCanvas else { return false }
        do {
            try store.write(NotaStrokeCodec.encode(PencilKitBridge.strokes(from: ink.drawing)),
                            notebookID: notebookID, relativePath: path("ink.nstk"))
            try store.write(NotaStrokeCodec.encode(PencilKitBridge.strokes(from: marker.drawing)),
                            notebookID: notebookID, relativePath: path("marker.nstk"))
            dirty = false
            return true
        } catch {
            log.error("Speichern fehlgeschlagen: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: Werkzeug

    func apply(_ tool: ActiveTool?) {
        active = tool
        guard let tool, let ink = inkCanvas, let marker = markerCanvas else { return }
        let target = tool.targetsMarker ? marker : ink
        let other = tool.targetsMarker ? ink : marker
        target.tool = tool.tool
        target.isUserInteractionEnabled = !tool.readOnly
        target.allowsFingerDrawing = tool.finger
        target.isRulerActive = tool.ruler
        other.isUserInteractionEnabled = false
        other.isRulerActive = false
    }

    // MARK: PKCanvasViewDelegate

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard !suppress else { return }
        dirty = true
        onChange?(self)
    }

    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        onFocus?(canvasView)
    }
}
