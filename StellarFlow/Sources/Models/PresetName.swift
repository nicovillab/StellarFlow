import Foundation

/// Built-in orbital configurations. Each case maps to a body-construction routine in `SimulationModel.createPresetBodies`.
enum PresetName: String, CaseIterable, Identifiable {
    case sunPlanet       = "sun-planet"
    case sunPlanetComet  = "sun-planet-comet"
    case trojan          = "trojan"
    case solarSystem     = "solar-system"
    case ellipses        = "ellipses"
    case binaryStar      = "binary-star"
    case fourStar        = "four-star"
    case custom          = "custom" // user-edited state, not directly loadable

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunPlanet:      return "Sun, Planet"
        case .sunPlanetComet: return "Sun, Planet, Comet"
        case .trojan:         return "Trojan Asteroids"
        case .solarSystem:    return "Solar System"
        case .ellipses:       return "Ellipses"
        case .binaryStar:     return "Binary Star, Planet"
        case .fourStar:       return "Four-Body System"
        case .custom:         return "Custom"
        }
    }
}
