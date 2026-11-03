import SwiftUI
import AppKit
import PoxiOFFXCore

// MARK: - Colores Poxi (coral)

enum Tono {
    static let fondo = Color(hex: 0x0A0E1C)
    static let fondo2 = Color(hex: 0x0F1228)
    static let acento = Color(hex: 0xFF7A59)
    static let acentoClaro = Color(hex: 0xFFA38A)
    static let acentoOscuro = Color(hex: 0xE5583A)
    static let sombra1 = Color(hex: 0x994935)
    static let sombra2 = Color(hex: 0x592B1F)
    static let texto = Color.white
    static let secundario = Color(hex: 0x8A9BBE)
    static let tenue = Color(hex: 0x5B6785)
    static let oscuro = Color(hex: 0x0A111F)
    static let verde = Color(hex: 0x34D399)
    static let azul = Color(hex: 0x60A5FA)
    static let naranja = Color(hex: 0xF59E0B)
    static let rojo = Color(hex: 0xF87171)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Panel (lo que se abre desde la barra de menús)

struct Panel: View {
    @ObservedObject var vigilante: Vigilante

    var body: some View {
        VStack(spacing: 0) {
            Cabecera()
            VStack(spacing: 12) {
                Estado(vigilante: vigilante)
                Pantallas(nombres: vigilante.pantallas)
                Ajustes(vigilante: vigilante)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            BarraEstado(vigilante: vigilante)
        }
        .frame(width: 340)
        .background(Fondo())
    }
}

struct Fondo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Tono.fondo2, Tono.fondo], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Tono.acento.opacity(0.22), .clear], center: .topTrailing,
                           startRadius: 0, endRadius: 300)
        }
    }
}

struct Cabecera: View {
    var body: some View {
        HStack(spacing: 8) {
            LetraP(color: Tono.acento).frame(width: 15, height: 15)
            Text("PoxiOFFX")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Tono.texto)
            Text("beta")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Tono.acentoClaro)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Tono.acento.opacity(0.16)))
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
    }
}

/// La P pixel de la familia Poxi, con su sombra escalonada.
struct LetraP: View {
    let color: Color

    nonisolated static let forma = [
        "XXXXXXXXXX", "XXXXXXXXXX", "XXX....XXX", "XXX....XXX", "XXX....XXX", "XXXXXXXXXX",
        "XXXXXXXXXX", "XXX.......", "XXX.......", "XXX.......", "XXX.......", "XXX.......",
    ]

    var body: some View {
        Canvas { ctx, size in
            let bloque = min(size.width / 11, size.height / 13)
            func dibujar(dx: CGFloat, _ c: Color) {
                var camino = Path()
                for (y, fila) in LetraP.forma.enumerated() {
                    for (x, ch) in fila.enumerated() where ch == "X" {
                        camino.addRect(CGRect(x: CGFloat(x) * bloque + dx, y: CGFloat(y) * bloque + dx,
                                              width: bloque + 0.5, height: bloque + 0.5))
                    }
                }
                ctx.fill(camino, with: .color(c))
            }
            dibujar(dx: bloque * 0.9, Tono.sombra2)
            dibujar(dx: bloque * 0.45, Tono.sombra1)
            dibujar(dx: 0, color)
        }
    }
}

// MARK: - Estado grande

struct Estado: View {
    @ObservedObject var vigilante: Vigilante

