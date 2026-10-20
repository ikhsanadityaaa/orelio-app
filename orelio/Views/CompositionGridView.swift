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
                // Fibonacci construction from adjacent 5,3,2,1,1 squares
                // (8:5 bounding rectangle), rather than a logarithmic spiral.
                let portrait = h > w
                let rotations = ((settings.quarterTurns + (portrait ? 1 : 0)) % 4 + 4) % 4
                let vertical = rotations % 2 != 0
                let unit = min(w / (vertical ? 5 : 8), h / (vertical ? 8 : 5))
                let angle = CGFloat(rotations) * (.pi / 2)
                let ca = cos(angle), sa = sin(angle)
                func converted(_ ux: CGFloat, _ uy: CGFloat) -> CGPoint {
                    var dx = (ux - 4) * unit
                    let dy = (uy - 2.5) * unit
                    if settings.mirrored { dx = -dx }
                    return CGPoint(x: bounds.midX + dx * ca - dy * sa,
                                   y: bounds.midY + dx * sa + dy * ca)
                }
                // Rectangles and quarter-circle arcs share precisely the same
                // transformed coordinates; preserve real circles at any photo ratio.
                for (sx, sy, side) in [(0.0,0.0,5.0),(5,0,3),(6,3,2),
                                       (5,3,1),(5,4,1)] {
                    let x = CGFloat(sx), y = CGFloat(sy), d = CGFloat(side)
                    let corners = [converted(x,y),converted(x+d,y),
                                   converted(x+d,y+d),converted(x,y+d)]
                    lines.move(to: corners[0])
                    for pt in corners.dropFirst() { lines.addLine(to: pt) }
                    lines.closeSubpath()
                }
                for (cx, cy, radius, firstAngle) in [(5.0,5.0,5.0,Double.pi),
                                                      (5,3,3,1.5*Double.pi),
                                                      (6,3,2,0.0),
                                                      (6,4,1,Double.pi/2)] {
                    let steps = 24
                    for i in 0...steps {
                        let theta = firstAngle + Double(i) * (.pi/2) / Double(steps)
                        let pt = converted(CGFloat(cx + radius*cos(theta)),
                                           CGFloat(cy + radius*sin(theta)))
                        if i == 0 { lines.move(to: pt) } else { lines.addLine(to: pt) }
                    }
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
