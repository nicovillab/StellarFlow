import Foundation

extension SimulationModel {

    /// Advances the simulation by one symplectic Euler step.
    /// Symplectic (vs plain) Euler preserves orbital energy over long runs, keeping orbits closed.
    /// No-ops while paused, while a mutation is in progress, or with no bodies.
    func stepSimulation() {
        guard !isPaused && !isUpdating && !bodies.isEmpty else { return }

        let mult: Double
        switch speed {
        case .slow:   mult = 0.3
        case .normal: mult = 1.0
        case .fast:   mult = 3.0
        case .custom: mult = customSpeedMultiplier
        }

        let dt = TIME_STEP * mult

        // Pass 1: compute accelerations from current positions.
        var accelerations: [(ax: Double, ay: Double)] = []

        for i in 0..<bodies.count {
            var ax = 0.0, ay = 0.0

            for j in 0..<bodies.count where i != j {
                let dx = bodies[j].x - bodies[i].x
                let dy = bodies[j].y - bodies[i].y
                let distSq = dx * dx + dy * dy

                // Skip extremely close pairs to avoid divide-by-zero.
                guard distSq > 1e6 else { continue }

                let dist  = sqrt(distSq)
                let force = G * bodies[j].mass / distSq
                ax += force * (dx / dist)
                ay += force * (dy / dist)
            }

            accelerations.append((ax, ay))
        }

        guard accelerations.count == bodies.count else { return }

        // Pass 2: integrate velocity then position; cap trail at 500 points.
        for i in 0..<bodies.count {
            bodies[i].vx += accelerations[i].ax * dt
            bodies[i].vy += accelerations[i].ay * dt
            bodies[i].x  += bodies[i].vx * dt
            bodies[i].y  += bodies[i].vy * dt

            if bodies[i].trail.count > 500 { bodies[i].trail.removeFirst() }
            bodies[i].trail.append(TrailPoint(x: bodies[i].x, y: bodies[i].y))
        }

        time += dt
    }

    /// Advances exactly one step regardless of pause state — for frame-by-frame inspection.
    func stepOnce() {
        let oldPaused = isPaused
        isPaused = false
        stepSimulation()
        isPaused = oldPaused
    }

    /// Resets elapsed time and clears all trails without moving bodies.
    func clearTime() {
        time = 0
        for i in 0..<bodies.count { bodies[i].trail = [] }
    }
}