    var body: some View {
        let s = vigilante.situacion
        Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14).fill(color(s).opacity(0.14))
                        Image(systemName: simbolo(s))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(color(s))
                            .shadow(color: color(s).opacity(0.6), radius: 8)
                    }
                    .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titulo(s))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Tono.texto)
                        Text(detalle(s))
                            .font(.system(size: 11.5))
                            .foregroundStyle(Tono.secundario)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                if s == .sinPermiso {
                    BotonPrincipal(titulo: "Dar permiso (una sola vez)", icono: "key.fill") {
                        vigilante.instalarPermiso()
                    }
                }
            }
        }
    }

    private func simbolo(_ s: Vigilante.Situacion) -> String {
        switch s {
        case .protegido: "sun.max.fill"
        case .normal: "moon.zzz.fill"
        case .esperando: "hourglass"
        case .apagado: "pause.circle.fill"
        case .sinPermiso: "key.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private func color(_ s: Vigilante.Situacion) -> Color {
        switch s {
        case .protegido: Tono.acento
        case .normal: Tono.azul
        case .esperando, .sinPermiso: Tono.naranja
        case .apagado: Tono.secundario
        case .error: Tono.rojo
        }
    }

    private func titulo(_ s: Vigilante.Situacion) -> String {
        switch s {
        case .protegido: "Puedes cerrar la tapa"
        case .normal: "Comportamiento normal"
        case .esperando: "Pantalla desconectada"
        case .apagado: "En pausa"
        case .sinPermiso: "Falta un permiso"
        case .error: "Algo ha fallado"
        }
    }

    private func detalle(_ s: Vigilante.Situacion) -> String {
        switch s {
        case .protegido:
            "El Mac seguirá encendido con la tapa cerrada, también con batería y sin cargador."
        case .normal:
            "No hay pantallas externas: cerrar la tapa suspende el Mac, como siempre."
        case .esperando:
            "Volviendo al comportamiento normal en unos segundos…"
        case .apagado:
            "PoxiOFFX no hace nada: cerrar la tapa suspende el Mac, como siempre."
        case .sinPermiso:
            "Para que el Mac no se duerma al cerrar la tapa, macOS pide tu contraseña una vez."
        case .error(let m):
            m
        }
    }
}

// MARK: - Pantallas

struct Pantallas: View {
    let nombres: [String]

    var body: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Etiqueta(texto: "PANTALLAS EXTERNAS")
                    Spacer()
                    Text("\(nombres.count)")
                        .font(.system(size: 11, weight: .bold)).monospacedDigit()
                        .foregroundStyle(nombres.isEmpty ? Tono.tenue : Tono.acentoClaro)
                }
                if nombres.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "display").font(.system(size: 20)).foregroundStyle(Tono.tenue)
                        Text("Conecta una pantalla externa")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(Tono.secundario)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                } else {
                    ForEach(Array(nombres.enumerated()), id: \.offset) { _, nombre in
                        HStack(spacing: 10) {
                            Image(systemName: "display")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Tono.acento)
                                .frame(width: 18)
                            Text(nombre)
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(Tono.texto)
                                .lineLimit(1).truncationMode(.tail)
                            Spacer()
                            Text("conectada")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Tono.verde)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Capsule().fill(Tono.verde.opacity(0.14)))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Ajustes

struct Ajustes: View {
    @ObservedObject var vigilante: Vigilante

    var body: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 12) {
                Etiqueta(texto: "AJUSTES")
                Fila(titulo: "Activar con pantalla externa", detalle: "Lo hace solo al conectar o desconectar") {
                    Toggle("", isOn: $vigilante.activado).labelsHidden()
                }
                Fila(titulo: "Abrir al iniciar sesión", detalle: "Siempre listo en la barra de menús") {
                    Toggle("", isOn: $vigilante.alIniciar).labelsHidden()
                }
                if vigilante.permiso {
                    Fila(titulo: "Permiso de administrador", detalle: "Solo para «pmset disablesleep»") {
                        Boton(titulo: "Quitar", icono: "xmark") { vigilante.quitarPermiso() }
                    }
                }
            }
            .toggleStyle(Interruptor())
        }
    }
}

struct Fila<Control: View>: View {
    let titulo: String
    let detalle: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo).font(.system(size: 12.5, weight: .medium)).foregroundStyle(Tono.texto)
                Text(detalle).font(.system(size: 10.5)).foregroundStyle(Tono.tenue)
            }
            Spacer(minLength: 8)
            control.controlSize(.small)
        }
    }
}

// MARK: - Barra de estado

