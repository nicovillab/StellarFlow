# StellarFlow

A real-time n-body gravitational simulator for iPad and iPhone, built entirely in Swift Playgrounds.

Pick a preset, watch the orbits form, drag the camera, change masses on the fly, and toggle visualization overlays for velocity vectors, the gravitational vector field, the system's center of mass, and more.

<img width="2360" height="1640" alt="StellarFlow Screnshot 1" src="https://github.com/user-attachments/assets/b9a91931-8f32-4aa8-bb0c-400f702a3a59" />

## Features

- **Seven built-in presets**: Sun + planet, sun + planet + comet, Trojan asteroids at the Sun-Jupiter L4/L5 Lagrange points, a scaled solar system, elliptical orbits, a binary star with circumbinary planet, and a four-body rotating square
- **Live editing**: add bodies, remove bodies, change masses with sliders or steppers, all while the simulation runs
- **Six visualization overlays**: AU-scaled grid, orbital trails, velocity arrows with optional km/s labels, gravitational vector field, center of mass marker, and per-body data table
- **Camera controls**: drag to pan, slider to zoom, persistent across preset loads
- **Time controls**: slow / normal / fast / custom multiplier, plus a step-once button for frame-by-frame inspection
- **Glassmorphic UI**: collapsible panels, gold accent system

## Stack

- Swift 5.9
- SwiftUI (`Canvas` for the simulation, native controls everywhere else)
- iOS 18.1+
- No third-party dependencies

## Physics

The integrator is semi-implicit (symplectic) Euler over an `O(n²)` direct summation of pairwise gravitational forces. The fixed timestep is one Earth day per integration step, scaled by the user's speed multiplier. Trails are capped at 500 points per body. A small distance-squared softening prevents singularities when bodies pass close to each other.

This is enough to keep two-body and most three-body orbits visually stable over hundreds of simulated years. It is not a research-grade integrator.

## Project Structure

```
StellarFlow/
├── Package.swift
└── Sources/
    ├── App/
    │   ├── StellarFlowApp.swift          App entry point
    │   └── AppRootView.swift             Landing → content router
    ├── Models/
    │   ├── Body.swift                    Body, BodyType, TrailPoint
    │   ├── VisualizationToggles.swift    Overlay flags
    │   ├── SimulationSpeed.swift         Speed enum
    │   └── PresetName.swift              Preset enum
    ├── Simulation/
    │   ├── SimulationModel.swift         State and body mutation
    │   ├── SimulationModel+Physics.swift Verlet integration step
    │   ├── SimulationModel+Presets.swift Body construction per preset
    │   └── SimulationModel+Camera.swift  World-to-screen transforms
    ├── Views/
    │   ├── ContentView.swift             Main composed view
    │   ├── Canvas/
    │   │   └── SimulationCanvasView.swift Canvas-based renderer
    │   ├── Controls/
    │   │   ├── ControlPanelView.swift
    │   │   ├── MassControlPanelView.swift
    │   │   ├── MassSliderRowView.swift
    │   │   ├── FullDataRow.swift
    │   │   ├── BodyCountControlView.swift
    │   │   └── CenteredPlayButtonView.swift
    │   └── Landing/
    │       ├── LandingView.swift
    │       └── AuraBlob.swift
    └── Extensions/
        └── Color+Extensions.swift        Hex init, random palette
```

## Building

### Swift Playgrounds (iPad or Mac)

1. Open `StellarFlow.swiftpm` in Swift Playgrounds
2. Tap the run button

Note: the iPad version of Swift Playgrounds shows files in a flat list rather than a folder tree, but the project still builds correctly. Folder structure is preserved for Xcode and on disk.

### Xcode

1. Open `Package.swift` in Xcode
2. Select an iOS 18.1+ simulator or device
3. Cmd+R

## Notes on the Codebase

`SimulationModel` is the single source of truth and is observed by every view. It is split across four files (state, physics, presets, camera) by extension for readability, but it remains one class.

The canvas is rendered imperatively into a SwiftUI `Canvas` rather than as a view hierarchy. With trails of up to 500 points per body, view diffing would dominate frame time; the canvas approach lets each frame draw in a single pass.

UI state (panel collapse, selection) lives on the model rather than as `@State` on individual views, so the layout survives view recreation when SwiftUI decides to rebuild.

## Author

Nicolas Villalobos
