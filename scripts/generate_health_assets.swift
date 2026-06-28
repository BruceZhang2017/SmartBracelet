import AppKit
import Foundation

struct Palette {
    static let bgTop = NSColor(calibratedRed: 0.96, green: 0.95, blue: 1.00, alpha: 1.0)
    static let bgBottom = NSColor(calibratedRed: 1.00, green: 0.95, blue: 0.92, alpha: 1.0)
    static let coral = NSColor(calibratedRed: 1.00, green: 0.39, blue: 0.34, alpha: 1.0)
    static let orange = NSColor(calibratedRed: 1.00, green: 0.74, blue: 0.26, alpha: 1.0)
    static let purple = NSColor(calibratedRed: 0.52, green: 0.42, blue: 1.00, alpha: 1.0)
    static let cyan = NSColor(calibratedRed: 0.15, green: 0.79, blue: 0.78, alpha: 1.0)
    static let whiteStrong = NSColor(calibratedWhite: 1.0, alpha: 0.96)
}

func makeGradient(_ colors: [NSColor], angle: CGFloat = 0, in rect: CGRect) {
    let gradient = NSGradient(colors: colors)!
    gradient.draw(in: NSBezierPath(roundedRect: rect, xRadius: 36, yRadius: 36), angle: angle)
}

func drawBlob(_ rect: CGRect, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: rect).fill()
}

func drawRoundedCard(_ rect: CGRect, fill: NSColor, stroke: NSColor? = nil, radius: CGFloat = 28, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawShadowedCard(_ rect: CGRect, fill: NSColor, radius: CGFloat = 28, shadow: NSColor = NSColor.black.withAlphaComponent(0.08)) {
    let shadowObj = NSShadow()
    shadowObj.shadowBlurRadius = 24
    shadowObj.shadowOffset = NSSize(width: 0, height: -8)
    shadowObj.shadowColor = shadow
    NSGraphicsContext.saveGraphicsState()
    shadowObj.set()
    drawRoundedCard(rect, fill: fill, radius: radius)
    NSGraphicsContext.restoreGraphicsState()
}

func savePNG(size: CGSize, path: String, drawing: () -> Void) throws {
    let image = NSImage(size: size)
    image.lockFocusFlipped(false)
    drawing()
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "health.assets", code: 1)
    }

    try FileManager.default.createDirectory(at: URL(fileURLWithPath: path).deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: URL(fileURLWithPath: path))
}

func drawRing(center: CGPoint, radius: CGFloat, lineWidth: CGFloat, color: NSColor, start: CGFloat = 0, end: CGFloat = 360) {
    let path = NSBezierPath()
    path.appendArc(withCenter: center, radius: radius, startAngle: start, endAngle: end)
    path.lineWidth = lineWidth
    color.setStroke()
    path.stroke()
}

