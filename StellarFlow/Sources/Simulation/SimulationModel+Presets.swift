import SwiftUI

extension SimulationModel {

    /// Preset Lifecycle
    /// Loads a preset, restoring from cache if previously loaded (so re-loading always returns
    /// to the same initial state). Camera state intentionally does not reset.
    /// Dispatched one runloop tick ahead to avoid re-entrancy with the integration timer.
    func loadPreset(_ preset: PresetName) {
        guard !isUpdating else { return }
        isUpdating = true
        isPaused = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self = self else { return }

            if let saved = self.presetBodyStates[preset] {
                self.bodies = saved.map { var b = $0; b.trail = []; return b }
            } else {
                self.createPresetBodies(preset)
                self.presetBodyStates[preset] = self.bodies
            }

            self.time = 0
            self.selectedBodyId = self.bodies.first?.id
            self.lastLoadedPreset = preset
            self.selectedPreset = preset
            self.lastChange = preset.rawValue
            self.isUpdating = false
        }
    }

    /// Re-loads the most recently loaded preset. Wired to the reset button.
    func resetToLastPreset() {
        loadPreset(lastLoadedPreset)
    }


    /// Preset Construction
    /// Builds the initial body list for `preset`, replacing `bodies`.
    private func createPresetBodies(_ preset: PresetName) {
        nextBodyId = 0
        bodies = []

        switch preset {
        case .sunPlanet:      buildSunPlanet()
        case .sunPlanetComet: buildSunPlanetComet()
        case .trojan:         buildTrojan()
        case .solarSystem:    buildSolarSystem()
        case .ellipses:       buildEllipses()
        case .binaryStar:     buildBinaryStar()
        case .fourStar:       buildFourStar()
        case .custom:         break  // marker only, never directly loaded
        }
    }

    /// Individual Presets

    private func buildSunPlanet() {
        bodies = [
            Body(id: nextBodyId, x: 0, y: 0, vx: 0, vy: 0,
                 mass: 2e30, color: Color(hex: "#FDB813"), type: .sun, trail: [], displayRadius: nil),
        ]
        nextBodyId += 1

        let dist  = AU
        let speed = sqrt(G * 2e30 / dist)
        bodies.append(Body(id: nextBodyId, x: dist, y: 0, vx: 0, vy: speed,
                           mass: 6e28, color: Color(hex: "#4A9EFF"), type: .planet, trail: [], displayRadius: nil))
        nextBodyId += 1
    }

    private func buildSunPlanetComet() {
        buildSunPlanet()

        bodies.append(Body(id: nextBodyId, x: -2 * AU, y: 0, vx: 0, vy: -15000,
                           mass: 1e25, color: Color(hex: "#888888"), type: .comet, trail: [], displayRadius: nil))
        nextBodyId += 1
    }

    /// Sun + Jupiter at 5.2 AU + asteroid clusters at L4 (+60°) and L5 (-60°).
    private func buildTrojan() {
        let sunMass = 2e30
        bodies = [
            Body(id: nextBodyId, x: 0, y: 0, vx: 0, vy: 0,
                 mass: sunMass, color: Color(hex: "#FDB813"), type: .sun, trail: [], displayRadius: nil),
        ]
        nextBodyId += 1

        let jupiterDist  = 5.2 * AU
        let jupiterSpeed = sqrt(G * sunMass / jupiterDist)
        let jupiterMass  = 1.9e29
        bodies.append(Body(id: nextBodyId, x: jupiterDist, y: 0, vx: 0, vy: jupiterSpeed,
                           mass: jupiterMass, color: Color(hex: "#C88B3A"), type: .planet, trail: [], displayRadius: nil))
        nextBodyId += 1

        let angle60 = Double.pi / 3.0
        let asteroidMass    = 1e22
        let clusterSpread   = 0.05 * AU
        let asteroidsPerPoint = 6

        for (lagrangeAngle, _) in [(angle60, "L4"), (-angle60, "L5")] {
            let lx  = jupiterDist * cos(lagrangeAngle)
            let ly  = jupiterDist * sin(lagrangeAngle)
            let lvx = -sin(lagrangeAngle) * jupiterSpeed
            let lvy =  cos(lagrangeAngle) * jupiterSpeed

            for i in 0..<asteroidsPerPoint {
                let a   = Double(i) * (Double.pi * 2.0 / Double(asteroidsPerPoint))
                let r   = clusterSpread * 0.7
                let dx  = cos(a) * r;  let dy  = sin(a) * r
                let dvx = -sin(a) * (jupiterSpeed * 0.02)
                let dvy =  cos(a) * (jupiterSpeed * 0.02)

                bodies.append(Body(id: nextBodyId, x: lx + dx, y: ly + dy,
                                   vx: lvx + dvx, vy: lvy + dvy,
                                   mass: asteroidMass, color: Color(hex: "#888888"),
                                   type: .comet, trail: [], displayRadius: 4))
                nextBodyId += 1
            }
        }
    }

    /// Scaled solar system with five inner planets.
    private func buildSolarSystem() {
        let sunMass = 1.989e30
        bodies = [
            Body(id: nextBodyId, x: 0, y: 0, vx: 0, vy: 0,
                 mass: sunMass, color: Color(hex: "#FDB813"), type: .sun, trail: [], displayRadius: 20),
        ]
        nextBodyId += 1

        let planets: [(dist: Double, mass: Double, color: String)] = [
            (0.4 * AU, 3.3e26, "#8C7853"),
            (0.7 * AU, 4.9e27, "#FFC649"),
            (1.0 * AU, 6.0e27, "#4A9EFF"),
            (1.6 * AU, 6.4e26, "#E27B58"),
            (2.5 * AU, 3.0e27, "#A78BFA"),
        ]

        for p in planets {
            let speed = sqrt(G * sunMass / p.dist)
            bodies.append(Body(id: nextBodyId, x: p.dist, y: 0, vx: 0, vy: speed,
                               mass: p.mass, color: Color(hex: p.color), type: .planet, trail: [], displayRadius: nil))
            nextBodyId += 1
        }
    }

    /// Two planets with sub-circular speeds, producing visible elliptical orbits.
    private func buildEllipses() {
        bodies = [
            Body(id: nextBodyId, x: 0, y: 0, vx: 0, vy: 0,
                 mass: 2e30, color: Color(hex: "#FDB813"), type: .sun, trail: [], displayRadius: nil),
        ]
        nextBodyId += 1

        bodies.append(Body(id: nextBodyId, x: AU,        y: 0, vx: 0, vy: 35000,
                           mass: 6e28, color: Color(hex: "#4A9EFF"), type: .planet, trail: [], displayRadius: nil))
        nextBodyId += 1

        bodies.append(Body(id: nextBodyId, x: 1.5 * AU, y: 0, vx: 0, vy: 20000,
                           mass: 4e28, color: Color(hex: "#FF6B9D"), type: .planet, trail: [], displayRadius: nil))
        nextBodyId += 1
    }

    /// Two stars orbiting their barycenter + a circumbinary planet at 2 AU.
    private func buildBinaryStar() {
        let d = 0.5 * AU
        let m1 = 2e30, m2 = 1.5e30
        let totalMass = m1 + m2
        let r1 = d * m2 / totalMass
        let r2 = d * m1 / totalMass
        let omega = sqrt(G * totalMass / (d * d * d))

        bodies = [
            Body(id: nextBodyId, x:  r1, y: 0, vx: 0, vy:  omega * r1,
                 mass: m1, color: Color(hex: "#FDB813"), type: .sun, trail: [], displayRadius: nil),
        ]
        nextBodyId += 1

        bodies.append(Body(id: nextBodyId, x: -r2, y: 0, vx: 0, vy: -(omega * r2),
                           mass: m2, color: Color(hex: "#FF6B6B"), type: .sun, trail: [], displayRadius: nil))
        nextBodyId += 1

        let planetDist = 2.0 * AU
        bodies.append(Body(id: nextBodyId, x: planetDist, y: 0, vx: 0, vy: sqrt(G * totalMass / planetDist),
                           mass: 6e28, color: Color(hex: "#4A9EFF"), type: .planet, trail: [], displayRadius: nil))
        nextBodyId += 1
    }

    /// Four equal-mass stars at square corners, rotating about the center.
    /// Speed derived from balancing centripetal force against the net gravity of the other three;
    /// the 1.914 factor absorbs the two adjacent (distance s) + one diagonal (distance s√2) geometry.
    private func buildFourStar() {
        let s        = 0.4 * AU
        let starMass = 1e30
        let r        = s / sqrt(2.0)
        let omega    = sqrt(G * starMass * 1.914 / (s * s * s))
        let v        = omega * r

        let configs: [(x: Double, y: Double, vx: Double, vy: Double, color: String)] = [
            ( r,  0,  0,  v, "#FDB813"),
            ( 0,  r, -v,  0, "#FF6B6B"),
            (-r,  0,  0, -v, "#4ECDC4"),
            ( 0, -r,  v,  0, "#A78BFA"),
        ]

        bodies = configs.map { c in
            defer { nextBodyId += 1 }
            return Body(id: nextBodyId, x: c.x, y: c.y, vx: c.vx, vy: c.vy,
                        mass: starMass, color: Color(hex: c.color), type: .sun, trail: [], displayRadius: nil)
        }
    }
}