struct BarraEstado: View {
    @ObservedObject var vigilante: Vigilante

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8).shadow(color: color.opacity(0.8), radius: 4)
            Text(texto)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Tono.texto.opacity(0.9))
                .lineLimit(1)
            Spacer()
            Boton(titulo: "Salir", icono: "power") { NSApp.terminate(nil) }
        }
        .padding(.horizontal, 16)
        .frame(height: 42)
        .background(Color.black.opacity(0.25))
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .top)
    }

    private var color: Color {
        switch vigilante.situacion {
        case .protegido, .normal: Tono.verde
        case .esperando, .sinPermiso: Tono.naranja
        case .apagado: Tono.tenue
        case .error: Tono.rojo
        }
    }

    private var texto: String {
        switch vigilante.situacion {
        case .protegido: "Listo · suspensión bloqueada"
        case .normal: "Listo · vigilando pantallas"
        case .esperando: "Trabajando en restaurar…"
        case .apagado: "En pausa"
        case .sinPermiso: "Esperando permiso"
        case .error: "Error"
        }
    }
}

// MARK: - Piezas comunes

/// Interruptor tipo píldora en el color del logo (el nativo sale gris en las capturas).
struct Interruptor: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        let on = configuration.isOn
        Button { configuration.isOn.toggle() } label: {
            ZStack(alignment: on ? .trailing : .leading) {
                Capsule().fill(on
                    ? AnyShapeStyle(LinearGradient(colors: [Tono.acentoClaro, Tono.acento],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.white.opacity(0.1)))
                Circle().fill(Color.white).padding(2.5).shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
            }
            .frame(width: 34, height: 20)
            .borde(10, Color.white.opacity(on ? 0 : 0.1))
            .shadow(color: Tono.acento.opacity(on ? 0.35 : 0), radius: 6)
            .animation(.spring(duration: 0.22, bounce: 0.25), value: on)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(on ? "activado" : "desactivado")
    }
}

struct BotonPrincipal: View {
    let titulo: String
    let icono: String
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 7) {
                Image(systemName: icono).font(.system(size: 11, weight: .bold))
                Text(titulo).font(.system(size: 12.5, weight: .bold))
            }
            .foregroundStyle(Tono.oscuro)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 11).fill(
                LinearGradient(colors: [Tono.acentoClaro, Tono.acento, Tono.acentoOscuro],
                               startPoint: .top, endPoint: .bottom)))
            .shadow(color: Tono.acento.opacity(0.45), radius: 10, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }
}

struct Boton: View {
    let titulo: String
    let icono: String
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 5) {
                Image(systemName: icono).font(.system(size: 10, weight: .semibold))
                Text(titulo).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Tono.texto.opacity(0.9))
            .padding(.horizontal, 11)
            .frame(height: 26)
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.06)))
            .borde(13, Color.white.opacity(0.1))
            .contentShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
}

/// Borde dibujado como anillo relleno: en macOS 26, `stroke`/`strokeBorder` con radio
/// igual a media altura pinta unas rayitas sueltas en los laterales.
struct Aro: Shape {
    var radio: CGFloat
    var grosor: CGFloat = 1

    func path(in rect: CGRect) -> Path {
        let r = min(radio, rect.height / 2, rect.width / 2)
        var camino = Path(roundedRect: rect, cornerRadius: r)
        camino.addPath(Path(roundedRect: rect.insetBy(dx: grosor, dy: grosor), cornerRadius: max(0, r - grosor)))
        return camino
    }
}

extension View {
    func borde(_ radio: CGFloat, _ color: Color, grosor: CGFloat = 1) -> some View {
        overlay(Aro(radio: radio, grosor: grosor).fill(color, style: FillStyle(eoFill: true)))
    }
}

struct Tarjeta<Contenido: View>: View {
    @ViewBuilder let contenido: Contenido

    var body: some View {
        contenido
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
            .borde(16, Color.white.opacity(0.08))
    }
}

struct Etiqueta: View {
    let texto: String

    var body: some View {
        Text(texto)
            .font(.system(size: 10, weight: .bold))
            .kerning(1.2)
            .foregroundStyle(Tono.secundario)
    }
}
