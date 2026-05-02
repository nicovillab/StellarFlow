import SwiftUI

/// Celestial body classification — drives default radius and color rendering.
enum BodyType: String {
    case sun    // largest
    case planet // medium
    case comet  // smallest
}

/// A past position used to render orbital trails.
struct TrailPoint {
    var x: Double
    var y: Double
}

/// A celestial body in the n-body simulation. All units are SI (meters, kg, m/s).
struct Body: Identifiable {
    var id: Int
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var mass: Double
    var color: Color
    var type: BodyType
    var trail: [TrailPoint] // capped at 500 entries
    var displayRadius: Double? // nil = derived from type
}
