// Genera el icono de PoxiOFFX con la receta de los logos Poxi:
// baldosa oscura, "P" gruesa de bloques, sombra escalonada en 2 capas
// y un objeto pixel-art abajo a la derecha (aquí, una pantalla externa encendida).
// Uso: swift scripts/make-icon.swift <salida.png>
// Baldosa de 824 con margen de 100 en un lienzo de 1024.
import AppKit

let canvas = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: canvas, pixelsHigh: canvas, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("sin contexto") }

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

// Origen arriba a la izquierda, en un lienzo de trabajo de 512.
let (margin, tile): (CGFloat, CGFloat) = (100, 824)
let transform = NSAffineTransform()
transform.translateX(by: margin, yBy: margin + tile)
transform.scaleX(by: tile / 512.0, yBy: -tile / 512.0)
transform.concat()

// Baldosa
rgb(0x0A111F).setFill()
NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 512, height: 512), xRadius: 92, yRadius: 92).fill()

// La "P": 10 x 12 bloques de 25,6px, origen en el bloque (4, 3).
let unit: CGFloat = 25.6
let originX = 4 * unit, originY = 3 * unit
let rows = [
    "XXXXXXXXXX",
    "XXXXXXXXXX",
    "XXX....XXX",
    "XXX....XXX",
    "XXX....XXX",
    "XXXXXXXXXX",
    "XXXXXXXXXX",
    "XXX.......",
    "XXX.......",
    "XXX.......",
    "XXX.......",
    "XXX.......",
]

/// Cada color de `pattern` como una sola forma, para que no salgan líneas finas entre bloques.
func fill(_ pattern: [String], at x0: CGFloat, _ y0: CGFloat, cell: CGFloat, colors: [Character: UInt32]) {
    for (char, hex) in colors {
        let path = NSBezierPath()
        for (y, row) in pattern.enumerated() {
            for (x, c) in row.enumerated() where c == char || (char == "*" && c != ".") {
                path.appendRect(NSRect(x: x0 + CGFloat(x) * cell, y: y0 + CGFloat(y) * cell, width: cell, height: cell))
            }
        }
        rgb(hex).setFill()
        path.fill()
    }
}

// Coral, con su sombra al ~60 % y al ~35 %.
fill(rows, at: originX + 24, originY + 24, cell: unit, colors: ["X": 0x592B1F])
fill(rows, at: originX + 12, originY + 12, cell: unit, colors: ["X": 0x994935])
fill(rows, at: originX, originY, cell: unit, colors: ["X": 0xFF7A59])

// Pantalla: W marco, S pantalla, h brillo, c botón de encendido coral (sigue despierto), G pie, B base.
let monitor = [
    "WWWWWWWWWW",
    "WSSScSSShW",
    "WScScScShW",
    "WcSScSSchW",
    "WcSSSSSchW",
    "WScccccShW",
    "WWWWWWWWWW",
    "....GG....",
    "..BBBBBB..",
]
let cell: CGFloat = 16, monX: CGFloat = 316, monY: CGFloat = 322
fill(monitor, at: monX + 10, monY + 10, cell: cell, colors: ["*": 0x2A3350])
fill(monitor, at: monX, monY, cell: cell, colors: [
    "W": 0xFFFFFF, "S": 0x24325A, "h": 0x4A64A8, "c": 0xFF7A59, "G": 0x8A9BBE, "B": 0xD4DEF0,
])

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
