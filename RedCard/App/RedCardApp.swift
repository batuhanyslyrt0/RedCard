import SwiftUI

@main
struct RedCardApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = SettingsModel()
    @State private var isShowingSplash = ScreenshotMode.current == nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .environment(model)

                if isShowingSplash {
                    LaunchSplashView {
                        isShowingSplash = false
                    }
                    .zIndex(1)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Each time the app comes to the front, look for newer rules.
            // The updater itself limits this to once a day.
            if phase == .active {
                Task { await model.refreshRules() }
            }
        }
    }
}
