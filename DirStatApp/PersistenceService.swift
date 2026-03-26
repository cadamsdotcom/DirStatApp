import AppKit

class PersistenceService {
    static let shared = PersistenceService()

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("DirStatApp", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        fileURL = appDir.appendingPathComponent("windows.json")
    }

    func load() -> [WindowState] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([WindowState].self, from: data)) ?? []
    }

    func saveAll() {
        let states = WindowManager.shared.controllers.map { controller -> WindowState in
            var state = controller.state
            state.x = Double(controller.window.frame.origin.x)
            state.y = Double(controller.window.frame.origin.y)
            state.width = Double(controller.window.frame.width)
            state.height = Double(controller.window.frame.height)
            return state
        }
        guard let data = try? JSONEncoder().encode(states) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
