import SwiftUI

/// Renders all simulation layers (background, grid, vector field, trails, bodies, overlays)
/// in a single `Canvas` pass. Owns the pan gesture. Canvas avoids per-shape view diffing overhead.
struct SimulationCanvasView: View {
    @ObservedObject var model: SimulationModel

    /// Camera pan at the moment the current drag began. Captured once per drag so
    /// the drag translation is applied as a delta rather than accumulating.
    @State private var dragStartPanX: CGFloat = 0
    @State private var dragStartPanY: CGFloat = 0
    @State private var isDragging: Bool = false

    var body: some View {
        Canvas { context, size in
            drawBackground(context: context, size: size)

            if model.toggles.showGrid {
                drawGrid(context: context, size: size)
            }

            if model.toggles.showVectorField && !model.bodies.isEmpty {
                drawVectorField(context: context, size: size)
            }

            guard !model.bodies.isEmpty else { return }

            if model.toggles.showPath {
                drawTrails(context: context, size: size)
            }

            drawBodies(context: context, size: size)

            if model.toggles.centerOfMass && model.bodies.count > 1 {
                drawCenterOfMass(context: context, size: size)
            }

            if model.toggles.showVelocity {
                drawVelocityVectors(context: context, size: size)
            }
        }
        .contentShape(Rectangle()) // Ensure the entire canvas receives gestures.
        .gesture(panGesture)
    }

    /// Drawing Layers

    /// Paint the background gradient: a dark base with a subtle radial highlight at center.
    private func drawBackground(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .color(Color(red: 11/255, green: 14/255, blue: 20/255)))

