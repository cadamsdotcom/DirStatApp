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

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event) ?? event
        }

        WindowManager.shared.restoreWindows()
        if WindowManager.shared.controllers.isEmpty {
            WindowManager.shared.createWindow()
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard let chars = event.charactersIgnoringModifiers?.lowercased(), chars == "h" else { return event }

        if flags == [.command, .shift] {
            // Cmd+Shift+H: toggle all windows
            WindowManager.shared.toggleAllVisibility()
            return nil
        } else if flags == [.command] {
            // Cmd+H: hide focused window
            if let keyWindow = NSApp.keyWindow as? BorderlessWindow,
               let controller = WindowManager.shared.controllers.first(where: { $0.window === keyWindow }) {
                controller.hideWindow()
                return nil
            }
        }
        return event
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
            let item = NSMenuItem(title: title, action: #selector(toggleWindowVisibility(_:)), keyEquivalent: "")
            item.representedObject = controller
            item.state = controller.isVisible ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show All", action: #selector(showAllWindows), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide All", action: #selector(hideAllWindows), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func newWindow() {
        WindowManager.shared.createWindow()
    }

    @objc private func showAllWindows() {
        for controller in WindowManager.shared.controllers { controller.showWindow() }
    }

    @objc private func hideAllWindows() {
        for controller in WindowManager.shared.controllers { controller.hideWindow() }
    }

    @objc private func toggleWindowVisibility(_ sender: NSMenuItem) {
        guard let controller = sender.representedObject as? WindowController else { return }
        controller.toggleVisibility()
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
