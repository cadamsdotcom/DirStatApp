import AppKit

@Observable
class WindowManager {
    static let shared = WindowManager()
    private(set) var controllers: [WindowController] = []

    private init() {}

    func createWindow(state: WindowState? = nil) {
        let windowState = state ?? WindowState()
        let controller = WindowController(state: windowState)
        controllers.append(controller)
        PersistenceService.shared.saveAll()
    }

    func removeController(_ controller: WindowController) {
        controllers.removeAll { $0.id == controller.id }
        PersistenceService.shared.saveAll()
    }

    func restoreWindows() {
        let states = PersistenceService.shared.load()
        if states.isEmpty {
            return
        }
        for state in states {
            let validatedState = validateScreenPosition(state)
            createWindow(state: validatedState)
        }
    }

    private func validateScreenPosition(_ state: WindowState) -> WindowState {
        var s = state
        let screens = NSScreen.screens
        let frame = NSRect(x: s.x, y: s.y, width: s.width, height: s.height)
        let isOnScreen = screens.contains { $0.frame.intersects(frame) }
        if !isOnScreen, let main = NSScreen.main {
            s.x = main.frame.midX - s.width / 2
            s.y = main.frame.midY - s.height / 2
        }
        return s
    }
}
