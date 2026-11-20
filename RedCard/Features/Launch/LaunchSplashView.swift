import SwiftUI

/// The short animation shown every time the app opens: the card flips up
/// into place, the message bubble pops out of it, the name appears, and the
/// whole thing fades into the home screen.
///
/// iOS launch screens must be static, so this runs as the first view instead.
/// It starts on the same plain background as the system launch screen, so
/// there is no visible jump between the two.
struct LaunchSplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = Phase.start

    var body: some View {
        VStack(spacing: 32) {
            RedCardMark(width: 132, bubbleScale: phase >= .bubbleIn ? 1 : 0.2)
                .rotationEffect(phase >= .cardIn ? Theme.cardRestingTilt : Theme.splashStartTilt)
                .offset(y: phase >= .cardIn ? 0 : Theme.splashStartOffset)
                .scaleEffect(phase == .exit ? 1.1 : 1)

            Text("Red Card")
                .font(Theme.splashTitle)
                .opacity(phase >= .titleIn ? 1 : 0)
                .offset(y: phase >= .titleIn ? 0 : 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .opacity(phase == .exit ? 0 : 1)
        .sensoryFeedback(.impact(weight: .light), trigger: phase == .bubbleIn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Red Card")
        .task { await play() }
    }

    private func play() async {
        if reduceMotion {
            // No movement: show the finished state, then fade out.
            phase = .titleIn
            try? await Task.sleep(for: .milliseconds(600))
        } else {
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(Theme.splashCardIn) { phase = .cardIn }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(Theme.splashBubbleIn) { phase = .bubbleIn }
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.35)) { phase = .titleIn }
            try? await Task.sleep(for: .milliseconds(650))
        }
        withAnimation(.easeIn(duration: 0.3)) { phase = .exit }
        try? await Task.sleep(for: .milliseconds(300))
        onFinish()
    }

    /// Steps of the animation, in order.
    enum Phase: Int, Comparable {
        case start
        case cardIn
        case bubbleIn
        case titleIn
        case exit

        static func < (lhs: Phase, rhs: Phase) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

#Preview {
    LaunchSplashView {}
}
