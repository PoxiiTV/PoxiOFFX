import AppKit
import IOKit
import PoxiOFFXCore

/// Todo lo que toca el sistema: pantallas, tapa, `pmset` y el permiso de sudoers.
enum Energia {
    struct Resultado {
        let codigo: Int32
        let salida: String
    }

    @discardableResult
    static func ejecutar(_ ruta: String, _ argumentos: [String]) -> Resultado {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: ruta)
        p.arguments = argumentos
        let tubo = Pipe()
        p.standardOutput = tubo
        p.standardError = tubo
        p.standardInput = FileHandle.nullDevice
        do { try p.run() } catch { return Resultado(codigo: -1, salida: error.localizedDescription) }
        let datos = tubo.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return Resultado(codigo: p.terminationStatus, salida: String(decoding: datos, as: UTF8.self))
    }

    // MARK: - Pantallas

    /// Nombres de las pantallas externas conectadas (también si están dormidas).
    static func pantallasExternas() -> [String] {
        var cantidad: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &cantidad) == .success, cantidad > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(cantidad))
        guard CGGetOnlineDisplayList(cantidad, &ids, &cantidad) == .success else { return [] }
        let nombres = Dictionary(NSScreen.screens.compactMap { pantalla -> (CGDirectDisplayID, String)? in
            guard let id = pantalla.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            else { return nil }
            return (id.uint32Value, pantalla.localizedName)
        }, uniquingKeysWith: { a, _ in a })
        return ids.prefix(Int(cantidad))
            .filter { CGDisplayIsBuiltin($0) == 0 }
            .map { nombres[$0] ?? "Pantalla externa" }
    }

    // MARK: - Tapa

    static func tapaCerrada() -> Bool {
        let raiz = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard raiz != 0 else { return false }
        defer { IOObjectRelease(raiz) }
        let valor = IORegistryEntryCreateCFProperty(raiz, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)
        return (valor?.takeRetainedValue() as? Bool) ?? false
    }

    // MARK: - Suspensión

    static func suspensionBloqueada() -> Bool {
        Reglas.suspensionBloqueada(salidaPmset: ejecutar(Reglas.pmset, ["-g"]).salida)
    }

    /// `sudo -n -l <comando>` sale bien solo si la regla deja ejecutarlo sin contraseña.
    static func permisoInstalado() -> Bool {
        ejecutar("/usr/bin/sudo", ["-n", "-l", Reglas.pmset] + Reglas.argumentos(bloquear: true)).codigo == 0
    }

    static func fijar(bloquear: Bool) -> Bool {
        ejecutar("/usr/bin/sudo", ["-n", Reglas.pmset] + Reglas.argumentos(bloquear: bloquear)).codigo == 0
    }

    static func dormirAhora() {
        ejecutar(Reglas.pmset, ["sleepnow"])
    }

    // MARK: - Permiso (pide la contraseña con el diálogo de macOS)

    enum ErrorPermiso: Error {
        case usuario, cancelado, fallo(String)
    }

    static func instalarPermiso() throws(ErrorPermiso) {
        guard let script = Reglas.scriptInstalar(usuario: NSUserName()) else { throw .usuario }
        try comoAdministrador(script)
    }

    static func quitarPermiso() throws(ErrorPermiso) {
        try comoAdministrador(Reglas.scriptQuitar)
    }

    private static func comoAdministrador(_ shell: String) throws(ErrorPermiso) {
        let fuente = "do shell script \(Reglas.comillasAppleScript(shell)) with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: fuente)?.executeAndReturnError(&error)
        guard let error else { return }
        if (error[NSAppleScript.errorNumber] as? Int) == -128 { throw .cancelado }
        throw .fallo(error[NSAppleScript.errorMessage] as? String ?? "error desconocido")
    }
}
