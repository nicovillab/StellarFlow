import Foundation

/// Simulation speed presets. `slow`=0.3×, `normal`=1.0×, `fast`=3.0×.
/// `custom` reads `SimulationModel.customSpeedMultiplier` instead.
enum SimulationSpeed: String {
    case slow
    case normal
    case fast
    case custom
}
