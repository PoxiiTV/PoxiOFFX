import SwiftUI
import AppKit
import Combine

// PoxiOFFX: con una pantalla externa conectada, el Mac no se duerme al cerrar la tapa.
//
//   PoxiOFFX                    vive en la barra de menús
//   PoxiOFFX --snapshot <dir>   capturas con datos de ejemplo
//   PoxiOFFX --estado           imprime lo que ve (pantallas, tapa, bloqueo, permiso) y sale

let argumentos = CommandLine.arguments

func valor(de opcion: String) -> String? {
    guard let i = argumentos.firstIndex(of: opcion), i + 1 < argumentos.count else { return nil }
    return argumentos[i + 1]
}

@MainActor
final class Delegado: NSObject, NSApplicationDelegate {
    let vigilante = Vigilante()
    private var item: NSStatusItem?
    private let popover = NSPopover()
    private var suscripcion: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.target = self
        item.button?.action = #selector(alternar)
        self.item = item

        let host = NSHostingController(rootView: Panel(vigilante: vigilante))
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)

        suscripcion = vigilante.$situacion.sink { [weak self] s in self?.ponerIcono(s) }
        vigilante.empezar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        vigilante.restaurarAlSalir()
    }

    @objc private func alternar() {
        guard let boton = item?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            vigilante.revisar()
            popover.show(relativeTo: boton.bounds, of: boton, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func ponerIcono(_ s: Vigilante.Situacion) {
        let nombre = switch s {
        case .protegido: "display"
        case .normal: "laptopcomputer"
        case .esperando: "hourglass"
        case .apagado: "pause.circle"
        case .sinPermiso, .error: "exclamationmark.triangle"
        }
        let imagen = NSImage(systemSymbolName: nombre, accessibilityDescription: "PoxiOFFX")
        imagen?.isTemplate = true
        item?.button?.image = imagen
        item?.button?.toolTip = s == .protegido ? "PoxiOFFX · puedes cerrar la tapa" : "PoxiOFFX"
    }
}

// MARK: - Capturas

@MainActor
func capturar(_ vista: some View, en url: URL) throws {
    let host = NSHostingView(rootView: vista.environment(\.colorScheme, .dark))
    host.frame.size = host.fittingSize
    let ventana = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
    ventana.appearance = NSAppearance(named: .darkAqua)
    ventana.contentView = host
    host.layoutSubtreeIfNeeded()
    // A 2x para que se vea nítido en el README.
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(host.bounds.width * 2), pixelsHigh: Int(host.bounds.height * 2),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0) else { return }
    rep.size = host.bounds.size
    host.cacheDisplay(in: host.bounds, to: rep)
    try rep.representation(using: .png, properties: [:])?.write(to: url)
}

// MARK: - Arranque

if let ruta = valor(de: "--snapshot") {
    let dir = URL(fileURLWithPath: ruta)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    _ = NSApplication.shared
    try MainActor.assumeIsolated {
        let ejemplos: [(String, Vigilante)] = [
            ("protegido", Vigilante(ejemplo: ["DELL U2723QE"], bloqueado: true, situacion: .protegido)),
            ("dos-pantallas", Vigilante(ejemplo: ["DELL U2723QE", "LG UltraFine"], bloqueado: true, situacion: .protegido)),
            ("normal", Vigilante(ejemplo: [], bloqueado: false, situacion: .normal)),
            ("permiso", Vigilante(ejemplo: ["DELL U2723QE"], bloqueado: false, permiso: false, situacion: .sinPermiso)),
        ]
        for (nombre, v) in ejemplos {
            try capturar(Panel(vigilante: v), en: dir.appendingPathComponent("\(nombre).png"))
        }
    }
    exit(0)
}

if argumentos.contains("--estado") {
    print("""
    pantallas externas: \(Energia.pantallasExternas())
    tapa cerrada: \(Energia.tapaCerrada())
    suspensión bloqueada: \(Energia.suspensionBloqueada())
    permiso instalado: \(Energia.permisoInstalado())
    """)
    exit(0)
}

let app = NSApplication.shared
let delegado = MainActor.assumeIsolated { Delegado() }
app.delegate = delegado
app.setActivationPolicy(.accessory)
app.run()
