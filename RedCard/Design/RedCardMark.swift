import SwiftUI

/// The app's signature graphic: a flat red card with a crossed-out message
/// bubble ("message blocked"). The same design as the app icon, drawn by
/// `Tools/MakeAppIcon.swift`.
struct RedCardMark: View {
    var width: CGFloat = 120
    /// Size of the bubble relative to its resting size. The launch splash
    /// animates this to make the bubble pop in.
    var bubbleScale: CGFloat = 1

    var body: some View {
        let height = width / Theme.cardAspectRatio
        let bubbleWidth = width * 0.56

        RoundedRectangle(cornerRadius: width * Theme.cardCornerFraction)
            .fill(Color(.cardRed))
            .overlay(alignment: .bottom) {
                // Thin darker band: the edge of a physical card.
                Rectangle()
                    .fill(Color(.cardEdge))
                    .frame(height: height * 0.06)
            }
            .overlay {
                ZStack {
                    SpeechBubble()
                        .fill(.white)
                    BubbleSlash()
                        .stroke(Color(.cardRed), style: StrokeStyle(lineWidth: bubbleWidth * 0.12, lineCap: .round))
                }
                .frame(width: bubbleWidth, height: width * 0.48)
                .scaleEffect(bubbleScale)
            }
            .clipShape(.rect(cornerRadius: width * Theme.cardCornerFraction))
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(0.22), radius: width * 0.1, y: width * 0.06)
            .accessibilityHidden(true)
    }
}

/// The slash across the bubble, from its bottom left to its top right.
nonisolated struct BubbleSlash: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - rect.width * 0.05, y: rect.maxY + rect.height * 0.02))
        path.addLine(to: CGPoint(x: rect.maxX + rect.width * 0.05, y: rect.minY - rect.height * 0.02))
        return path
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
