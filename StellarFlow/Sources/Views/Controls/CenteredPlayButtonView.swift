import SwiftUI

/// The transport bar: step-once, play/pause, reset.
/// The play/pause button is the centerpiece, a glowing gold pill flanked by the
/// other two as smaller dark squares.
struct CenteredPlayButtonView: View {
    @ObservedObject var model: SimulationModel

    var body: some View {
        HStack(spacing: 10) {
            stepOnceButton
            playPauseButton
            resetButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(barBackground)
        .cornerRadius(18)
        .shadow(radius: 8)
    }

    /// Buttons

    /// Advances the simulation by exactly one frame regardless of pause state.
    private var stepOnceButton: some View {
        Button {
            model.stepOnce()
        } label: {
            Image(systemName: "forward.frame")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                .frame(width: 30, height: 30)
                .background(squareButtonBackground)
        }
        .buttonStyle(.plain)
    }

    /// Main toggle: starts or stops the integration loop.
    private var playPauseButton: some View {
        Button {
            model.isPaused.toggle()
        } label: {
            Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(
                    ZStack {
                        // Gold gradient fill.
                        RoundedRectangle(cornerRadius: 21)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.85, blue: 0.3),
                                        Color(red: 1.0, green: 0.75, blue: 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        // Subtle top highlight to give the button some dimensionality.
                        RoundedRectangle(cornerRadius: 21)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                )
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.6), radius: 15, x: 0, y: 0)
                .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.4), radius: 20, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }

    /// Reload the most recently selected preset, restoring the original starting state.
    private var resetButton: some View {
        Button {
            model.resetToLastPreset()
        } label: {
            Image(systemName: "gobackward")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                .frame(width: 30, height: 30)
                .background(squareButtonBackground)
        }
        .buttonStyle(.plain)
    }

    /// Chrome

    /// Background used by the small step and reset buttons.
    private var squareButtonBackground: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4), lineWidth: 1.5)
            )
    }

    /// Glassmorphic background of the entire transport bar.
    private var barBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.92))
                .blur(radius: 0.5)
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.5))
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
