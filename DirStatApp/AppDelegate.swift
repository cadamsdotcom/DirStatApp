import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: "DirStat")
        }
        statusItem.menu = buildMenu()

        WindowManager.shared.restoreWindows()
        if WindowManager.shared.controllers.isEmpty {
            WindowManager.shared.createWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        PersistenceService.shared.saveAll()
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        return menu
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(NSMenuItem(title: "New Window", action: #selector(newWindow), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())

        for controller in WindowManager.shared.controllers {
            let title: String
            if let path = controller.state.directoryPath {
                title = abbreviatePath(path)
            } else {
                title = "No Directory"
            }
            let item = NSMenuItem(title: title, action: #selector(focusWindow(_:)), keyEquivalent: "")
            item.representedObject = controller
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func newWindow() {
        WindowManager.shared.createWindow()
    }

    @objc private func focusWindow(_ sender: NSMenuItem) {
        guard let controller = sender.representedObject as? WindowController else { return }
        controller.window.makeKeyAndOrderFront(nil)
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