        let gradient = Gradient(colors: [
            Color(red: 20/255, green: 25/255, blue: 35/255, opacity: 0.3),
            Color(red: 11/255, green: 14/255, blue: 20/255, opacity: 0)
        ])
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                gradient,
                center: .init(x: rect.midX, y: rect.midY),
                startRadius: 0,
                endRadius: max(rect.width, rect.height) / 2
            )
        )
    }

    /// Render an AU-scaled grid with three levels of detail (fine, medium, coarse)
    /// that fade in and out based on zoom.
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let AU = model.AU
        let pixelsPerAU = (AU / model.SCALE) * model.zoom

        // Pick which grid layers to show based on how dense each layer would appear
        // at the current zoom. At very low zooms the coarse grid even falls back to
        // 5-AU spacing.
        var showFineGrid = false
        var showMediumGrid = false
        var showCoarseGrid = true
        let fineGridSpacingAU = 0.1
        let mediumGridSpacingAU = 0.5
        var coarseGridSpacingAU = 1.0

        if pixelsPerAU > 200 {
            showFineGrid = true
            showMediumGrid = true
            showCoarseGrid = true
        } else if pixelsPerAU > 80 {
            showMediumGrid = true
            showCoarseGrid = true
        } else if pixelsPerAU > 30 {
            showCoarseGrid = true
        } else {
            showCoarseGrid = true
            coarseGridSpacingAU = 5.0
        }

        let toScreen: (Double, Double) -> CGPoint = { wx, wy in
            self.model.worldToScreen(x: wx, y: wy, size: size)
        }
        let toWorld: (CGPoint) -> CGPoint = { sp in
            self.model.screenToWorld(point: sp, size: size)
        }

        let worldTopLeft = toWorld(.init(x: 0, y: 0))
        let worldBottomRight = toWorld(.init(x: size.width, y: size.height))

        /// Draw a single grid layer at the given AU spacing, color, and line width.
        let drawGridLayer: (Double, Color, CGFloat) -> Void = { spacingAU, color, lineWidth in
            let spacingMeters = spacingAU * AU
            let minXAU = floor(worldTopLeft.x / spacingMeters) * spacingMeters
            let maxXAU = ceil(worldBottomRight.x / spacingMeters) * spacingMeters
            let minYAU = floor(worldBottomRight.y / spacingMeters) * spacingMeters
            let maxYAU = ceil(worldTopLeft.y / spacingMeters) * spacingMeters

            var path = Path()

            var x = minXAU
            while x <= maxXAU {
                let pTop = toScreen(x, worldTopLeft.y)
                let pBottom = toScreen(x, worldBottomRight.y)
                path.move(to: pTop)
                path.addLine(to: pBottom)
                x += spacingMeters
            }

            var y = minYAU
            while y <= maxYAU {
                let pLeft = toScreen(worldTopLeft.x, y)
                let pRight = toScreen(worldBottomRight.x, y)
                path.move(to: pLeft)
                path.addLine(to: pRight)
                y += spacingMeters
            }

            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }

        if showFineGrid {
            drawGridLayer(fineGridSpacingAU, Color.white.opacity(0.03), 0.5)
        }
        if showMediumGrid {
            drawGridLayer(mediumGridSpacingAU, Color.white.opacity(0.06), 1.0)
        }
        if showCoarseGrid {
            drawGridLayer(coarseGridSpacingAU, Color.white.opacity(0.12), 1.5)
        }
    }

    /// Render the gravitational acceleration field as a grid of small arrows.
    /// Sampling density scales with both the user's `vectorFieldDensity` setting and
    /// the current zoom, so on-screen density stays roughly constant.
    private func drawVectorField(context: GraphicsContext, size: CGSize) {
        let G = model.G
        let AU = model.AU
        let SCALE = model.SCALE

        // Visible world bounds, derived from the screen corners.
        let topLeft = model.screenToWorld(point: CGPoint(x: 0, y: 0), size: size)
        let bottomRight = model.screenToWorld(point: CGPoint(x: size.width, y: size.height), size: size)

        let worldMinX = min(topLeft.x, bottomRight.x)
        let worldMaxX = max(topLeft.x, bottomRight.x)
        let worldMinY = min(topLeft.y, bottomRight.y)
        let worldMaxY = max(topLeft.y, bottomRight.y)

        let baseSpacing: Double
        switch model.vectorFieldDensity {
        case .low:    baseSpacing = 0.3 * AU
        case .medium: baseSpacing = 0.15 * AU
        case .high:   baseSpacing = 0.08 * AU
        }

        // Counter the zoom so on-screen arrow density stays similar regardless of zoom.
        let worldSpacing = baseSpacing / model.zoom

        let gridStartX = floor(worldMinX / worldSpacing) * worldSpacing
        let gridStartY = floor(worldMinY / worldSpacing) * worldSpacing

        // Walk the world-space grid, computing net acceleration at each sample point
        // and drawing an arrow if it's above the noise floor.
        var worldX = gridStartX
        while worldX <= worldMaxX {
            var worldY = gridStartY
            while worldY <= worldMaxY {
                var netAx = 0.0
                var netAy = 0.0

                for body in model.bodies {
                    let dx = body.x - worldX
                    let dy = body.y - worldY
                    let distSq = dx * dx + dy * dy
                    // Skip when very close to a body, otherwise the arrow blows up.
                    guard distSq > 1e20 else {
                        worldY += worldSpacing
                        continue
                    }
                    let dist = sqrt(distSq)
                    let aMag = G * body.mass / distSq
                    netAx += aMag * (dx / dist)
                    netAy += aMag * (dy / dist)
                }

                let totalA = sqrt(netAx * netAx + netAy * netAy)
                if totalA > 1e-12 {
                    let screenPos = model.worldToScreen(x: worldX, y: worldY, size: size)

                    let screenSpacing = (worldSpacing / SCALE) * model.zoom
                    // Logarithmic length keeps arrows readable across many orders of magnitude.
                    let arrowLen = min(screenSpacing * 0.4, log10(totalA + 1) * 3)
                    let angle = atan2(netAy, netAx)

                    let start = screenPos
                    let end = CGPoint(
                        x: screenPos.x + arrowLen * CGFloat(cos(angle)),
                        y: screenPos.y - arrowLen * CGFloat(sin(angle))
                    )

                    var line = Path()
                    line.move(to: start)
                    line.addLine(to: end)
                    context.stroke(line, with: .color(Color(red: 0.4, green: 0.6, blue: 0.9, opacity: 0.6)), lineWidth: 2.0)

                    let headLen: CGFloat = 6
                    let headLeft = CGPoint(
                        x: end.x - headLen * CGFloat(cos(angle - Double.pi / 6)),
                        y: end.y + headLen * CGFloat(sin(angle - Double.pi / 6))
                    )
                    let headRight = CGPoint(
                        x: end.x - headLen * CGFloat(cos(angle + Double.pi / 6)),
                        y: end.y + headLen * CGFloat(sin(angle + Double.pi / 6))
                    )

                    var head = Path()
                    head.move(to: end)
                    head.addLine(to: headLeft)
                    head.addLine(to: headRight)
                    head.closeSubpath()
                    context.fill(head, with: .color(Color(red: 0.4, green: 0.6, blue: 0.9, opacity: 0.7)))
                }

                worldY += worldSpacing
            }
            worldX += worldSpacing
        }
    }

    /// Render the orbital trail behind each body as a faded polyline.
    private func drawTrails(context: GraphicsContext, size: CGSize) {
        for body in model.bodies {
            guard body.trail.count > 1 else { continue }
            var path = Path()
            let first = model.worldToScreen(x: body.trail[0].x, y: body.trail[0].y, size: size)
            path.move(to: first)
            for point in body.trail.dropFirst() {
                let p = model.worldToScreen(x: point.x, y: point.y, size: size)
                path.addLine(to: p)
            }
            context.stroke(path, with: .color(body.color.opacity(0.3)), lineWidth: 1.5)
        }
    }

    /// Render every body as a glowing filled circle. Suns get a small black cross
    /// marker on top to make them visually distinct from large planets.
    private func drawBodies(context: GraphicsContext, size: CGSize) {
        for body in model.bodies {
            let p = model.worldToScreen(x: body.x, y: body.y, size: size)
            let baseRadius: Double
            switch body.type {
            case .sun:    baseRadius = 20
            case .comet:  baseRadius = 6
            case .planet: baseRadius = 10
            }
            let radius = body.displayRadius ?? baseRadius
            let isSelected = body.id == model.selectedBodyId

            let circlePath = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius,
                                                    width: radius * 2, height: radius * 2))

            // Outer glow.
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: body.color.opacity(0.8),
                                        radius: isSelected ? 26 : 18, x: 0, y: 0))
                layer.fill(circlePath, with: .color(body.color))
            }

            context.stroke(circlePath, with: .color(isSelected ? .white : body.color),
                           lineWidth: isSelected ? 3 : 2)

            if body.type == .sun {
                var cross = Path()
                cross.move(to: CGPoint(x: p.x - 6, y: p.y))
                cross.addLine(to: CGPoint(x: p.x + 6, y: p.y))
                cross.move(to: CGPoint(x: p.x, y: p.y - 6))
                cross.addLine(to: CGPoint(x: p.x, y: p.y + 6))
                context.stroke(cross, with: .color(Color.black.opacity(0.5)), lineWidth: 2)
            }
        }
    }

    /// Render a white circle with crosshair at the system's mass-weighted center.
    private func drawCenterOfMass(context: GraphicsContext, size: CGSize) {
        var totalMass = 0.0
        var cmX = 0.0
        var cmY = 0.0

        for b in model.bodies {
            totalMass += b.mass
            cmX += b.x * b.mass
            cmY += b.y * b.mass
        }
        guard totalMass > 0 else { return }
        cmX /= totalMass
        cmY /= totalMass

        let p = model.worldToScreen(x: cmX, y: cmY, size: size)
        var circle = Path()
        circle.addArc(center: p, radius: 8, startAngle: .zero,
                      endAngle: .degrees(360), clockwise: false)
        context.stroke(circle, with: .color(.white), lineWidth: 2)

        var cross = Path()
        cross.move(to: CGPoint(x: p.x - 12, y: p.y))
        cross.addLine(to: CGPoint(x: p.x + 12, y: p.y))
        cross.move(to: CGPoint(x: p.x, y: p.y - 12))
        cross.addLine(to: CGPoint(x: p.x, y: p.y + 12))
        context.stroke(cross, with: .color(.white), lineWidth: 2)
    }

    /// Render velocity vectors as green arrows from each body. The selected body always
    /// shows its arrow; others are hidden if they'd be too short to read. When the
    /// `showSpeed` toggle is on, each arrow is labeled with its magnitude in km/s.
    private func drawVelocityVectors(context: GraphicsContext, size: CGSize) {
        for (index, body) in model.bodies.enumerated() {
            let pos = model.worldToScreen(x: body.x, y: body.y, size: size)
            let speed = sqrt(body.vx * body.vx + body.vy * body.vy)
            // Map 30 km/s (Earth's orbital speed) to a 60-pt arrow as a baseline.
            let arrowLength = (speed / 30_000.0) * 60.0
            let isSelected = body.id == model.selectedBodyId

            let shouldShow = isSelected || arrowLength > 5
            guard shouldShow else { continue }

            let displayArrowLength = isSelected ? max(arrowLength, 30.0) : arrowLength
            let angle = speed > 0 ? atan2(body.vy, body.vx) : 0

            let endX = pos.x + CGFloat(cos(angle)) * displayArrowLength
            let endY = pos.y - CGFloat(sin(angle)) * displayArrowLength
            let endPoint = CGPoint(x: endX, y: endY)

            var arrow = Path()
            arrow.move(to: pos)
            arrow.addLine(to: endPoint)

            let arrowColor = isSelected ? Color(red: 0.43, green: 1.0, blue: 0.67) : Color(red: 0.30, green: 1.0, blue: 0.53)

            context.stroke(arrow, with: .color(arrowColor), lineWidth: isSelected ? 3 : 2)

            let headLength: CGFloat = 8
            let headLeft = CGPoint(
                x: endX - headLength * CGFloat(cos(angle - Double.pi / 6)),
                y: endY + headLength * CGFloat(sin(angle - Double.pi / 6))
            )
            let headRight = CGPoint(
                x: endX - headLength * CGFloat(cos(angle + Double.pi / 6)),
                y: endY + headLength * CGFloat(sin(angle + Double.pi / 6))
            )

            var head = Path()
            head.move(to: endPoint)
            head.addLine(to: headLeft)
            head.addLine(to: headRight)
            head.closeSubpath()

            context.fill(head, with: .color(arrowColor))

            if model.toggles.showSpeed {
                let speedKmS = speed / 1000.0
                let text = Text(String(format: "|v%d| = %.2f km/s", index, speedKmS))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                let labelPoint = CGPoint(x: endX + 10, y: endY - 6)
                context.draw(text, at: labelPoint, anchor: .leading)
            }
        }
    }

    /// Gestures

    /// Drag gesture that pans the camera. Captures the initial pan offset once per
    /// drag and clamps the result to a fixed bounding box.
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragStartPanX = model.panX
                    dragStartPanY = model.panY
                }

                let dx = value.translation.width
                let dy = value.translation.height

                // Clamp to a soft border so the user can't pan to the moon.
                let maxPan: CGFloat = 10000.0
                model.panX = max(-maxPan, min(maxPan, dragStartPanX + dx))
                model.panY = max(-maxPan, min(maxPan, dragStartPanY + dy))
            }
            .onEnded { _ in
                isDragging = false
            }
    }
}
