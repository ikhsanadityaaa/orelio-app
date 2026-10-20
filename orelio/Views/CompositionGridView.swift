import SwiftUI

/// Composition guides are deliberately a non-exporting preview overlay.
/// All paths are drawn in the fitted photograph's coordinate space, not the
/// letterboxed editor container; guides cannot escape the image bounds.
struct CompositionGridView: View {
    let settings: GridSettings
    var outsideBorderFraction: Double = 0

    var body: some View {
        Canvas { context, size in
            guard settings.kind != .off, size.width > 0, size.height > 0 else { return }
            let f = min(0.08, max(0, outsideBorderFraction))
            // Exterior borders grow the exported bitmap: exclude that padding
            // from guides so they still follow original photographic content.
            let inset = min(size.width, size.height) * CGFloat(f / (1 + 2 * f))
            let bounds = CGRect(x: inset, y: inset,
                                width: size.width - 2 * inset,
                                height: size.height - 2 * inset)
            guard bounds.width > 0 && bounds.height > 0 else { return }
            context.clip(to: Path(bounds))
            var lines = Path()
            func start(_ a: CGPoint, _ b: CGPoint) {
                lines.move(to: a); lines.addLine(to: b)
            }
            let x = bounds.minX, y = bounds.minY
            let w = bounds.width, h = bounds.height
            switch settings.kind {
            case .off:
                break
            case .thirds:
                for fraction in [CGFloat(1)/3, CGFloat(2)/3] {
                    start(CGPoint(x: x + w*fraction, y: y), CGPoint(x: x + w*fraction, y: y+h))
                    start(CGPoint(x: x, y: y + h*fraction), CGPoint(x: x+w, y: y+h*fraction))
                }
            case .centerMarker:
                let arm = min(w, h) * 0.105
                start(CGPoint(x: bounds.midX-arm, y: bounds.midY), CGPoint(x: bounds.midX+arm, y: bounds.midY))
                start(CGPoint(x: bounds.midX, y: bounds.midY-arm), CGPoint(x: bounds.midX, y: bounds.midY+arm))
                lines.addEllipse(in: CGRect(x: bounds.midX-4, y: bounds.midY-4, width: 8, height: 8))
            case .goldenTriangles:
                let a = CGPoint(x: x,y: y), b = CGPoint(x: x+w,y: y+h)
                start(a,b)
                let dx = b.x-a.x, dy = b.y-a.y
                func foot(_ p: CGPoint) -> CGPoint {
                    let t = ((p.x-a.x)*dx+(p.y-a.y)*dy)/(dx*dx+dy*dy)
                    return CGPoint(x: a.x + t*dx, y: a.y + t*dy)
                }
                let corner1 = CGPoint(x: x+w, y: y), corner2 = CGPoint(x: x, y: y+h)
                start(corner1,foot(corner1)); start(corner2,foot(corner2))
            case .square:
                // Actual square spacing (not independent fractions on unequal axes).
                let step = min(w,h) / 5
                if step > 0 {
                    var xx = bounds.midX.truncatingRemainder(dividingBy: step) + x
                    // Grid is centred on the photograph, works in portrait and landscape.
                    xx = bounds.midX - floor((bounds.midX-x)/step)*step
                    while xx < bounds.maxX { start(CGPoint(x: xx,y:y),CGPoint(x:xx,y:y+h)); xx += step }
                    var yy = bounds.midY - floor((bounds.midY-y)/step)*step
                    while yy < bounds.maxY { start(CGPoint(x:x,y:yy),CGPoint(x:x+w,y:yy)); yy += step }
                }
            case .goldenSpiral:
                // A logarithmic golden spiral, radius grows by phi every 90°.
                // Rotate 0/90/180/270°; mirror adds four additional orientations.
                let phi = (1 + sqrt(5.0)) / 2
                let turns = ((settings.quarterTurns % 4) + 4) % 4
                let angle = Double(turns) * .pi / 2
                let scale = Double(min(w,h)) * 0.67
                let centerX = Double(bounds.midX), centerY = Double(bounds.midY)
                let maxTheta = 3.4 * Double.pi
                var first = true
                for index in 0...550 {
                    let theta = -3.5*Double.pi + (maxTheta + 3.5*Double.pi) * Double(index) / 550
                    let radius = scale * pow(phi, (theta-maxTheta)/(.pi/2))
                    var px = radius * cos(theta)
                    let py = radius * sin(theta)
                    if settings.mirrored { px = -px }
                    let rx = px*cos(angle)-py*sin(angle)
                    let ry = px*sin(angle)+py*cos(angle)
                    let point = CGPoint(x:centerX+rx,y:centerY+ry)
                    if first { lines.move(to:point); first=false } else { lines.addLine(to:point) }
                }
            }
            let ink = settings.darkLines ? Color.black : Color.white
            // Dark shadow increases legibility when a white grid is over a light photo.
            if !settings.darkLines {
                context.stroke(lines, with: .color(.black.opacity(0.28 * settings.opacity)),
                               style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
            context.stroke(lines, with: .color(ink.opacity(settings.opacity)),
                           style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
