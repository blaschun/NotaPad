// PaperView.swift
// Zweck: Papier-Ebene einer Seite. Nutzt CATiledLayer, damit die Vorlage beim Hineinzoomen in Kacheln scharf
// neu gezeichnet wird (Plan 5.8: "gekacheltes Rendern") – ohne riesigen Speicherbedarf.
import UIKit

final class FadelessTiledLayer: CATiledLayer {
    override class func fadeDuration() -> CFTimeInterval { 0 }
}

final class PaperView: UIView {
    override class var layerClass: AnyClass { FadelessTiledLayer.self }

    private let paper: PaperTemplate
    private let pageSize: CGSize

    init(paper: PaperTemplate, size: CGSize) {
        self.paper = paper
        self.pageSize = size
        super.init(frame: CGRect(origin: .zero, size: size))
        isOpaque = true
        backgroundColor = UIColor(hex: paper.colorHex)
        if let tiled = layer as? CATiledLayer {
            tiled.tileSize = CGSize(width: 512, height: 512)
            tiled.levelsOfDetail = 1
            tiled.levelsOfDetailBias = 4   // bis zu 16-fach schärfer als 100 %
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) wird nicht benutzt") }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clip(to: rect)
        PaperRenderer.draw(paper, size: pageSize, in: ctx)
    }
}
