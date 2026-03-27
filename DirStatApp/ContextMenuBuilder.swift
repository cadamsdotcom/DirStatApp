import AppKit

enum ContextMenuBuilder {
    static func build(for controller: WindowController) -> NSMenu {
        let menu = NSMenu()

        // Choose Folder
        let chooseFolderItem = NSMenuItem(title: "Choose Folder…", action: #selector(ChooseFolderMenuTarget.chooseFolder(_:)), keyEquivalent: "")
        let chooseFolderTarget = ChooseFolderMenuTarget(controller: controller)
        chooseFolderItem.target = chooseFolderTarget
        chooseFolderItem.representedObject = chooseFolderTarget
        menu.addItem(chooseFolderItem)

        // New Window
        let newItem = NSMenuItem(title: "New Window", action: #selector(WindowMenuTarget.newWindow(_:)), keyEquivalent: "")
        let newTarget = WindowMenuTarget()
        newItem.target = newTarget
        newItem.representedObject = newTarget
        menu.addItem(newItem)

        // Hide Window
        let hideItem = NSMenuItem(title: "Hide Window", action: #selector(HideMenuTarget.hideWindow(_:)), keyEquivalent: "")
        let hideTarget = HideMenuTarget(controller: controller)
        hideItem.target = hideTarget
        hideItem.representedObject = hideTarget
        menu.addItem(hideItem)

        // Close Window
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(CloseMenuTarget.closeWindow(_:)), keyEquivalent: "")
        let closeTarget = CloseMenuTarget(controller: controller)
        closeItem.target = closeTarget
        closeItem.representedObject = closeTarget
        menu.addItem(closeItem)

        // Transparency slider
        menu.addItem(NSMenuItem.separator())
        let sliderItem = NSMenuItem()
        sliderItem.title = "Transparency"
        let sliderView = SliderMenuItem(initialValue: controller.state.alpha)
        sliderView.onValueChanged = { [weak controller] value in
            controller?.setAlpha(value)
        }
        sliderItem.view = sliderView
        menu.addItem(sliderItem)

        // Branch lists
        let localBranches = controller.gitData.branches.filter { !$0.isRemote }
        let remoteBranches = controller.gitData.branches.filter { $0.isRemote }

        if !localBranches.isEmpty {
            menu.addItem(NSMenuItem.separator())
            let header = NSMenuItem(title: "Track Changes Against Local Branch", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for branch in localBranches {
                let item = NSMenuItem(title: branch.name, action: #selector(BranchMenuTarget.selectBranch(_:)), keyEquivalent: "")
                let target = BranchMenuTarget(controller: controller, branch: branch.name)
                item.target = target
                item.representedObject = target
                if branch.name == controller.state.baseBranch {
                    item.state = .on
                }
                menu.addItem(item)
            }
        }

        if !remoteBranches.isEmpty {
            menu.addItem(NSMenuItem.separator())
            let header = NSMenuItem(title: "Track Changes Against Remote Branch", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for branch in remoteBranches {
                let item = NSMenuItem(title: branch.name, action: #selector(BranchMenuTarget.selectBranch(_:)), keyEquivalent: "")
                let target = BranchMenuTarget(controller: controller, branch: branch.name)
                item.target = target
                item.representedObject = target
                if branch.name == controller.state.baseBranch {
                    item.state = .on
                }
                menu.addItem(item)
            }
        }

        return menu
    }
}

class BranchMenuTarget: NSObject {
    let controller: WindowController
    let branch: String

    init(controller: WindowController, branch: String) {
        self.controller = controller
        self.branch = branch
    }

    @objc func selectBranch(_ sender: NSMenuItem) {
        controller.setBaseBranch(branch)
    }
}

class WindowMenuTarget: NSObject {
    @objc func newWindow(_ sender: NSMenuItem) {
        WindowManager.shared.createWindow()
    }
}

class HideMenuTarget: NSObject {
    let controller: WindowController

    init(controller: WindowController) {
        self.controller = controller
    }

    @objc func hideWindow(_ sender: NSMenuItem) {
        controller.hideWindow()
    }
}

class ChooseFolderMenuTarget: NSObject {
    let controller: WindowController

    init(controller: WindowController) {
        self.controller = controller
    }

    @objc func chooseFolder(_ sender: NSMenuItem) {
        controller.openDirectoryChooser()
    }
}

class CloseMenuTarget: NSObject {
    let controller: WindowController

    init(controller: WindowController) {
        self.controller = controller
    }

    @objc func closeWindow(_ sender: NSMenuItem) {
        controller.closeWindow()
    }
}
