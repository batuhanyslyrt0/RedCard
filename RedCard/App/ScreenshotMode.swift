import Foundation

/// Opens the app straight on one screen, for App Store screenshots.
/// Only in Debug builds; release builds always start normally.
///
///     xcrun simctl launch <device> com.batuhan.redcard -RedCardScreenshot tester
///
/// See `Tools/screenshots.sh`.
enum ScreenshotMode: String {
    case home
    case tester
    case setup

    static var current: ScreenshotMode? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "RedCardScreenshot").flatMap(ScreenshotMode.init(rawValue:))
        #else
        nil
        #endif
    }
}
