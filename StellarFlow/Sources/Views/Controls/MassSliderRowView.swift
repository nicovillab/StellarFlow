import SwiftUI

/// One row of the compact mass panel: a single body's mass control.
/// Includes a color swatch, name, numeric mass readout, +/- 1 buttons, a slider,
/// and a remove button. Tapping the row selects the body.
struct MassSliderRowView: View {
    @ObservedObject var model: SimulationModel

    /// Snapshot of the body to render. Reads back into the model via callbacks.
    let bodyData: Body

    /// Index of this body in the model's array.
    /// Used to label non-sun bodies as "Body 0", "Body 1", etc.
    var bodyIndex: Int {
        model.bodies.firstIndex(where: { $0.id == bodyData.id }) ?? 0
    }

    var body: some View {
        // Mass scale: slider value is in units of 10²⁸ kg, matching the panel header.
        let massUnits = bodyData.mass / 1e28

        return HStack(spacing: 6) {
            // Color swatch.
            Circle()
                .fill(bodyData.color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(bodyData.color.opacity(0.5), lineWidth: 1))

            // Name.
            Text(bodyData.type == .sun ? "Sun" : "Body \(bodyIndex)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 55, alignment: .leading)

            // Numeric mass readout.
            Text(String(format: "%.1f", massUnits))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                .frame(width: 45, alignment: .trailing)

            // Step-down by 1 unit.
            Button {
                let newValue = max(0.1, massUnits - 1.0)
                model.changeMass(bodyId: bodyData.id, massUnits: newValue)
            } label: {
                stepperButtonLabel(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            // Continuous mass slider, range chosen to make small bodies and stars
            // both controllable on a single scale.
            Slider(
                value: Binding(
                    get: { massUnits },
                    set: { model.changeMass(bodyId: bodyData.id, massUnits: $0) }
                ),
                in: 0.1...300.0,
                step: 0.5
            )
            .accentColor(Color(red: 1.0, green: 0.85, blue: 0.3))

            // Step-up by 1 unit.
            Button {
                let newValue = min(300.0, massUnits + 1.0)
                model.changeMass(bodyId: bodyData.id, massUnits: newValue)
            } label: {
                stepperButtonLabel(systemName: "chevron.right")
            }
            .buttonStyle(.plain)

            // Remove this body.
            Button {
                model.removeBody(bodyId: bodyData.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(rowBackground)
        .onTapGesture {
            model.selectedBodyId = bodyData.id
        }
    }

    /// Shared visual for the +/- stepper buttons.
    private func stepperButtonLabel(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
            .frame(width: 24, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.3), lineWidth: 1)
                    )
            )
    }

    /// Highlights the row in gold when its body is the selected one.
    private var rowBackground: some View {
        let isSelected = bodyData.id == model.selectedBodyId
        return RoundedRectangle(cornerRadius: 9)
            .fill(isSelected ? Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isSelected ? Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
}
