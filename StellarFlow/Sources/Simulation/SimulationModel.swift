import SwiftUI
import Combine

/// Single source of truth for the simulation — owns body state, camera, UI state, and the integration loop.
/// Split across: SimulationModel.swift (this), +Physics, +Presets, +Camera.
final class SimulationModel: ObservableObject {

    /// Physical Constants

    let G         = 6.674e-11
    let SCALE     = 1e9               // meters per pixel at zoom 1.0
    let TIME_STEP = 60.0 * 60.0 * 24.0 // one Earth day per frame at normal speed
    let AU        = 1.496e11

    /// Simulation State

    @Published var bodies: [Body] = []
    @Published var time: Double = 0
    @Published var isPaused: Bool = true
    @Published var speed: SimulationSpeed = .normal
    @Published var customSpeedMultiplier: Double = 1.0

    /// Camera State

    @Published var zoom: Double = 1.0  // persists across preset loads by design
    @Published var panX: Double = 0
    @Published var panY: Double = 0

    /// UI State

    @Published var selectedBodyId: Int? = nil
    @Published var toggles = VisualizationToggles()
    @Published var forceScale: Double = 1e20  // reserved for future force-arrow overlay
    @Published var selectedPreset: PresetName = .sunPlanet
    @Published var vectorFieldDensity: VectorFieldDensity = .medium
    @Published var lastChange: String = "none"
    @Published var showPresetNotification: Bool = false
    @Published var isSpeedPanelCollapsed: Bool = false
    @Published var isPresetPanelCollapsed: Bool = false
    @Published var isMassPanelCollapsed: Bool = false
    @Published var isMassDataExpanded: Bool = false

    /// Internal State

    var isUpdating = false  // re-entrancy guard; integrator and add/remove must not interleave
    var lastLoadedPreset: PresetName = .sunPlanet
    var presetBodyStates: [PresetName: [Body]] = [:]  // cached so re-loading returns the original state

    enum VectorFieldDensity { case low, medium, high }

    var nextBodyId = 0

    init() {
        loadPreset(.sunPlanet)
    }

    /// Body Modification

    /// Updates mass for the given body. `massUnits` is in units of 10²⁸ kg (matches slider scale).
    func changeMass(bodyId: Int, massUnits: Double) {
        if let index = bodies.firstIndex(where: { $0.id == bodyId }) {
            bodies[index].mass = massUnits * 1e28
            markAsCustom(changeType: "mass-change")
        }
    }

    /// Adds a randomly-placed body in a stable orbit. No-op if a mutation is in progress.
    func addBody() {
        guard !isUpdating else { return }
        isUpdating = true
        addRandomBody()
        isUpdating = false
    }

    /// Removes a body by ID. Refuses to remove the last body. Clears selection if needed.
    func removeBody(bodyId: Int) {
        guard bodies.count > 1, !isUpdating else { return }
        isUpdating = true

        if let index = bodies.firstIndex(where: { $0.id == bodyId }) {
            bodies.remove(at: index)
            if selectedBodyId == bodyId { selectedBodyId = bodies.first?.id }
            markAsCustom(changeType: "remove-body")
        }

        isUpdating = false
    }

    /// Places a new planet in a random circular orbit around an implicit 2×10³⁰ kg primary.
    private func addRandomBody() {
        let angle    = Double.random(in: 0..<(2 * Double.pi))
        let distance = Double.random(in: 0.5...2.0) * AU
        let speed    = sqrt(G * 2e30 / distance)

        let body = Body(
            id: nextBodyId,
            x: cos(angle) * distance,
            y: sin(angle) * distance,
            vx: -sin(angle) * speed * Double.random(in: 0.8...1.2),
            vy:  cos(angle) * speed * Double.random(in: 0.8...1.2),
            mass: Double.random(in: 0.5...5.0) * 1e28,
            color: Color.randomPalette(),
            type: .planet,
            trail: [],
            displayRadius: nil
        )
        nextBodyId += 1
        bodies.append(body)
        markAsCustom(changeType: "add-body")
    }

    /// Switches preset to `.custom` and briefly shows the notification banner.
    private func markAsCustom(changeType: String) {
        selectedPreset = .custom
        lastChange = changeType
        showPresetNotification = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showPresetNotification = false
        }
    }
}
