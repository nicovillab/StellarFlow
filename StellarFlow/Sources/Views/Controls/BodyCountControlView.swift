import SwiftUI

/// Compact bottom-right control showing the current body count and a `+` button
/// to add a randomly-placed body. Capped at 10 bodies because the integrator is
/// O(n²) and visual clutter dominates beyond that.
struct BodyCountControlView: View {
    @ObservedObject var model: SimulationModel

    var body: some View {
        HStack(spacing: 10) {
            Text("Bodies")
                .foregroundColor(.white)
                .font(.system(size: 12))

            Text("\(model.bodies.count)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 35, alignment: .center)

            Button {
                model.addBody()
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4), lineWidth: 1.5)
                    )
            )
            .disabled(model.bodies.count >= 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(controlBackground)
        .cornerRadius(18)
        .shadow(radius: 8)
    }

    /// Glassmorphic background matching the other floating controls.
    private var controlBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.88))
                .blur(radius: 0.5)
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.4))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.5), Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.15), radius: 16, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}
