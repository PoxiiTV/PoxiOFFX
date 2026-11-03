import AppKit
import ServiceManagement
import PoxiOFFXCore

/// Vigila las pantallas y pone o quita el bloqueo de suspensión según haga falta.
@MainActor
final class Vigilante: ObservableObject {
    enum Situacion: Equatable {
        case normal          // sin pantallas externas: la tapa suspende
        case protegido       // hay pantalla externa: se puede cerrar la tapa
        case esperando       // se acaba de desconectar: restaurando en unos segundos
        case apagado         // interruptor apagado
        case sinPermiso      // falta instalar el permiso
        case error(String)
    }

    @Published private(set) var pantallas: [String] = []
    @Published private(set) var bloqueado = false
    @Published private(set) var permiso = false
    @Published private(set) var situacion: Situacion = .normal
    @Published var activado: Bool {
        didSet {
            UserDefaults.standard.set(activado, forKey: "activado")
            revisar()
        }
    }
    @Published var alIniciar: Bool {
        didSet { if alIniciar != oldValue { cambiarInicio() } }
    }

    private let real: Bool
    private var pendiente: DispatchWorkItem?
    private var observadores: [NSObjectProtocol] = []

    init() {
        real = true
        activado = UserDefaults.standard.object(forKey: "activado") as? Bool ?? true
        alIniciar = SMAppService.mainApp.status == .enabled
    }

    /// Para las capturas: datos de ejemplo, sin tocar el sistema.
    init(ejemplo pantallas: [String], bloqueado: Bool, permiso: Bool = true, situacion: Situacion) {
        real = false
        activado = true
        alIniciar = true
        self.pantallas = pantallas
        self.bloqueado = bloqueado
        self.permiso = permiso
        self.situacion = situacion
    }

    func empezar() {
        let centro = NotificationCenter.default
        observadores.append(centro.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.revisar() } })
        observadores.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.revisar() } })
        revisar()
    }

    /// Al salir se deja macOS como estaba.
    func restaurarAlSalir() {
        guard real, bloqueado else { return }
        _ = Energia.fijar(bloquear: false)
    }

    func revisar() {
        guard real else { return }
        pantallas = Energia.pantallasExternas()
        permiso = Energia.permisoInstalado()
        bloqueado = Energia.suspensionBloqueada()
        let deseado = Reglas.debeBloquear(externas: pantallas.count, activado: activado)

        pendiente?.cancel()
        pendiente = nil
        guard deseado != bloqueado else { return actualizarSituacion() }

        let espera = Reglas.espera(bloqueado: bloqueado, deseado: deseado)
        if espera == 0 { return aplicar(deseado) }
        situacion = .esperando
        let tarea = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                // Se vuelve a mirar: si la pantalla ha vuelto, no se toca nada.
                self.pantallas = Energia.pantallasExternas()
                guard !Reglas.debeBloquear(externas: self.pantallas.count, activado: self.activado) else {
                    return self.actualizarSituacion()
                }
                self.aplicar(false)
            }
        }
        pendiente = tarea
        DispatchQueue.main.asyncAfter(deadline: .now() + espera, execute: tarea)
    }

    private func aplicar(_ bloquear: Bool) {
        guard permiso else { return actualizarSituacion() }
        if !Energia.fijar(bloquear: bloquear) {
            situacion = .error(bloquear
                ? "No se pudo bloquear la suspensión. Prueba a reinstalar el permiso."
                : "No se pudo restaurar la suspensión. Prueba a reinstalar el permiso.")
            return
        }
        bloqueado = Energia.suspensionBloqueada()
        actualizarSituacion()
        // Pantalla quitada con la tapa cerrada: se duerme ya, como haría macOS.
        if !bloquear && Reglas.dormirTrasRestaurar(tapaCerrada: Energia.tapaCerrada()) {
            Energia.dormirAhora()
        }
    }

    private func actualizarSituacion() {
        if !permiso { situacion = .sinPermiso }
        else if !activado { situacion = bloqueado ? .error("Sigue bloqueada la suspensión.") : .apagado }
        else { situacion = bloqueado ? .protegido : .normal }
    }

    // MARK: - Acciones

    func instalarPermiso() {
        do throws(Energia.ErrorPermiso) {
            try Energia.instalarPermiso()
        } catch {
            switch error {
            case .cancelado: return
            case .usuario:
                situacion = .error("Tu nombre de usuario tiene caracteres raros y no se puede usar en el permiso.")
            case .fallo(let m):
                situacion = .error("No se pudo instalar el permiso: \(m)")
            }
            return
        }
        revisar()
    }

    func quitarPermiso() {
        do throws(Energia.ErrorPermiso) {
            try Energia.quitarPermiso()
        } catch {
            if case .cancelado = error { return }
            situacion = .error("No se pudo quitar el permiso.")
            return
        }
        revisar()
    }

    private func cambiarInicio() {
        guard real else { return }
        do {
            if alIniciar { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            situacion = .error("No se pudo cambiar el inicio de sesión. Mueve la app a Aplicaciones y vuelve a probar.")
        }
    }
}
