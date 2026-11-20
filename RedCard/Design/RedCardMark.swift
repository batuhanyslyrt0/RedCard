import SwiftUI

/// The app's signature graphic: a red card with a message bubble cut out of it.
struct RedCardMark: View {
    var width: CGFloat = 120
    /// Size of the bubble relative to its resting size. The launch splash
    /// animates this to make the bubble pop in.
    var bubbleScale: CGFloat = 1

    var body: some View {
        let height = width / Theme.cardAspectRatio
        let shape = RoundedRectangle(cornerRadius: width * Theme.cardCornerFraction)

        shape
            .fill(
                LinearGradient(
                    colors: [Color(.cardShine), Color(.cardRed)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                // Punch the bubble out of the card so the background shows through.
                SpeechBubble()
                    .frame(width: width * 0.54, height: width * 0.48)
                    .scaleEffect(bubbleScale)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .frame(width: width, height: height)
            .shadow(color: Color(.cardRed).opacity(0.35), radius: width * 0.12, y: width * 0.08)
            .accessibilityHidden(true)
    }
}

/// A generic text-message bubble with a tail at the bottom left.
/// Drawn by hand (not an SF Symbol or Apple's Messages icon) so it can also
/// be used in the app icon. `Tools/MakeAppIcon.swift` draws the same shape.
/// `nonisolated` because SwiftUI may compute shape paths off the main actor.
nonisolated struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let bodyHeight = rect.height * 0.8
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: bodyHeight)
        let bubble = Path(roundedRect: body, cornerRadius: bodyHeight * 0.45)

        var tail = Path()
        tail.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: body.maxY - bodyHeight * 0.3))
        tail.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.maxY),
            control: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY - rect.height * 0.08)
        )
        tail.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.4, y: body.maxY - bodyHeight * 0.02),
            control: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY - rect.height * 0.01)
        )
        tail.closeSubpath()

        return bubble.union(tail)
    }
}

#Preview {
    RedCardMark()
        .rotationEffect(Theme.cardRestingTilt)
        .padding(60)
}
