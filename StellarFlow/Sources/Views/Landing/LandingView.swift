import SwiftUI

/// First screen the user sees: title, subtitle, animated aura, and a Start button.
/// Calls `onStart` when the user taps Start, at which point `AppRootView` fades
/// over to `ContentView`.
struct LandingView: View {

    /// Callback fired when the user taps the start button.
    let onStart: () -> Void

    /// Drives the aura blob animation. Incremented by a timer at ~60fps.
    @State private var animationTime: Double = 0

    var body: some View {
        ZStack {
            // Solid dark background, behind everything.
            Color(red: 0.039, green: 0.047, blue: 0.086)
                .ignoresSafeArea()

            // Two large blurred animated gradient blobs.
            GeometryReader { geometry in
                ZStack {
                    AuraBlob(
                        baseX: geometry.size.width * 0.38,
                        baseY: geometry.size.height * 0.30,
                        size: 500,
                        color: Color(hex: "#FFD93D"),
                        opacity: 0.28,
                        animationTime: animationTime,
                        animSpeed: 16.0,
                        scaleSpeed: 14.0,
                        offsetRadius: 40
                    )

                    AuraBlob(
                        baseX: geometry.size.width * 0.62,
                        baseY: geometry.size.height * 0.45,
                        size: 450,
                        color: Color(red: 1.0, green: 0.96, blue: 0.78),
                        opacity: 0.22,
                        animationTime: animationTime,
                        animSpeed: 18.0,
                        scaleSpeed: 16.0,
                        offsetRadius: 35
                    )
                }
                .blur(radius: 140)
            }
            .onAppear {
                // Drive the aura animation. ~60fps, accumulated as elapsed seconds.
                Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                    animationTime += 0.016
                }
            }

            // Slight darkening to keep text readable over the brightest aura phases.
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            // Vignette: corners fade to near-black to focus attention.
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.9)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 450
            )
            .ignoresSafeArea()

            // Bottom fade for the credit text.
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color(red: 0.02, green: 0.03, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Foreground text and button stack.
            VStack(spacing: 0) {
                Spacer()

                // Title.
                Text("StellarFlow")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FFD93D"),
                                Color(hex: "#FFEBB8")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "#FFD93D").opacity(0.28), radius: 45)
                    .shadow(color: Color.black.opacity(0.9), radius: 8, y: 2)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, y: 1)
                    .padding(.bottom, 24)

                // Subtitle.
                Text("Experience zero-gravity orbital dynamics in a living space simulation.")
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .tracking(1.5)
                    .lineSpacing(4)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 64)

                // Start button.
                Button(action: onStart) {
                    Text("Start Simulation")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .tracking(1.0)
                        .padding(.horizontal, 56)
                        .padding(.vertical, 16)
                        .background(
                            ZStack {
                                Color(red: 0.04, green: 0.06, blue: 0.1).opacity(0.6)
                                    .blur(radius: 10)

                                RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(hex: "#FFD93D").opacity(0.6), lineWidth: 1)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .shadow(color: Color(hex: "#FFD93D").opacity(0.35), radius: 50)
                        .shadow(color: Color(hex: "#FFD93D").opacity(0.2), radius: 25)
                        .shadow(color: Color.black.opacity(0.4), radius: 32, y: 8)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Credit.
                Text("Made by Nicolas Villalobos")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Color.gray.opacity(0.5))
                    .tracking(2.0)
                    .padding(.bottom, 40)
            }
            .padding()
        }
    }
}