func drawWatch(center: CGPoint, scale: CGFloat = 1, accent: NSColor = Palette.coral, secondary: NSColor = Palette.purple) {
    let strapW: CGFloat = 82 * scale
    let bodyW: CGFloat = 142 * scale
    let bodyH: CGFloat = 168 * scale

    drawRoundedCard(CGRect(x: center.x - strapW / 2, y: center.y - bodyH / 2 - 64 * scale, width: strapW, height: 64 * scale), fill: NSColor.white.withAlphaComponent(0.82), radius: 28 * scale)
    drawRoundedCard(CGRect(x: center.x - strapW / 2, y: center.y + bodyH / 2, width: strapW, height: 64 * scale), fill: NSColor.white.withAlphaComponent(0.82), radius: 28 * scale)
    drawShadowedCard(CGRect(x: center.x - bodyW / 2, y: center.y - bodyH / 2, width: bodyW, height: bodyH), fill: NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.22, alpha: 1.0), radius: 42 * scale, shadow: NSColor.black.withAlphaComponent(0.18))
    drawRoundedCard(CGRect(x: center.x - bodyW / 2 + 12 * scale, y: center.y - bodyH / 2 + 12 * scale, width: bodyW - 24 * scale, height: bodyH - 24 * scale), fill: NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1.0), radius: 34 * scale)

    let screenRect = CGRect(x: center.x - bodyW / 2 + 22 * scale, y: center.y - bodyH / 2 + 22 * scale, width: bodyW - 44 * scale, height: bodyH - 44 * scale)
    makeGradient([accent.withAlphaComponent(0.92), secondary.withAlphaComponent(0.88)], angle: -45, in: screenRect)

    drawRing(center: CGPoint(x: center.x, y: center.y + 18 * scale), radius: 22 * scale, lineWidth: 7 * scale, color: NSColor.white.withAlphaComponent(0.88), start: 24, end: 318)
    drawRing(center: CGPoint(x: center.x, y: center.y + 18 * scale), radius: 34 * scale, lineWidth: 5 * scale, color: NSColor.white.withAlphaComponent(0.42), start: 90, end: 330)

    let heart = NSBezierPath()
    heart.move(to: CGPoint(x: center.x, y: center.y - 8 * scale))
    heart.curve(to: CGPoint(x: center.x - 22 * scale, y: center.y + 16 * scale), controlPoint1: CGPoint(x: center.x - 2 * scale, y: center.y + 10 * scale), controlPoint2: CGPoint(x: center.x - 18 * scale, y: center.y + 28 * scale))
    heart.curve(to: CGPoint(x: center.x, y: center.y + 42 * scale), controlPoint1: CGPoint(x: center.x - 26 * scale, y: center.y + 4 * scale), controlPoint2: CGPoint(x: center.x - 12 * scale, y: center.y + 40 * scale))
    heart.curve(to: CGPoint(x: center.x + 22 * scale, y: center.y + 16 * scale), controlPoint1: CGPoint(x: center.x + 12 * scale, y: center.y + 40 * scale), controlPoint2: CGPoint(x: center.x + 26 * scale, y: center.y + 4 * scale))
    heart.curve(to: CGPoint(x: center.x, y: center.y - 8 * scale), controlPoint1: CGPoint(x: center.x + 18 * scale, y: center.y + 28 * scale), controlPoint2: CGPoint(x: center.x + 2 * scale, y: center.y + 10 * scale))
    NSColor.white.withAlphaComponent(0.96).setFill()
    heart.fill()

    drawRoundedCard(CGRect(x: center.x - 38 * scale, y: center.y - 44 * scale, width: 76 * scale, height: 12 * scale), fill: NSColor.white.withAlphaComponent(0.24), radius: 6 * scale)
}

func drawDeviceEmpty(size: CGSize, path: String) throws {
    try savePNG(size: size, path: path) {
        makeGradient([Palette.bgTop, Palette.bgBottom], angle: -35, in: CGRect(origin: .zero, size: size))
        drawBlob(CGRect(x: size.width - 260, y: size.height - 210, width: 210, height: 210), color: Palette.orange.withAlphaComponent(0.18))
        drawBlob(CGRect(x: 50, y: 80, width: 180, height: 180), color: Palette.purple.withAlphaComponent(0.14))
        drawWatch(center: CGPoint(x: size.width * 0.50, y: size.height * 0.47), scale: 1.05, accent: Palette.coral, secondary: Palette.orange)
        drawShadowedCard(CGRect(x: size.width * 0.62, y: size.height * 0.56, width: 150, height: 96), fill: Palette.whiteStrong, radius: 26)
        drawRoundedCard(CGRect(x: size.width * 0.62 + 22, y: size.height * 0.56 + 60, width: 106, height: 14), fill: Palette.orange.withAlphaComponent(0.18), radius: 7)
        drawRoundedCard(CGRect(x: size.width * 0.62 + 22, y: size.height * 0.56 + 36, width: 70, height: 10), fill: Palette.purple.withAlphaComponent(0.14), radius: 5)
        let plus = NSBezierPath()
        let center = CGPoint(x: size.width * 0.62 + 118, y: size.height * 0.56 + 32)
        plus.lineWidth = 8
        plus.move(to: CGPoint(x: center.x - 14, y: center.y))
        plus.line(to: CGPoint(x: center.x + 14, y: center.y))
        plus.move(to: CGPoint(x: center.x, y: center.y - 14))
        plus.line(to: CGPoint(x: center.x, y: center.y + 14))
        Palette.coral.setStroke()
        plus.stroke()
    }
}

