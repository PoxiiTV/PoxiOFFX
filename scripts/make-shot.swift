// Pone una captura del panel (de `PoxiOFFX --snapshot`) con esquinas redondeadas y sombra suave
// sobre una tarjeta de degradado violeta-rosa con esquinas redondeadas, transparente por fuera.
// Uso: swift scripts/make-shot.swift <panel.png> <salida.png>
import AppKit

let args = CommandLine.arguments
guard args.count == 3, let panel = NSImage(contentsOfFile: args[1]),
      let source = panel.representations.first else { print("Uso: make-shot <panel.png> <salida.png>"); exit(1) }

let w = CGFloat(source.pixelsWide), h = CGFloat(source.pixelsHigh)
let pad = w * 0.14
let width = Int(w + 2 * pad), height = Int(h + 2 * pad)
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("sin lienzo") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let card = NSRect(x: 0, y: 0, width: width, height: height)
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255, alpha: 1),
    NSColor(srgbRed: 0xEC / 255, green: 0x48 / 255, blue: 0x99 / 255, alpha: 1),
])!
gradient.draw(in: NSBezierPath(roundedRect: card, xRadius: pad * 0.5, yRadius: pad * 0.5), angle: -35)

let marco = NSRect(x: pad, y: pad, width: w, height: h)
let forma = NSBezierPath(roundedRect: marco, xRadius: 28, yRadius: 28)
NSGraphicsContext.saveGraphicsState()
let sombra = NSShadow()
sombra.shadowColor = NSColor.black.withAlphaComponent(0.45)
sombra.shadowBlurRadius = 40
sombra.shadowOffset = NSSize(width: 0, height: -14)
sombra.set()
NSColor.black.setFill()
forma.fill()
NSGraphicsContext.restoreGraphicsState()
forma.addClip()
panel.draw(in: marco)
NSColor.white.withAlphaComponent(0.12).setStroke()
forma.lineWidth = 2
forma.stroke()
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
