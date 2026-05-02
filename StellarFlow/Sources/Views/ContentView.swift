import SwiftUI

/// The main simulation screen, composed of the canvas with floating control overlays.

/// Layout, layered back-to-front:
/// 1. `SimulationCanvasView` (full-screen, owns pan gestures)
/// 2. Top-right: `ControlPanelView` (presets, speed, toggles, zoom)
/// 3. Top-left: debug readout and transient preset notification
/// 4. Bottom: `MassControlPanelView` and the `CenteredPlayButtonView` + `BodyCountControlView` stack

/// The integration loop is driven by a 60Hz timer that calls `model.stepSimulation()`.
struct ContentView: View {

    /// The simulation state, owned by this view and shared down to all controls.
    @StateObject private var model = SimulationModel()

    /// 60Hz frame timer that drives the integration loop.
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Simulation canvas, stable-identified to prevent SwiftUI from rebuilding it
            //    when sibling state changes.
            SimulationCanvasView(model: model)
                .id("stable-canvas")

            // 2. Top-right control panel.
            VStack {
                Spacer().frame(height: 0)
                HStack {
                    Spacer().frame(width: 0)
                    ControlPanelView(model: model)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // 3. Top-left debug overlay. Pass-through for hit testing so it doesn't
            //    block canvas drags.
            debugOverlay
                .allowsHitTesting(false)

            // 4. Bottom controls.
            bottomControls
                .padding([.leading, .trailing, .bottom], 14)
                .allowsHitTesting(true)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.01, green: 0.02, blue: 0.04), Color(red: 0.02, green: 0.03, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onReceive(timer) { _ in
            model.stepSimulation()
        }
    }

    /// Subviews

    /// Top-left debug readout: last change identifier and a transient preset banner.
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last change: \(model.lastChange)")
                .font(.caption)
                .padding(6)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.leading, 16)
                .padding(.top, 16)

            if model.showPresetNotification {
                Text("Preset: \(model.selectedPreset == .custom ? "Custom" : model.selectedPreset.label)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.3))
                    )
                    .foregroundColor(Color(red: 0.02, green: 0.03, blue: 0.05))
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.5), radius: 12)
                    .padding(.leading, 16)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: model.showPresetNotification)
            }

            Spacer()
        }
    }

    /// Bottom row: mass panel on the left, transport bar and body-count control
    /// stacked on the right.
    private var bottomControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            HStack(alignment: .bottom, spacing: 14) {
                MassControlPanelView(model: model)
                Spacer()
                VStack(spacing: 16) {
                    CenteredPlayButtonView(model: model)
                    BodyCountControlView(model: model)
                }
            }
        }
    }
}
