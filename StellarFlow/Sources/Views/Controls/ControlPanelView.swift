import SwiftUI

/// The top-right floating panel: preset picker, speed control, time readout,
/// visualization toggles, and zoom slider.
/// Collapsible via the chevron in its header. Sub-sections (speed) are also
/// independently collapsible.
struct ControlPanelView: View {
    @ObservedObject var model: SimulationModel

    /// The signature gold accent used throughout the control chrome.
    private let goldAccent = Color(red: 1.0, green: 0.85, blue: 0.3)

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            collapseHeader

            if !model.isPresetPanelCollapsed {
                expandedPanel
            }
        }
        .padding(14)
        .frame(maxWidth: model.isPresetPanelCollapsed ? 110 : 320, alignment: .topTrailing)
    }

    /// Header

    /// The collapse-toggle button shown above the panel.
    private var collapseHeader: some View {
        HStack {
            Spacer()
            Button {
                model.isPresetPanelCollapsed.toggle()
            } label: {
                HStack(spacing: 5) {
                    if model.isPresetPanelCollapsed {
                        Text("Presets")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    Image(systemName: model.isPresetPanelCollapsed ? "chevron.left.circle.fill" : "chevron.right.circle.fill")
                        .font(.system(size: 22))
                }
                .foregroundColor(goldAccent.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(goldAccent.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 6)
    }

    /// Body

    /// The fully expanded panel, with all five sections stacked vertically.
    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            presetSection
            sectionDivider
            speedSection
            sectionDivider
            timeSection
            sectionDivider
            togglesSection
            sectionDivider
            zoomSection
        }
        .padding(16)
        .background(panelBackground)
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    /// Sections

    /// Preset picker row, including the change handler that ignores `.custom`
    /// (so editing the system doesn't trigger a re-load).
    private var presetSection: some View {
        HStack {
            Text("PRESET")
                .foregroundColor(goldAccent.opacity(0.9))
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
            Spacer()
            Picker("", selection: $model.selectedPreset) {
                ForEach(PresetName.allCases) { p in
                    Text(p.label).tag(p)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .accentColor(goldAccent)
        }
        .onChange(of: model.selectedPreset) { _, newValue in
            // .custom is a marker, not a selectable preset.
            if newValue != .custom {
                model.loadPreset(newValue)
            }
        }
    }

    /// Speed picker plus a custom-multiplier slider when `.custom` is selected.
    private var speedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation {
                    model.isSpeedPanelCollapsed.toggle()
                }
            } label: {
                HStack {
                    Text("SPEED")
                        .foregroundColor(goldAccent.opacity(0.9))
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                    Spacer()
                    Image(systemName: model.isSpeedPanelCollapsed ? "chevron.down" : "chevron.up")
                        .foregroundColor(goldAccent.opacity(0.7))
                        .font(.system(size: 9))
                }
            }
            .buttonStyle(.plain)

            if !model.isSpeedPanelCollapsed {
                Picker("", selection: $model.speed) {
                    Text("Slow").tag(SimulationSpeed.slow)
                    Text("Normal").tag(SimulationSpeed.normal)
                    Text("Fast").tag(SimulationSpeed.fast)
                    Text("Custom").tag(SimulationSpeed.custom)
                }
                .pickerStyle(.segmented)

                if model.speed == .custom {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Multiplier")
                                .font(.system(size: 11))
                            Spacer()
                            Text(String(format: "%.2f×", model.customSpeedMultiplier))
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        Slider(value: $model.customSpeedMultiplier, in: 0.1...5, step: 0.1)
                            .accentColor(goldAccent)
                    }
                }
            }
        }
    }

    /// Elapsed time readout in years, plus a clear button.
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("TIME")
                .foregroundColor(goldAccent.opacity(0.9))
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
            HStack {
                let years = model.time / (365.25 * 24 * 60 * 60)
                Text(String(format: "%.2f years", years))
                    .font(.system(size: 11, design: .monospaced))
                Spacer()
                Button("Clear") {
                    model.clearTime()
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundColor(goldAccent.opacity(0.8))
            }
            .foregroundColor(.white)
        }
    }

    /// Visualization overlay toggles. The Speed sub-toggle and Density picker only
    /// appear when their parent overlay is enabled.
    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOGGLES")
                .foregroundColor(goldAccent.opacity(0.9))
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .padding(.bottom, 2)

            Toggle("Center of Mass", isOn: $model.toggles.centerOfMass)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.3)))
            Toggle("Velocity", isOn: $model.toggles.showVelocity)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.3)))
            if model.toggles.showVelocity {
                Toggle("Speed (km/s)", isOn: $model.toggles.showSpeed)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.3)))
                    .padding(.leading, 16)
            }
            Toggle("Path", isOn: $model.toggles.showPath)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.3)))
            Toggle("Grid", isOn: $model.toggles.showGrid)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.3)))
            Toggle("Vector Field", isOn: $model.toggles.showVectorField)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.3)))

            if model.toggles.showVectorField {
                HStack {
                    Text("Density")
                        .font(.system(size: 11))
                    Picker("", selection: $model.vectorFieldDensity) {
                        Text("Low").tag(SimulationModel.VectorFieldDensity.low)
                        Text("Med").tag(SimulationModel.VectorFieldDensity.medium)
                        Text("High").tag(SimulationModel.VectorFieldDensity.high)
                    }
                    .pickerStyle(.segmented)
                }
                .foregroundColor(.white)
            }
        }
    }

    /// Zoom slider with a numeric readout. Range matches the rest of the rendering code.
    private var zoomSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("ZOOM")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(goldAccent.opacity(0.9))
                    .tracking(0.5)
                Spacer()
                Text(String(format: "%.1f×", model.zoom))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
            }
            Slider(value: $model.zoom, in: 0.2...5.0, step: 0.1)
                .accentColor(goldAccent)
        }
    }

    /// Chrome

    /// Glowing horizontal divider used between sections.
    private var sectionDivider: some View {
        Divider()
            .background(
                LinearGradient(
                    colors: [goldAccent.opacity(0.3), Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.2), radius: 2)
    }

    /// Glassmorphic dark background with a gold gradient stroke and ambient glow.
    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.88))
                .blur(radius: 0.5)
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.4))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [goldAccent.opacity(0.6), Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.15), radius: 20, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}