func drawDisconnected(size: CGSize, path: String) throws {
    try savePNG(size: size, path: path) {
        makeGradient([Palette.bgTop, NSColor(calibratedRed: 0.93, green: 0.98, blue: 1.0, alpha: 1.0)], angle: -30, in: CGRect(origin: .zero, size: size))
        drawBlob(CGRect(x: size.width - 250, y: size.height - 220, width: 220, height: 220), color: Palette.cyan.withAlphaComponent(0.16))
        drawBlob(CGRect(x: 70, y: 80, width: 170, height: 170), color: Palette.coral.withAlphaComponent(0.10))
        drawWatch(center: CGPoint(x: size.width * 0.40, y: size.height * 0.48), scale: 0.98, accent: Palette.cyan, secondary: Palette.purple)
        drawRing(center: CGPoint(x: size.width * 0.64, y: size.height * 0.56), radius: 44, lineWidth: 8, color: Palette.cyan.withAlphaComponent(0.36), start: 28, end: 136)
        drawRing(center: CGPoint(x: size.width * 0.64, y: size.height * 0.56), radius: 68, lineWidth: 8, color: Palette.cyan.withAlphaComponent(0.24), start: 24, end: 150)
        let slash = NSBezierPath()
        slash.lineWidth = 10
        slash.move(to: CGPoint(x: size.width * 0.59, y: size.height * 0.46))
        slash.line(to: CGPoint(x: size.width * 0.70, y: size.height * 0.63))
        Palette.coral.setStroke()
        slash.stroke()
        drawShadowedCard(CGRect(x: size.width * 0.54, y: size.height * 0.25, width: 200, height: 88), fill: Palette.whiteStrong, radius: 26)
        drawRoundedCard(CGRect(x: size.width * 0.54 + 22, y: size.height * 0.25 + 48, width: 126, height: 12), fill: Palette.cyan.withAlphaComponent(0.16), radius: 6)
        drawRoundedCard(CGRect(x: size.width * 0.54 + 22, y: size.height * 0.25 + 24, width: 84, height: 10), fill: Palette.coral.withAlphaComponent(0.14), radius: 5)
    }
}

func drawMetrics(size: CGSize, path: String) throws {
    try savePNG(size: size, path: path) {
        makeGradient([Palette.bgTop, NSColor(calibratedRed: 0.98, green: 0.96, blue: 1.00, alpha: 1.0)], angle: -28, in: CGRect(origin: .zero, size: size))
        drawBlob(CGRect(x: size.width - 280, y: size.height - 240, width: 240, height: 240), color: Palette.purple.withAlphaComponent(0.15))
        drawBlob(CGRect(x: 40, y: 100, width: 200, height: 200), color: Palette.orange.withAlphaComponent(0.12))
        drawShadowedCard(CGRect(x: size.width * 0.22, y: size.height * 0.30, width: 420, height: 230), fill: Palette.whiteStrong, radius: 34)
        drawRoundedCard(CGRect(x: size.width * 0.22 + 28, y: size.height * 0.30 + 160, width: 132, height: 16), fill: Palette.purple.withAlphaComponent(0.16), radius: 8)
        drawRoundedCard(CGRect(x: size.width * 0.22 + 28, y: size.height * 0.30 + 132, width: 94, height: 11), fill: Palette.orange.withAlphaComponent(0.14), radius: 5)

        let baseX = size.width * 0.22 + 28
        let barY = size.height * 0.30 + 42
        let barColors = [Palette.cyan, Palette.orange, Palette.coral, Palette.purple]
        let heights: [CGFloat] = [56, 92, 72, 116]
        for i in 0..<4 {
            drawRoundedCard(CGRect(x: baseX + CGFloat(i) * 64, y: barY, width: 34, height: heights[i]), fill: barColors[i].withAlphaComponent(0.90), radius: 12)
        }

        drawRing(center: CGPoint(x: size.width * 0.72, y: size.height * 0.52), radius: 56, lineWidth: 16, color: Palette.coral.withAlphaComponent(0.92), start: 16, end: 220)
        drawRing(center: CGPoint(x: size.width * 0.72, y: size.height * 0.52), radius: 34, lineWidth: 12, color: Palette.cyan.withAlphaComponent(0.82), start: 90, end: 330)

        let heart = NSBezierPath()
        let c = CGPoint(x: size.width * 0.72, y: size.height * 0.52)
        heart.move(to: CGPoint(x: c.x, y: c.y - 12))
        heart.curve(to: CGPoint(x: c.x - 20, y: c.y + 10), controlPoint1: CGPoint(x: c.x - 2, y: c.y + 6), controlPoint2: CGPoint(x: c.x - 16, y: c.y + 20))
        heart.curve(to: CGPoint(x: c.x, y: c.y + 34), controlPoint1: CGPoint(x: c.x - 24, y: c.y - 2), controlPoint2: CGPoint(x: c.x - 10, y: c.y + 32))
        heart.curve(to: CGPoint(x: c.x + 20, y: c.y + 10), controlPoint1: CGPoint(x: c.x + 10, y: c.y + 32), controlPoint2: CGPoint(x: c.x + 24, y: c.y - 2))
        heart.curve(to: CGPoint(x: c.x, y: c.y - 12), controlPoint1: CGPoint(x: c.x + 16, y: c.y + 20), controlPoint2: CGPoint(x: c.x + 2, y: c.y + 6))
        Palette.whiteStrong.setFill()
        heart.fill()
    }
}

