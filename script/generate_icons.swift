// Builds Akshara's macOS icons from the icon shared with the Android and iOS apps.
//
//     swift script/generate_icons.swift        (or ./script/generate_icons.sh)
//
// support/IconSource/AksharaIcon-1024.png  → support/Resources/AksharaIconMaster.png, Akshara.icns
// support/IconSource/AksharaMonochrome.png → support/Resources/AksharaMenu{,@2x}.tif (template, black)
//                                            support/Resources/AksharaMenuWhite{,@2x}.tif
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let source = root.appendingPathComponent("support/IconSource")
let resources = root.appendingPathComponent("support/Resources")
let work = root.appendingPathComponent("build/icon-generation")

func load(_ name: String) -> NSBitmapImageRep {
    let url = source.appendingPathComponent(name)
    guard let data = try? Data(contentsOf: url), let rep = NSBitmapImageRep(data: data) else {
        fatalError("Missing icon master: \(url.path)")
    }
    return rep
}

/// A transparent bitmap of `size` pixels drawn by `draw`.
func render(_ size: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    draw(context.cgContext)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func write(_ rep: NSBitmapImageRep, _ url: URL, _ type: NSBitmapImageRep.FileType) {
    try! rep.representation(using: type, properties: [:])!.write(to: url)
}

// MARK: - App icon: the shared icon on the macOS grid (an 824 pt tile in 1024, with a soft shadow)

let icon = load("AksharaIcon-1024.png")
let master = render(1024) { cg in
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    cg.addPath(shape)
    cg.setFillColor(NSColor(srgbRed: 0.063, green: 0.063, blue: 0.063, alpha: 1).cgColor)
    cg.fillPath()
    cg.restoreGState()
    // The source has its own rounded corners; the macOS tile's larger radius clips them away.
    cg.addPath(shape)
    cg.clip()
    cg.draw(icon.cgImage!, in: tile)
}
write(master, resources.appendingPathComponent("AksharaIconMaster.png"), .png)

let iconset = work.appendingPathComponent("Akshara.iconset")
try? FileManager.default.removeItem(at: work)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let rep = render(pixels) { cg in cg.draw(master.cgImage!, in: CGRect(x: 0, y: 0, width: pixels, height: pixels)) }
        let name = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
        write(rep, iconset.appendingPathComponent(name), .png)
    }
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("Akshara.icns").path]
try! iconutil.run()
iconutil.waitUntilExit()
precondition(iconutil.terminationStatus == 0, "iconutil failed")

// MARK: - Input menu icons: the one-colour mark, trimmed to its ink and centred (template images)

let monochrome = load("AksharaMonochrome.png")
// The master has faint noise around the glyph; drop pixels under 15% opacity, which would show as specks.
let mark = render(monochrome.pixelsWide) { cg in
    cg.interpolationQuality = .none
    cg.draw(monochrome.cgImage!, in: CGRect(x: 0, y: 0, width: monochrome.pixelsWide, height: monochrome.pixelsHigh))
}
var ink = CGRect.null
for y in 0..<mark.pixelsHigh {
    for x in 0..<mark.pixelsWide {
        let alpha = mark.colorAt(x: x, y: y)?.alphaComponent ?? 0
        if alpha < 0.15 {
            if alpha > 0 { mark.setColor(NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 0), atX: x, y: y) }
            continue
        }
        ink = ink.union(CGRect(x: x, y: mark.pixelsHigh - 1 - y, width: 1, height: 1))
    }
}
let markImage = mark.cgImage!.cropping(to: CGRect(
    x: ink.minX, y: CGFloat(mark.pixelsHigh) - ink.maxY, width: ink.width, height: ink.height))!

func menuIcon(_ pixels: Int, _ color: NSColor) -> NSBitmapImageRep {
    render(pixels) { cg in
        let inset = CGFloat(pixels) / 16                     // 1 pt margin
        let box = CGRect(x: 0, y: 0, width: pixels, height: pixels).insetBy(dx: inset, dy: inset)
        let scale = min(box.width / ink.width, box.height / ink.height)
        let size = CGSize(width: ink.width * scale, height: ink.height * scale)
        let frame = CGRect(x: box.midX - size.width / 2, y: box.midY - size.height / 2, width: size.width, height: size.height)
        cg.clip(to: frame, mask: markImage)
        cg.setFillColor(color.cgColor)
        cg.fill(frame)
    }
}
for (name, color) in [("AksharaMenu", NSColor.black), ("AksharaMenuWhite", NSColor.white)] {
    write(menuIcon(16, color), resources.appendingPathComponent("\(name).tif"), .tiff)
    let retina = menuIcon(32, color)
    retina.size = NSSize(width: 16, height: 16)
    write(retina, resources.appendingPathComponent("\(name)@2x.tif"), .tiff)
}

print("Generated Akshara app and menu icons")
