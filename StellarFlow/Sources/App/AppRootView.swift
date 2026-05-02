import SwiftUI

/// Top-level switcher between the landing screen and the main simulation.
/// Initially shows `LandingView`. When the user taps Start, fades over to
/// `ContentView` for the rest of the session.
struct AppRootView: View {

    /// Whether the landing screen is currently displayed.
    /// Set to false on first user tap, never reset within a session.
    @State private var showLanding = true

    var body: some View {
        if showLanding {
            LandingView(onStart: {
                withAnimation(.easeOut(duration: 0.4)) {
                    showLanding = false
                }
            })
        } else {
            ContentView()
        }
    }
}
