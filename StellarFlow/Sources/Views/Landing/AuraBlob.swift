import SwiftUI

/// A large, blurred, slowly orbiting and breathing radial gradient.
/// Used in `LandingView` to create the warm animated background. Two of these are
/// stacked with offset positions and slightly different speeds so the combined
/// motion never repeats exactly within a session.
struct AuraBlob: View {

    /// Center position the blob orbits around.
    let baseX: CGFloat
    let baseY: CGFloat
    /// Untransformed diameter in points.
    let size: CGFloat
    /// Core color of the radial gradient.
    let color: Color
    /// Peak opacity at the gradient's center.
    let opacity: Double
    /// Externally-driven animation clock, in seconds.
    let animationTime: Double
    /// Period (in seconds) of the orbital motion.
    let animSpeed: Double
    /// Period (in seconds) of the size and opacity breathing.
    let scaleSpeed: Double
    /// Radius of the orbital motion around the base position.
    let offsetRadius: CGFloat

    var body: some View {
        // Orbital position around the base point.
        let angle = (animationTime / animSpeed) * .pi * 2
        let x = baseX + cos(angle) * offsetRadius
        let y = baseY + sin(angle) * offsetRadius

        // Breathing factor: smoothly varies between 0.85 and 1.15 over scaleSpeed seconds.
        let breathe = sin(animationTime / scaleSpeed) * 0.15 + 1
        let currentSize = size * breathe
        let currentOpacity = opacity * (0.85 + sin(animationTime / scaleSpeed) * 0.15)

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(currentOpacity),
                        color.opacity(currentOpacity * 0.6),
                        color.opacity(currentOpacity * 0.2),
                        color.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: currentSize / 2
                )
            )
            .frame(width: currentSize, height: currentSize)
            .position(x: x, y: y)
    }
}
