import SwiftUI

/// One row of the expanded data table: full position and velocity columns for a body.
///
/// Shown when the user expands the mass panel via "More Data". Tapping the row
/// selects the body, matching `MassSliderRowView`'s behavior.
struct FullDataRow: View {
    @ObservedObject var model: SimulationModel
    let bodyData: Body
    /// One astronomical unit in meters, passed in to convert position from meters
    /// to AU for display.
    let AU: Double

    var bodyIndex: Int {
        model.bodies.firstIndex(where: { $0.id == bodyData.id }) ?? 0
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(bodyData.color)
                .frame(width: 10, height: 10)

            Text(bodyData.type == .sun ? "Sun" : "Body \(bodyIndex)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)

            // Mass in units of 10²⁸ kg.
            Text(String(format: "%.1f", bodyData.mass / 1e28))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .trailing)

            // Position in AU.
            Text(String(format: "%.3f", bodyData.x / AU))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 70, alignment: .trailing)

            Text(String(format: "%.3f", bodyData.y / AU))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 70, alignment: .trailing)

            // Velocity in km/s, color-matched to the canvas velocity arrows.
            Text(String(format: "%.2f", bodyData.vx / 1000))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(red: 0.3, green: 1.0, blue: 0.53))
                .frame(width: 80, alignment: .trailing)

            Text(String(format: "%.2f", bodyData.vy / 1000))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(red: 0.3, green: 1.0, blue: 0.53))
                .frame(width: 80, alignment: .trailing)

            Button {
                model.removeBody(bodyId: bodyData.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
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

    /// Highlight the row when its body is selected.
    private var rowBackground: some View {
        let isSelected = bodyData.id == model.selectedBodyId
        return RoundedRectangle(cornerRadius: 7)
            .fill(isSelected ? Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isSelected ? Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
}
