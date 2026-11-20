import SwiftUI

/// Shared design constants, so every screen looks like the same app.
enum Theme {
    /// Headlines use SF Pro Expanded: the app's one typographic signature.
    static let headline: Font = .title2.bold().width(.expanded)
    static let verdictTitle: Font = .title3.bold().width(.expanded)
    static let splashTitle: Font = .largeTitle.bold().width(.expanded)

    /// The red card graphic.
    static let cardAspectRatio: CGFloat = 0.7
    static let cardCornerFraction: CGFloat = 0.1
    static let cardRestingTilt: Angle = .degrees(-8)

    /// Launch splash: where the card starts and how it moves.
    static let splashStartTilt: Angle = .degrees(32)
    static let splashStartOffset: CGFloat = 520
    static let splashCardIn: Animation = .spring(duration: 0.65, bounce: 0.3)
    static let splashBubbleIn: Animation = .spring(duration: 0.4, bounce: 0.55)
}
