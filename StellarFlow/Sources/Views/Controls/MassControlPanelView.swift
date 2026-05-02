import SwiftUI

/// Bottom-left floating panel for per-body mass controls.
/// Compact mode shows mass sliders; expanded mode shows a scrollable position/velocity table.
/// The chevron header collapses or expands the panel.
struct MassControlPanelView: View {
    @ObservedObject var model: SimulationModel

    /// One astronomical unit in meters, used for the position columns in expanded mode.
    private let AU = 1.496e11
    private let goldAccent = Color(red: 1.0, green: 0.85, blue: 0.3)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            if !model.isMassPanelCollapsed {
                if !model.isMassDataExpanded {
                    compactRows
                } else {
                    expandedTable
                }
            }
        }
        .frame(maxWidth: model.isMassPanelCollapsed ? 140 : 500)
        .background(panelBackground)
        .cornerRadius(20)
        .shadow(radius: 8)
    }

    /// Header

    /// Header with collapse toggle on the left and an expand-data toggle on the right.
    private var header: some View {
        HStack {
            Button {
                withAnimation {
                    model.isMassPanelCollapsed.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: model.isMassPanelCollapsed ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 16))
                    if model.isMassPanelCollapsed {
                        Text("Mass Panel")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 5)
                .frame(minHeight: 30)
            }
            .buttonStyle(.plain)

            if !model.isMassPanelCollapsed {
                Text("MASS (10²⁸ kg)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(goldAccent.opacity(0.7))
            }

            Spacer()

            if !model.isMassPanelCollapsed {
                Button {
                    withAnimation {
                        model.isMassDataExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("More Data")
                            .font(.system(size: 10, weight: .medium))
                        Image(systemName: model.isMassDataExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(goldAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 3)
    }

    /// Body Content

    /// Compact list of mass sliders, one row per body.
    private var compactRows: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(model.bodies) { bodyItem in
                MassSliderRowView(model: model, bodyData: bodyItem)
            }
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 3)
    }

    /// Expanded data table with full position and velocity columns.
    /// Wrapped in a horizontal scroll view because the columns easily exceed the
    /// panel width on phones.
    private var expandedTable: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 10) {
                    Circle().fill(Color.clear).frame(width: 10, height: 10)
                    Text("Name").frame(width: 50, alignment: .leading)
                    Text("Mass").frame(width: 60, alignment: .trailing)
                    Text("X (AU)").frame(width: 70, alignment: .trailing)
                    Text("Y (AU)").frame(width: 70, alignment: .trailing)
                    Text("vₓ (km/s)").frame(width: 80, alignment: .trailing)
                    Text("vᵧ (km/s)").frame(width: 80, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(goldAccent.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)

                ForEach(model.bodies) { bodyItem in
                    FullDataRow(model: model, bodyData: bodyItem, AU: AU)
                }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 3)
        }
    }

    /// Chrome

    /// Glassmorphic background matching the other floating panels.
    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.85))
                .blur(radius: 0.5)
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.5))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [goldAccent.opacity(0.5), Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.15), radius: 18, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}
