import Foundation

/// Lógica pura de PoxiOFFX, separada de la interfaz para poder probarla.
public enum Reglas {
    /// Al desconectar se espera un poco: algunos monitores desaparecen un instante
    /// al dormirse o al cambiar de resolución, y no queremos dormir el Mac por eso.
    public static let esperaAlDesconectar: TimeInterval = 4

    /// Con al menos una pantalla externa (y el interruptor encendido) se bloquea la suspensión.
    public static func debeBloquear(externas: Int, activado: Bool) -> Bool {
        activado && externas > 0
    }

    /// Cuánto esperar antes de pasar de `bloqueado` a `deseado`.
    public static func espera(bloqueado: Bool, deseado: Bool) -> TimeInterval {
        bloqueado && !deseado ? esperaAlDesconectar : 0
    }

    /// Si al restaurar hay que dormir el Mac en el acto: se quitó la pantalla con la tapa cerrada.
    public static func dormirTrasRestaurar(tapaCerrada: Bool) -> Bool { tapaCerrada }

    /// Lee `SleepDisabled` de la salida de `pmset -g`. Si la línea no está, vale 0.
    public static func suspensionBloqueada(salidaPmset: String) -> Bool {
        for linea in salidaPmset.split(whereSeparator: \.isNewline) {
            let partes = linea.split(whereSeparator: \.isWhitespace)
            if partes.first == "SleepDisabled", let valor = partes.dropFirst().first {
                return valor == "1"
            }
        }
        return false
    }

    // MARK: - Permiso (sudoers)

    public static let rutaPermiso = "/etc/sudoers.d/poxioffx"
    public static let pmset = "/usr/bin/pmset"

    public static func argumentos(bloquear: Bool) -> [String] {
        ["-a", "disablesleep", bloquear ? "1" : "0"]
    }

    /// Nombres de usuario de macOS válidos: así nada raro acaba dentro de sudoers.
    public static func usuarioValido(_ usuario: String) -> Bool {
        usuario.range(of: #"^[a-z_][a-z0-9_.-]{0,31}$"#, options: .regularExpression) != nil
    }

    /// Regla de sudoers que deja a este usuario ejecutar SOLO esos dos comandos sin contraseña.
    public static func reglaSudoers(usuario: String) -> String? {
        guard usuarioValido(usuario) else { return nil }
        let comandos = [true, false].map { ([pmset] + argumentos(bloquear: $0)).joined(separator: " ") }
        return "\(usuario) ALL = (root) NOPASSWD: \(comandos.joined(separator: ", "))"
    }

    /// Script de shell (se ejecuta como root) que valida la regla con `visudo` y la instala.
    public static func scriptInstalar(usuario: String) -> String? {
        guard let regla = reglaSudoers(usuario: usuario) else { return nil }
        return """
        f=$(/usr/bin/mktemp) && printf '%s\\n' '\(regla)' > "$f" && /usr/sbin/visudo -cf "$f" >/dev/null \
        && /usr/bin/install -m 0440 -o root -g wheel "$f" \(rutaPermiso); r=$?; /bin/rm -f "$f"; exit $r
        """
    }

    public static var scriptQuitar: String {
        "/usr/bin/pmset -a disablesleep 0; /bin/rm -f \(rutaPermiso)"
    }

    /// Escapa un texto para meterlo entre comillas en AppleScript.
    public static func comillasAppleScript(_ texto: String) -> String {
        "\"" + texto.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}
