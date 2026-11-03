// Genera el banner del README de PoxiOFFX (2560x760) con el estilo de la familia Poxi:
// fondo con cuadrícula, panel con sombra pixel, logo + título, etiquetas y dos capturas con un sello.
// Uso: make-banner <icono.png> <captura1.png> <captura2.png> <salida.png>
import SwiftUI
import AppKit

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

let coral = Color(hex: 0xFF7A59)
let edge = Color(hex: 0x2A3446)
let panel = Color(hex: 0x111827)
let hardShadow = Color(hex: 0x04070D)

struct Grid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            stride(from: 0, through: size.width, by: 40).forEach { path.addRect(CGRect(x: $0, y: 0, width: 1, height: size.height)) }
            stride(from: 0, through: size.height, by: 40).forEach { path.addRect(CGRect(x: 0, y: $0, width: size.width, height: 1)) }
            context.fill(path, with: .color(.white.opacity(0.035)))
        }
    }
}

struct PixelBox<Content: View>: View {
    var shadow: CGFloat = 8
    var fill = panel
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(fill)
            .overlay(Rectangle().strokeBorder(edge, lineWidth: 3))
            .background(hardShadow.offset(x: shadow, y: shadow))
    }
}

struct Chip: View {
    let text: String
    let color: Color

    var body: some View {
        PixelBox(shadow: 5, fill: Color(hex: 0x0D1320)) {
            HStack(spacing: 14) {
                Rectangle().fill(color).frame(width: 13, height: 13)
                Text(text)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(Color(hex: 0xEEF2FB))
            }
            .padding(.horizontal, 20)
            .frame(height: 50)
        }
    }
}

struct Shot: View {
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 390)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
    }
}

struct Banner: View {
    let icon: NSImage
    let shots: [NSImage]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0x0A111F)
            Grid()
            RadialGradient(colors: [coral.opacity(0.09), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 700)

            PixelBox {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 26) {
                        Image(nsImage: icon).resizable().interpolation(.none).frame(width: 150, height: 150)
                            .padding(-20)
                        Text("\(Text("Poxi").foregroundColor(Color(hex: 0xF4F6FB)))\(Text("OFFX").foregroundColor(coral))")
                            .font(.system(size: 112, weight: .black, design: .rounded))
                            .shadow(color: hardShadow, radius: 0, x: 6, y: 6)
                    }
                    Text("Cierra la tapa del Mac con una pantalla externa")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x9AA6BD))
                        .padding(.top, 26)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 20) {
                            Chip(text: "AUTOMÁTICO", color: coral)
                            Chip(text: "TAMBIÉN CON BATERÍA", color: Color(hex: 0x60A5FA))
                        }
                        HStack(spacing: 20) {
                            Chip(text: "EN CASTELLANO", color: Color(hex: 0x34D399))
                            Chip(text: "BARRA DE MENÚS", color: Color(hex: 0xF472B6))
                            Chip(text: "OPEN SOURCE", color: Color(hex: 0xA78BFA))
                        }
                    }
                    .padding(.top, 44)
                }
                .padding(.horizontal, 54)
                .padding(.vertical, 50)
                .frame(width: 1080, alignment: .leading)
            }
            .offset(x: 82, y: 82)

            PixelBox(shadow: 10, fill: Color(hex: 0x0A0E1C)) {
                HStack(alignment: .top, spacing: 48) {
                    ForEach(Array(shots.enumerated()), id: \.offset) { Shot(image: $0.element) }
                }
                .padding(.top, 38)
                .frame(width: 1140, height: 620, alignment: .top)
                .clipped()
            }
            .offset(x: 1316, y: 60)

            PixelBox(shadow: 7, fill: coral) {
                Text("TAPA CERRADA, MAC DESPIERTO")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0x0A111F))
                    .padding(.horizontal, 30)
                    .frame(height: 78)
            }
            .offset(x: 1820, y: 640)
        }
        .frame(width: 2560, height: 760)
        .clipped()
    }
}

@main
enum Main {
    @MainActor static func main() {
        _ = NSApplication.shared
        let args = CommandLine.arguments
        guard args.count == 5, let icon = NSImage(contentsOfFile: args[1]),
              let a = NSImage(contentsOfFile: args[2]), let b = NSImage(contentsOfFile: args[3]) else {
            print("Uso: make-banner <icono.png> <captura1.png> <captura2.png> <salida.png>"); exit(1)
        }
        let renderer = ImageRenderer(content: Banner(icon: icon, shots: [a, b]))
        renderer.scale = 1
        guard let tiff = renderer.nsImage?.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
            print("No se pudo renderizar"); exit(1)
        }
        try! png.write(to: URL(fileURLWithPath: args[4]))
        print("Banner: \(args[4])")
    }
}
