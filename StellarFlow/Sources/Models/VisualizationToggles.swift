import Foundation

/// Flags controlling which overlays render on the canvas.
struct VisualizationToggles {
    var centerOfMass: Bool  = false
    var showSpeed: Bool     = true  // no effect when showVelocity is false
    var showVelocity: Bool  = true
    var showGravity: Bool   = false
    var showPath: Bool      = true
    var showGrid: Bool      = true
    var showVectorField: Bool = false
}
