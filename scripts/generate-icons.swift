#!/usr/bin/env swift

import AppKit
import Foundation

let outputDir = "ThePort/Resources/Assets.xcassets/AppIcon.appiconset"

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func generateIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    let s = CGFloat(size)

    // Background - dark rounded rect
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.setFillColor(CGColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0))
    ctx.addPath(bgPath)
    ctx.fillPath()

    // Inner background - slightly lighter
    let inset = s * 0.05
    let innerRect = bgRect.insetBy(dx: inset, dy: inset)
    let innerPath = CGPath(roundedRect: innerRect, cornerWidth: cornerRadius * 0.85, cornerHeight: cornerRadius * 0.85, transform: nil)
    ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0))
    ctx.addPath(innerPath)
    ctx.fillPath()

    // Main accent color - teal/cyan
    let accentR: CGFloat = 0.0
    let accentG: CGFloat = 0.698
    let accentB: CGFloat = 0.835

    // Secondary accent - purple
    let accent2R: CGFloat = 0.608
    let accent2G: CGFloat = 0.349
    let accent2B: CGFloat = 0.714

    // Center point
    let centerX = s * 0.5
    let centerY = s * 0.5

    // Draw network nodes in a circular pattern
    let nodeRadius = s * 0.08
    let orbitRadius = s * 0.28
    let nodeCount = 6

    // Draw connection lines first (behind nodes)
    ctx.setStrokeColor(CGColor(red: accentR, green: accentG, blue: accentB, alpha: 0.3))
    ctx.setLineWidth(s * 0.015)

    for i in 0..<nodeCount {
        let angle1 = (CGFloat(i) / CGFloat(nodeCount)) * 2 * .pi - .pi / 2
        let x1 = centerX + cos(angle1) * orbitRadius
        let y1 = centerY + sin(angle1) * orbitRadius

        // Connect to center
        ctx.move(to: CGPoint(x: centerX, y: centerY))
        ctx.addLine(to: CGPoint(x: x1, y: y1))
        ctx.strokePath()

        // Connect to adjacent nodes
        let angle2 = (CGFloat((i + 1) % nodeCount) / CGFloat(nodeCount)) * 2 * .pi - .pi / 2
        let x2 = centerX + cos(angle2) * orbitRadius
        let y2 = centerY + sin(angle2) * orbitRadius

        ctx.move(to: CGPoint(x: x1, y: y1))
        ctx.addLine(to: CGPoint(x: x2, y: y2))
        ctx.strokePath()
    }

    // Draw outer ring
    ctx.setStrokeColor(CGColor(red: accentR, green: accentG, blue: accentB, alpha: 0.2))
    ctx.setLineWidth(s * 0.02)
    ctx.addEllipse(in: CGRect(x: centerX - orbitRadius, y: centerY - orbitRadius, width: orbitRadius * 2, height: orbitRadius * 2))
    ctx.strokePath()

    // Draw center node (larger, main hub)
    let centerNodeRadius = s * 0.12

    // Glow effect
    let glowRect = CGRect(x: centerX - centerNodeRadius * 1.5, y: centerY - centerNodeRadius * 1.5, width: centerNodeRadius * 3, height: centerNodeRadius * 3)
    ctx.setFillColor(CGColor(red: accentR, green: accentG, blue: accentB, alpha: 0.15))
    ctx.fillEllipse(in: glowRect)

    // Center node
    let centerNodeRect = CGRect(x: centerX - centerNodeRadius, y: centerY - centerNodeRadius, width: centerNodeRadius * 2, height: centerNodeRadius * 2)
    ctx.setFillColor(CGColor(red: accentR, green: accentG, blue: accentB, alpha: 1.0))
    ctx.fillEllipse(in: centerNodeRect)

    // Inner highlight on center node
    let highlightRadius = centerNodeRadius * 0.5
    let highlightRect = CGRect(x: centerX - highlightRadius, y: centerY - highlightRadius, width: highlightRadius * 2, height: highlightRadius * 2)
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3))
    ctx.fillEllipse(in: highlightRect)

    // Draw outer nodes
    for i in 0..<nodeCount {
        let angle = (CGFloat(i) / CGFloat(nodeCount)) * 2 * .pi - .pi / 2
        let x = centerX + cos(angle) * orbitRadius
        let y = centerY + sin(angle) * orbitRadius

        // Alternate colors
        let isAccent = i % 2 == 0
        let r = isAccent ? accentR : accent2R
        let g = isAccent ? accentG : accent2G
        let b = isAccent ? accentB : accent2B

        // Node glow
        let glowRect = CGRect(x: x - nodeRadius * 1.3, y: y - nodeRadius * 1.3, width: nodeRadius * 2.6, height: nodeRadius * 2.6)
        ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 0.2))
        ctx.fillEllipse(in: glowRect)

        // Node
        let nodeRect = CGRect(x: x - nodeRadius, y: y - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2)
        ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1.0))
        ctx.fillEllipse(in: nodeRect)

        // Highlight
        let smallHighlight = nodeRadius * 0.4
        let hRect = CGRect(x: x - smallHighlight, y: y - smallHighlight, width: smallHighlight * 2, height: smallHighlight * 2)
        ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25))
        ctx.fillEllipse(in: hRect)
    }

    // Data flow indicators (small dots on lines)
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6))
    for i in 0..<nodeCount {
        let angle = (CGFloat(i) / CGFloat(nodeCount)) * 2 * .pi - .pi / 2
        let dotDist = orbitRadius * 0.5
        let x = centerX + cos(angle) * dotDist
        let y = centerY + sin(angle) * dotDist
        let dotSize = s * 0.02
        ctx.fillEllipse(in: CGRect(x: x - dotSize, y: y - dotSize, width: dotSize * 2, height: dotSize * 2))
    }

    image.unlockFocus()
    return image
}

// Ensure output directory exists
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for (filename, size) in sizes {
    let image = generateIcon(size: size)
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    let pngData = rep.representation(using: .png, properties: [:])!
    let path = "\(outputDir)/\(filename)"
    try! pngData.write(to: URL(fileURLWithPath: path))
    print("Generated \(filename) (\(size)x\(size))")
}

// Generate Contents.json
let contentsJson = """
{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""

try! contentsJson.write(toFile: "\(outputDir)/Contents.json", atomically: true, encoding: .utf8)
print("Generated Contents.json")

print("All icons generated successfully!")
