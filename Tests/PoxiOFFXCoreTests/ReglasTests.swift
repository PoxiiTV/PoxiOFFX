import Testing
import Foundation
@testable import PoxiOFFXCore

@Test func bloqueaSoloConPantallaYActivado() {
    #expect(Reglas.debeBloquear(externas: 1, activado: true))
    #expect(Reglas.debeBloquear(externas: 2, activado: true))
    #expect(!Reglas.debeBloquear(externas: 0, activado: true))
    #expect(!Reglas.debeBloquear(externas: 2, activado: false))
}

@Test func soloEsperaAlRestaurar() {
    #expect(Reglas.espera(bloqueado: false, deseado: true) == 0)
    #expect(Reglas.espera(bloqueado: true, deseado: false) == Reglas.esperaAlDesconectar)
    #expect(Reglas.espera(bloqueado: true, deseado: true) == 0)
}

@Test func leeSleepDisabled() {
    let activo = """
    System-wide power settings:
     SleepDisabled\t\t1
    Currently in use:
     sleep                1
    """
    #expect(Reglas.suspensionBloqueada(salidaPmset: activo))
    #expect(!Reglas.suspensionBloqueada(salidaPmset: " SleepDisabled\t\t0\n"))
    #expect(!Reglas.suspensionBloqueada(salidaPmset: "Currently in use:\n sleep 1\n"))
}

@Test func reglaSudoersLimitada() {
    #expect(Reglas.reglaSudoers(usuario: "alexis")
        == "alexis ALL = (root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0")
    #expect(Reglas.reglaSudoers(usuario: "root'; rm -rf /") == nil)
    #expect(Reglas.reglaSudoers(usuario: "ALL") == nil)
    #expect(Reglas.reglaSudoers(usuario: "") == nil)
}

@Test func scriptInstalarValidaConVisudo() throws {
    let s = try #require(Reglas.scriptInstalar(usuario: "alexis"))
    #expect(s.contains("visudo -cf"))
    #expect(s.contains("-m 0440 -o root -g wheel"))
    #expect(s.contains(Reglas.rutaPermiso))
}

@Test func escapaAppleScript() {
    #expect(Reglas.comillasAppleScript(#"a "b" \c"#) == #""a \"b\" \\c""#)
}

/// El script que se ejecuta como root tiene que ser shell válido (solo se comprueba, no se ejecuta).
@Test func scriptsSonShellValido() throws {
    for script in [try #require(Reglas.scriptInstalar(usuario: "alexis")), Reglas.scriptQuitar] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-n", "-c", script]
        try p.run()
        p.waitUntilExit()
        #expect(p.terminationStatus == 0)
    }
}

/// La regla que se instala la acepta `visudo`.
@Test func reglaPasaVisudo() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("poxioffx-regla-\(UUID())")
    try (try #require(Reglas.reglaSudoers(usuario: "alexis")) + "\n").write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/visudo")
    p.arguments = ["-cf", url.path]
    p.standardOutput = FileHandle.nullDevice
    try p.run()
    p.waitUntilExit()
    #expect(p.terminationStatus == 0)
}