func drawHero(size: CGSize, path: String) throws {
    try savePNG(size: size, path: path) {
        let rect = CGRect(origin: .zero, size: size)
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 1.00, green: 0.82, blue: 0.38, alpha: 1.0),
            NSColor(calibratedRed: 1.00, green: 0.47, blue: 0.34, alpha: 1.0),
            NSColor(calibratedRed: 0.98, green: 0.33, blue: 0.45, alpha: 1.0)
        ])!
        gradient.draw(in: NSBezierPath(roundedRect: rect, xRadius: 48, yRadius: 48), angle: -24)

        drawBlob(CGRect(x: size.width - 220, y: size.height - 180, width: 170, height: 170), color: NSColor.white.withAlphaComponent(0.14))
        drawBlob(CGRect(x: -40, y: -30, width: 160, height: 160), color: NSColor.white.withAlphaComponent(0.08))

        drawShadowedCard(CGRect(x: size.width * 0.56, y: size.height * 0.18, width: 180, height: 116), fill: NSColor.white.withAlphaComponent(0.20), radius: 28, shadow: NSColor.clear)
        drawRoundedCard(CGRect(x: size.width * 0.56 + 18, y: size.height * 0.18 + 72, width: 88, height: 12), fill: NSColor.white.withAlphaComponent(0.26), radius: 6)
        drawRoundedCard(CGRect(x: size.width * 0.56 + 18, y: size.height * 0.18 + 48, width: 130, height: 16), fill: NSColor.white.withAlphaComponent(0.34), radius: 8)
        drawRoundedCard(CGRect(x: size.width * 0.18, y: size.height * 0.18, width: 142, height: 120), fill: NSColor.white.withAlphaComponent(0.18), radius: 26)
        drawRing(center: CGPoint(x: size.width * 0.28, y: size.height * 0.36), radius: 28, lineWidth: 10, color: NSColor.white.withAlphaComponent(0.84), start: 18, end: 300)
        drawRoundedCard(CGRect(x: size.width * 0.22, y: size.height * 0.22, width: 80, height: 10), fill: NSColor.white.withAlphaComponent(0.24), radius: 5)
    }
}

func writeContentsJSON(assetDir: String, filename: String) throws {
    let json = """
    {
      "images" : [
        { "idiom" : "universal", "scale" : "1x" },
        { "idiom" : "universal", "scale" : "2x" },
        { "filename" : "\(filename)", "idiom" : "universal", "scale" : "3x" }
      ],
      "info" : { "author" : "xcode", "version" : 1 }
    }
    """
    let url = URL(fileURLWithPath: assetDir).appendingPathComponent("Contents.json")
    try FileManager.default.createDirectory(at: URL(fileURLWithPath: assetDir), withIntermediateDirectories: true)
    try json.data(using: .utf8)?.write(to: url)
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsRoot = repoRoot.appendingPathComponent("SmartBracelet/Assets.xcassets/Health")

let resources: [(name: String, size: CGSize, draw: (CGSize, String) throws -> Void)] = [
    ("health_empty_device", CGSize(width: 900, height: 660), drawDeviceEmpty),
    ("health_empty_disconnected", CGSize(width: 900, height: 660), drawDisconnected),
    ("health_empty_metrics", CGSize(width: 900, height: 660), drawMetrics),
    ("health_dashboard_hero", CGSize(width: 780, height: 420), drawHero)
]

for resource in resources {
    let dir = assetsRoot.appendingPathComponent("\(resource.name).imageset").path
    let filename = "\(resource.name)@3x.png"
    let pngPath = URL(fileURLWithPath: dir).appendingPathComponent(filename).path
    try resource.draw(resource.size, pngPath)
    try writeContentsJSON(assetDir: dir, filename: filename)
    print("generated \(resource.name)")
}
