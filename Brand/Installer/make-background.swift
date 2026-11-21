// Draws the installer disk image's window background, as setup's welcome
// dresses Arma: ink under fine lines, Arma's banner over the app, its name
// lettered in Pirata One, and an arrow from the app to Applications. The
// banner and the face come from the app's own resources.
// Usage: swift Brand/Installer/make-background.swift <out-dir>
import AppKit
import CoreText

let outDir = CommandLine.arguments[1]
let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
let bannerPath = root.appendingPathComponent(
    "CrestShared/Resources/AppIconPreviews.xcassets/ArmaMark.imageset/mark.svg").path
let facePath = root.appendingPathComponent("CrestShared/Resources/Fonts/PirataOne-Regular.ttf").path
let size = NSSize(width: 660, height: 420)

func color(_ hex: Int, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
        blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

// Arma's name is lettered in Pirata One; without it, the system's serif.
CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: facePath) as CFURL, .process, nil)
let lettering = NSFont(name: "PirataOne-Regular", size: 72) ?? NSFont.systemFont(ofSize: 72, weight: .bold)
let serif = NSFont(name: "Times New Roman", size: 21) ?? NSFont.systemFont(ofSize: 21)

func render(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    let cg = context.cgContext
    let bounds = NSRect(origin: .zero, size: size)

    // Ink, running down into slate, with dusk and sky glows.
    NSGradient(colors: [color(0x172238), color(0x2B3A5C)])!.draw(in: bounds, angle: -75)
    for (x, y, r, hex) in [
        (110.0, 380.0, 320.0, 0x6B4FA0), (600.0, 40.0, 340.0, 0x5A9BC8),
    ] {
        NSGradient(colors: [color(hex, 0.28), color(hex, 0)])!.draw(
            fromCenter: NSPoint(x: x, y: y), radius: 0, toCenter: NSPoint(x: x, y: y), radius: r, options: [])
    }
    // A mist rising from the bottom, under the icons' names, so Finder's
    // black labels in the light read on the ink as its white ones do in
    // the dark.
    NSGradient(colors: [color(0xFFFDF7, 0.2), color(0xFFFDF7, 0)])!.draw(
        in: NSRect(x: 0, y: 0, width: size.width, height: 170), angle: 90)
    // Fine diagonal lines, as Arma's texture draws them.
    cg.setStrokeColor(color(0xFFFDF7, 0.06).cgColor)
    cg.setLineWidth(1)
    var x = -size.height
    while x < size.width {
        cg.move(to: CGPoint(x: x, y: 0))
        cg.addLine(to: CGPoint(x: x + size.height, y: size.height))
        x += 14
    }
    cg.strokePath()

    // The banner over the app's icon on the left, with a soft shadow.
    if let banner = NSImage(contentsOfFile: bannerPath) {
        let shadow = NSShadow()
        shadow.shadowColor = color(0x000000, 0.45)
        shadow.shadowBlurRadius = 14
        shadow.shadowOffset = NSSize(width: 0, height: -6)
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        banner.draw(in: NSRect(x: 95, y: 252, width: 140, height: 140))
        NSGraphicsContext.restoreGraphicsState()
    }
    // Arma's name and its line, beside the banner.
    let title = NSAttributedString(
        string: "Arma", attributes: [.font: lettering, .foregroundColor: color(0xFFFDF7)])
    title.draw(at: NSPoint(x: 268, y: 318))
    let line = NSAttributedString(
        string: "A browser for cool people.",
        attributes: [.font: serif, .foregroundColor: color(0xFFFDF7, 0.72)])
    line.draw(at: NSPoint(x: 272, y: 288))

    // The arrow from the app (left) to Applications (right).
    let arrowY: CGFloat = 175
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 262, y: arrowY))
    path.curve(
        to: NSPoint(x: 392, y: arrowY), controlPoint1: NSPoint(x: 300, y: arrowY + 26),
        controlPoint2: NSPoint(x: 354, y: arrowY + 26))
    path.lineWidth = 4
    path.lineCapStyle = .round
    color(0xF2C14E, 0.9).setStroke()
    path.stroke()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 380, y: arrowY + 13))
    head.line(to: NSPoint(x: 394, y: arrowY))
    head.line(to: NSPoint(x: 377, y: arrowY - 6))
    head.lineWidth = 4
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.stroke()

    let hint = NSAttributedString(
        string: "Drag Arma to Applications",
        attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: color(0xFFFDF7, 0.7)])
    // Under the arrow, between the two icons, where every Finder shows it.
    hint.draw(at: NSPoint(x: (size.width - hint.size().width) / 2, y: arrowY - 34))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for (scale, name) in [(1.0, "background.png"), (2.0, "background@2x.png")] {
    let data = render(scale: scale).representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}
print("Wrote background.png and background@2x.png to \(outDir)")
