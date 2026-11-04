// ThumbnailRenderer.swift
// Zweck: Rendert Seiten-Miniaturen im Hintergrund: Papier -> Marker -> Tinte (Ticket T3.1, Plan 5.8 "ein Renderer für alles").
import UIKit
import PencilKit

enum ThumbnailRenderer {
    static func render(info: PageInfo, notebookID: UUID, width: CGFloat) async -> UIImage? {
        await Task.detached(priority: .utility) {
            renderSync(info: info, notebookID: notebookID, width: width)
        }.value
    }

    static func renderSync(info: PageInfo, notebookID: UUID, width: CGFloat) -> UIImage? {
        guard info.width > 0, info.height > 0 else { return nil }
        let scale = width / CGFloat(info.width)
        let size = CGSize(width: width, height: CGFloat(info.height) * scale)
        let pageRect = CGRect(x: 0, y: 0, width: info.width, height: info.height)
        let store = try? FileStore()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: size, format: format).image { r in
            let ctx = r.cgContext
            ctx.scaleBy(x: scale, y: scale)
            PaperRenderer.draw(info.paper, size: pageRect.size, in: ctx)
            for file in ["marker.nstk", "ink.nstk"] {
                guard let store,
                      let data = try? store.read(notebookID: notebookID, relativePath: "pages/\(info.id.uuidString)/\(file)"),
                      let strokes = try? NotaStrokeCodec.decode(data), !strokes.isEmpty else { continue }
                let drawing = PencilKitBridge.drawing(from: strokes)
                var image = UIImage()
                UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                    image = drawing.image(from: pageRect, scale: 2 * scale)
                }
                image.draw(in: pageRect)
            }
        }
    }
}
