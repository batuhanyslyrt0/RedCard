// Draws Red Card's app icons (light, dark, tinted) as 1024×1024 PNGs.
// Run from the project folder:  swift Tools/MakeAppIcon.swift
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let outputFolder = URL(fileURLWithPath: "RedCard/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

struct Palette {
    var backgroundTop: CGColor
    var backgroundBottom: CGColor
    var cardShine: CGColor
    var cardBase: CGColor
    var shadow: CGColor
    var hasBackground = true
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
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw CocoaError(.featureUnsupported) }

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)

    // Background
    if palette.hasBackground {
        let gradient = CGGradient(colorsSpace: colorSpace,
                                  colors: [palette.backgroundTop, palette.backgroundBottom] as CFArray,
                                  locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: canvas.maxY),
                                   end: CGPoint(x: 0, y: 0), options: [])
    }

    // Card, tilted like a card being held up
    let cardWidth: CGFloat = 470
    let cardHeight: CGFloat = cardWidth / 0.7
    let cardRect = CGRect(x: -cardWidth / 2, y: -cardHeight / 2, width: cardWidth, height: cardHeight)
    let cardPath = CGPath(roundedRect: cardRect, cornerWidth: cardWidth * 0.1,
                          cornerHeight: cardWidth * 0.1, transform: nil)

    context.saveGState()
    context.translateBy(x: CGFloat(size) / 2 + 10, y: CGFloat(size) / 2 - 6)
    context.rotate(by: 10 * .pi / 180) // positive = counter-clockwise in CG, matches -8° in SwiftUI

    // Soft shadow
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -36), blur: 70, color: palette.shadow)
    context.addPath(cardPath)
    context.setFillColor(palette.cardBase)
    context.fillPath()
    context.restoreGState()

    // Card gradient
    context.saveGState()
    context.addPath(cardPath)
    context.clip()
    let cardGradient = CGGradient(colorsSpace: colorSpace,
                                  colors: [palette.cardShine, palette.cardBase] as CFArray,
                                  locations: [0, 1])!
    context.drawLinearGradient(cardGradient, start: CGPoint(x: cardRect.minX, y: cardRect.maxY),
                               end: CGPoint(x: cardRect.maxX, y: cardRect.minY), options: [])

    // Bubble cut-out: clear the pixels so the background shows through
    let bubbleWidth = cardWidth * 0.54
    let bubbleHeight = cardWidth * 0.48
    let bubbleRect = CGRect(x: -bubbleWidth / 2, y: -bubbleHeight / 2,
                            width: bubbleWidth, height: bubbleHeight)
    context.setBlendMode(.clear)
    context.addPath(bubblePath(in: bubbleRect))
    context.fillPath()
    context.setBlendMode(.normal)
    context.restoreGState()
    context.restoreGState()

    // Fill the cut-out with the background again (an icon must be opaque)
    if palette.hasBackground {
        guard let partial = context.makeImage() else { throw CocoaError(.featureUnsupported) }
        context.clear(canvas)
        let gradient = CGGradient(colorsSpace: colorSpace,
                                  colors: [palette.backgroundTop, palette.backgroundBottom] as CFArray,
                                  locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: canvas.maxY),
                                   end: CGPoint(x: 0, y: 0), options: [])
        context.draw(partial, in: canvas)
    }

    // App Store icons must not have an alpha channel, so copy the result
    // into an opaque bitmap before saving.
    guard let drawn = context.makeImage(),
          let opaque = CGContext(
              data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
              space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
          )
    else { throw CocoaError(.fileWriteUnknown) }
    opaque.draw(drawn, in: canvas)

    guard let image = opaque.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw CocoaError(.fileWriteUnknown) }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

let light = Palette(backgroundTop: rgb(0xFBFBFC), backgroundBottom: rgb(0xE6E6EA),
                    cardShine: rgb(0xF2545F), cardBase: rgb(0xD7182A),
                    shadow: rgb(0x8A0E1A, alpha: 0.45))
let dark = Palette(backgroundTop: rgb(0x2A2A2F), backgroundBottom: rgb(0x0E0E10),
                   cardShine: rgb(0xFF7A83), cardBase: rgb(0xFF3D4A),
                   shadow: rgb(0x000000, alpha: 0.6))
// Tinted icons are drawn in greyscale; iOS applies the person's tint colour.
let tinted = Palette(backgroundTop: rgb(0x000000), backgroundBottom: rgb(0x000000),
                     cardShine: rgb(0xFFFFFF), cardBase: rgb(0xB8B8B8),
                     shadow: rgb(0x000000, alpha: 0.0))

try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
try drawIcon(palette: light, to: outputFolder.appendingPathComponent("AppIcon.png"))
try drawIcon(palette: dark, to: outputFolder.appendingPathComponent("AppIcon-Dark.png"))
try drawIcon(palette: tinted, to: outputFolder.appendingPathComponent("AppIcon-Tinted.png"))
print("Wrote icons to \(outputFolder.path)")
