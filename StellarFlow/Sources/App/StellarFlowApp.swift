import SwiftUI

/// App entry point.
/// Hosts a single `WindowGroup` containing `AppRootView`, which handles the
/// landing → content transition.
@main
struct StellarFlowApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
