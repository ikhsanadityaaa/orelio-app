import Foundation
import UIKit

/// Local collage renderer. Each layout is our own implementation.
final class CollageRenderer {
    static let shared = CollageRenderer()
    private init() {}

    private func makeCanvas(size: CGSize, draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            draw(ctx.cgContext)
        }
    }

    private func place(_ photo: PhotoRecord, in rect: CGRect, context: CGContext) {
        guard let image = ImagePipeline.shared.renderPreview(photo, maxDimension: 2100) else { return }
        let scaled = max(rect.width / image.size.width, rect.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scaled, height: image.size.height * scaled)
        let drawRect = CGRect(x: rect.midX - drawSize.width / 2,
                              y: rect.midY - drawSize.height / 2,
                              width: drawSize.width, height: drawSize.height)
        context.saveGState()
        context.clip(to: rect)
        image.draw(in: drawRect)
        context.restoreGState()
    }

    private func save(_ image: UIImage, at output: URL) throws {
        guard let data = image.jpegData(compressionQuality: 0.93) else { throw RenderError.cannotWrite }
        try data.write(to: output, options: .atomic)
    }

    /// Multipage canvas export: one JPEG for each page, respecting slots and page order.
    func renderPages(pages: [CollagePage], photos: [PhotoRecord]) throws -> [URL] {
        guard !pages.isEmpty else { return [] }
        let directory = try AppFolders.newExportDirectory(prefix: "pages")
        let byID = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0) })
        var results: [URL] = []
        for (index, page) in pages.enumerated() {
            let width: CGFloat = 1080
            let height: CGFloat = 1350
            let image = makeCanvas(size: CGSize(width: width, height: height)) { context in
                for (slot, normalized) in page.layout.rects.enumerated() {
                    guard page.photoIDs.indices.contains(slot),
                          let id = page.photoIDs[slot], let photo = byID[id] else { continue }
                    let safe = normalized.insetBy(dx: CGFloat(page.margin), dy: CGFloat(page.margin))
                    let rect = CGRect(x: safe.minX * width, y: safe.minY * height,
                                      width: safe.width * width, height: safe.height * height)
                    place(photo, in: rect, context: context)
                }
            }
            let url = directory.appendingPathComponent(String(format: "page-%02d.jpg", index + 1))
            try save(image, at: url)
            results.append(url)
        }
        return results
    }

    func render(photos: [PhotoRecord], style: CollageStyle) throws -> [URL] {
        guard !photos.isEmpty else { return [] }
        let directory = try AppFolders.newExportDirectory(prefix: "collage")
        switch style {
        case .grid:
            let items = Array(photos.prefix(12))
            let columns = items.count == 1 ? 1 : 2
            let rows = Int(ceil(Double(items.count) / Double(columns)))
            let margin: CGFloat = 34
            let gap: CGFloat = 18
            let width: CGFloat = 1080
            let tile = (width - margin * 2 - gap * CGFloat(columns - 1)) / CGFloat(columns)
            let height = max(1080, margin * 2 + CGFloat(rows) * tile + CGFloat(rows - 1) * gap)
            let image = makeCanvas(size: CGSize(width: width, height: height)) { ctx in
                for (index, record) in items.enumerated() {
                    let col = index % columns
                    let row = index / columns
                    let rect = CGRect(x: margin + CGFloat(col) * (tile + gap),
                                      y: margin + CGFloat(row) * (tile + gap),
                                      width: tile, height: tile)
                    place(record, in: rect, context: ctx)
                }
            }
            let result = directory.appendingPathComponent("collage-grid.jpg")
            try save(image, at: result)
            return [result]

        case .story:
            let items = Array(photos.prefix(4))
            let image = makeCanvas(size: CGSize(width: 1080, height: 1920)) { ctx in
                if let first = items.first {
                    place(first, in: CGRect(x: 72, y: 140, width: 936, height: 1110), context: ctx)
                }
                let small = Array(items.dropFirst())
                let cellWidth: CGFloat = 284
                for (index, record) in small.enumerated() {
                    place(record, in: CGRect(x: 72 + CGFloat(index) * (cellWidth + 42), y: 1320, width: cellWidth, height: 420), context: ctx)
                }
                // Deliberately original editorial composition, not proprietary SCRL assets.
                let header = "FILM / NOTES"
                (header as NSString).draw(at: CGPoint(x: 72, y: 58), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 38, weight: .light),
                    .foregroundColor: UIColor.darkGray,
                    .kern: 8
                ])
                ("A MOMENT IN FRAMES" as NSString).draw(at: CGPoint(x: 72, y: 1810), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 27, weight: .medium),
                    .foregroundColor: UIColor.darkGray,
                    .kern: 3
                ])
            }
            let result = directory.appendingPathComponent("collage-story.jpg")
            try save(image, at: result)
            return [result]

        case .seamless:
            let items = Array(photos.prefix(6))
            let slides = max(2, items.count)
            let slideWidth: CGFloat = 1080
            let totalWidth = CGFloat(slides) * slideWidth
            let canvas = makeCanvas(size: CGSize(width: totalWidth, height: 1350)) { ctx in
                let count = items.count
                for index in 0..<count {
                    // Images intentionally overlap boundaries between export panels.
                    let x = CGFloat(index) * slideWidth - CGFloat(index % 2 == 0 ? 40 : 230)
                    let y: CGFloat = index % 2 == 0 ? 80 : 330
                    let width: CGFloat = 1290
                    let height: CGFloat = index % 2 == 0 ? 900 : 930
                    place(items[index], in: CGRect(x: x, y: y, width: width, height: height), context: ctx)
                }
            }
            guard let cg = canvas.cgImage else { throw RenderError.cannotRender }
            var output: [URL] = []
            for i in 0..<slides {
                let segment = CGRect(x: CGFloat(i) * slideWidth, y: 0, width: slideWidth, height: 1350)
                guard let crop = cg.cropping(to: segment) else { throw RenderError.cannotRender }
                let url = directory.appendingPathComponent(String(format: "carousel-%02d.jpg", i + 1))
                try save(UIImage(cgImage: crop), at: url)
                output.append(url)
            }
            return output
        }
    }
}
