import AppKit

let base = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let names = ["."]
let colors: [(CGFloat, CGFloat, CGFloat)] = [(0.25, 0.25, 0.29)]
func stroke(_ points: [CGPoint], width: CGFloat = 30) {
    let path = NSBezierPath()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: points[0])
    for point in points.dropFirst() { path.line(to: point) }
    path.stroke()
}
for (index, name) in names.enumerated() {
    let folder = base.appendingPathComponent(name).appendingPathComponent(
        "Resources/Assets.xcassets")
    try FileManager.default.createDirectory(
        at: folder.appendingPathComponent("AppIcon.appiconset"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
        at: folder.appendingPathComponent("AccentColor.colorset"), withIntermediateDirectories: true
    )
    let (r, g, b) = colors[index]
    let info: [String: Any] = ["info": ["author": "xcode", "version": 1]]
    try JSONSerialization.data(withJSONObject: info, options: .prettyPrinted).write(
        to: folder.appendingPathComponent("Contents.json"))
    let accent: [String: Any] = [
        "info": ["author": "xcode", "version": 1],
        "colors": [
            [
                "idiom": "universal",
                "color": [
                    "color-space": "srgb",
                    "components": [
                        "red": String(Double(r)), "green": String(Double(g)),
                        "blue": String(Double(b)), "alpha": "1.0",
                    ],
                ],
            ]
        ],
    ]
    try JSONSerialization.data(withJSONObject: accent, options: .prettyPrinted).write(
        to: folder.appendingPathComponent("AccentColor.colorset/Contents.json"))
    func render(_ pixels: Int, filename: String) throws {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        NSColor(calibratedRed: r, green: g, blue: b, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
        NSColor(calibratedWhite: 0.96, alpha: 1).setStroke()
        NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
        switch 3 {
        case 0:
            for (x, h) in [(300, 180), (450, 320), (600, 460)] {
                NSBezierPath(
                    roundedRect: NSRect(x: x, y: 280, width: 100, height: h), xRadius: 24,
                    yRadius: 24
                ).fill()
            }
            stroke([CGPoint(x: 280, y: 210), CGPoint(x: 745, y: 210)], width: 18)
        case 1:
            let p = NSBezierPath(
                roundedRect: NSRect(x: 290, y: 235, width: 420, height: 560), xRadius: 30,
                yRadius: 30)
            p.lineWidth = 28
            p.stroke()
            stroke([CGPoint(x: 380, y: 650), CGPoint(x: 620, y: 650)], width: 24)
            stroke([CGPoint(x: 380, y: 540), CGPoint(x: 570, y: 540)], width: 24)
            stroke([CGPoint(x: 380, y: 430), CGPoint(x: 520, y: 430)], width: 24)
            NSColor(calibratedRed: 0.84, green: 0.65, blue: 0.35, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x: 610, y: 190, width: 170, height: 170)).fill()
        case 2:
            let p = NSBezierPath(
                roundedRect: NSRect(x: 295, y: 220, width: 430, height: 560), xRadius: 30,
                yRadius: 30)
            p.lineWidth = 28
            p.stroke()
            NSBezierPath(
                roundedRect: NSRect(x: 415, y: 735, width: 190, height: 90), xRadius: 22,
                yRadius: 22
            ).fill()
            stroke(
                [CGPoint(x: 385, y: 465), CGPoint(x: 475, y: 365), CGPoint(x: 650, y: 590)],
                width: 42)
        case 3:
            let p = NSBezierPath(
                roundedRect: NSRect(x: 225, y: 300, width: 575, height: 430), xRadius: 40,
                yRadius: 40)
            p.lineWidth = 28
            p.stroke()
            stroke([CGPoint(x: 410, y: 215), CGPoint(x: 610, y: 215)], width: 26)
            NSColor(calibratedRed: 0.94, green: 0.39, blue: 0.30, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x: 400, y: 400, width: 225, height: 225)).fill()
        case 4:
            stroke(
                [
                    CGPoint(x: 310, y: 235), CGPoint(x: 310, y: 795), CGPoint(x: 710, y: 795),
                    CGPoint(x: 710, y: 235), CGPoint(x: 650, y: 285), CGPoint(x: 580, y: 235),
                    CGPoint(x: 510, y: 285), CGPoint(x: 440, y: 235), CGPoint(x: 370, y: 285),
                    CGPoint(x: 310, y: 235),
                ], width: 28)
            for y in [665, 550, 435] {
                stroke([CGPoint(x: 395, y: y), CGPoint(x: 540, y: y)], width: 24)
                stroke([CGPoint(x: 615, y: y), CGPoint(x: 630, y: y)], width: 24)
            }
        default:
            let p = NSBezierPath(
                roundedRect: NSRect(x: 230, y: 285, width: 560, height: 460), xRadius: 45,
                yRadius: 45)
            p.lineWidth = 28
            p.stroke()
            stroke([CGPoint(x: 510, y: 305), CGPoint(x: 510, y: 725)], width: 20)
            stroke(
                [CGPoint(x: 430, y: 615), CGPoint(x: 330, y: 515), CGPoint(x: 430, y: 415)],
                width: 32)
            stroke(
                [CGPoint(x: 595, y: 615), CGPoint(x: 695, y: 515), CGPoint(x: 595, y: 415)],
                width: 32)
        }
        NSGraphicsContext.restoreGraphicsState()
        try rep.representation(using: .png, properties: [:])!.write(
            to: folder.appendingPathComponent("AppIcon.appiconset/" + filename))
    }
    var images: [[String: String]] = []
    if 3 != 3 {
        // Explicit slots retain compatibility with deployment targets below iOS 18.
        for (idiom, sizes) in [
            ("iphone", [20.0, 29, 40, 60]), ("ipad", [20.0, 29, 40, 76, 83.5]),
        ] {
            for size in sizes {
                for scale in (idiom == "iphone" ? [2, 3] : (size == 83.5 ? [2] : [1, 2])) {
                    let filename = "\(idiom)-\(size)-\(scale).png"
                    try render(Int(size * Double(scale)), filename: filename)
                    images.append([
                        "idiom": idiom, "size": "\(size)x\(size)", "scale": "\(scale)x",
                        "filename": filename,
                    ])
                }
            }
        }
        try render(1024, filename: "marketing.png")
        images.append([
            "idiom": "ios-marketing", "size": "1024x1024", "scale": "1x",
            "filename": "marketing.png",
        ])
    }
    if 3 == 1 || 3 == 3 {
        for size in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let filename = "mac-\(size)-\(scale).png"
                try render(size * scale, filename: filename)
                images.append([
                    "idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x",
                    "filename": filename,
                ])
            }
        }
    }
    try JSONSerialization.data(
        withJSONObject: ["info": ["author": "xcode", "version": 1], "images": images],
        options: [.prettyPrinted, .sortedKeys]
    ).write(to: folder.appendingPathComponent("AppIcon.appiconset/Contents.json"))
    print("Rendered \(name)")
}
