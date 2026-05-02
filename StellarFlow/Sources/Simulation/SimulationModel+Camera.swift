import SwiftUI

extension SimulationModel {

    /// Converts world coordinates (meters, +y up) to screen points (+y down), applying pan and zoom.
    func worldToScreen(x: Double, y: Double, size: CGSize) -> CGPoint {
        let cx = size.width  / 2 + panX
        let cy = size.height / 2 + panY
        return CGPoint(x: cx + (x / SCALE) * zoom,
                       y: cy - (y / SCALE) * zoom)
    }

    /// Inverse of `worldToScreen`.
    func screenToWorld(point: CGPoint, size: CGSize) -> CGPoint {
        let cx = size.width  / 2 + panX
        let cy = size.height / 2 + panY
        return CGPoint(x:  ((point.x - cx) / zoom) * SCALE,
                       y: -((point.y - cy) / zoom) * SCALE)
    }
}
