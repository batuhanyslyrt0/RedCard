// Draws Red Card's app icons (light, dark, tinted) as 1024×1024 PNGs.
// Run from the project folder:  swift Tools/MakeAppIcon.swift
//
// Design: a flat red card, slightly tilted, with a thin darker band along the
// bottom edge and a white message bubble crossed out by a red slash
// ("message blocked"). Keep in sync with RedCardMark.swift.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputFolder = URL(fileURLWithPath: "RedCard/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

struct Palette {
    var background: CGColor
    var card: CGColor
    var cardEdge: CGColor
    var bubble: CGColor
    var shadow: CGColor
}

func rgb(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

/// The same message bubble as `SpeechBubble` in the app (tail at the bottom
/// left). Built with y pointing down like SwiftUI, then flipped for Core Graphics.
func bubblePath(in rect: CGRect) -> CGPath {
    let w = rect.width, h = rect.height
    let bodyHeight = h * 0.8
    let body = CGPath(roundedRect: CGRect(x: 0, y: 0, width: w, height: bodyHeight),
                      cornerWidth: bodyHeight * 0.45, cornerHeight: bodyHeight * 0.45, transform: nil)
    let tail = CGMutablePath()
    tail.move(to: CGPoint(x: w * 0.14, y: bodyHeight - bodyHeight * 0.3))
    tail.addQuadCurve(to: CGPoint(x: w * 0.04, y: h), control: CGPoint(x: w * 0.16, y: h - h * 0.08))
    tail.addQuadCurve(to: CGPoint(x: w * 0.4, y: bodyHeight - bodyHeight * 0.02),
                      control: CGPoint(x: w * 0.24, y: h - h * 0.01))
    tail.closeSubpath()

    var flip = CGAffineTransform(translationX: rect.minX, y: rect.maxY).scaledBy(x: 1, y: -1)
    return body.union(tail).copy(using: &flip) ?? body
}

func drawIcon(palette: Palette, to url: URL) throws {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { throw CocoaError(.featureUnsupported) }

    // App Store icons must be opaque: a flat background, no alpha.
    context.setFillColor(palette.background)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))

    let cardWidth: CGFloat = 460
    let cardHeight = cardWidth / 0.7
    let cardRect = CGRect(x: -cardWidth / 2, y: -cardHeight / 2, width: cardWidth, height: cardHeight)
    let cardPath = CGPath(roundedRect: cardRect, cornerWidth: cardWidth * 0.09,
                          cornerHeight: cardWidth * 0.09, transform: nil)

    context.saveGState()
    context.translateBy(x: size / 2 + 8, y: size / 2 - 8)
    context.rotate(by: 9.6 * .pi / 180) // matches the -8° tilt used in the app

    // Card with a soft, neutral shadow
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -28), blur: 60, color: palette.shadow)
    context.addPath(cardPath)
    context.setFillColor(palette.card)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(cardPath)
    context.clip()

    // Thin darker band: the edge of a physical card
    context.setFillColor(palette.cardEdge)
    context.fill(CGRect(x: cardRect.minX, y: cardRect.minY, width: cardWidth, height: cardHeight * 0.06))

    // White bubble, crossed out
    let bubbleWidth = cardWidth * 0.56
    let bubbleHeight = cardWidth * 0.48
    let bubbleRect = CGRect(x: -bubbleWidth / 2, y: -bubbleHeight / 2, width: bubbleWidth, height: bubbleHeight)
    context.addPath(bubblePath(in: bubbleRect))
    context.setFillColor(palette.bubble)
    context.fillPath()

    context.setStrokeColor(palette.card)
    context.setLineCap(.round)
    context.setLineWidth(bubbleWidth * 0.12)
    context.move(to: CGPoint(x: bubbleRect.minX - bubbleWidth * 0.05, y: bubbleRect.minY - bubbleHeight * 0.02))
    context.addLine(to: CGPoint(x: bubbleRect.maxX + bubbleWidth * 0.05, y: bubbleRect.maxY + bubbleHeight * 0.02))
    context.strokePath()

    context.restoreGState()
    context.restoreGState()

    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw CocoaError(.fileWriteUnknown) }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

let light = Palette(background: rgb(0xF4F4F6), card: rgb(0xC8102E), cardEdge: rgb(0x9E0B23),
                    bubble: rgb(0xFFFFFF), shadow: rgb(0x000000, alpha: 0.22))
let dark = Palette(background: rgb(0x17171A), card: rgb(0xE3202F), cardEdge: rgb(0xB5121F),
                   bubble: rgb(0xFFFFFF), shadow: rgb(0x000000, alpha: 0.5))
// Tinted icons are drawn in greyscale; iOS applies the person's tint colour.
let tinted = Palette(background: rgb(0x000000), card: rgb(0xBDBDBD), cardEdge: rgb(0x8C8C8C),
                     bubble: rgb(0xFFFFFF), shadow: rgb(0x000000, alpha: 0))

try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
try drawIcon(palette: light, to: outputFolder.appendingPathComponent("AppIcon.png"))
try drawIcon(palette: dark, to: outputFolder.appendingPathComponent("AppIcon-Dark.png"))
try drawIcon(palette: tinted, to: outputFolder.appendingPathComponent("AppIcon-Tinted.png"))
print("Wrote icons to \(outputFolder.path)")
