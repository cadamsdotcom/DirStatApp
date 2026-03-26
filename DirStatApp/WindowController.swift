import AppKit
import SwiftUI

@Observable
class WindowController: NSObject {
    let id: UUID
    var state: WindowState
    var gitData: GitData = GitData()

    let window: BorderlessWindow
    private var hostingView: NSHostingView<DirStatView>!
    private var refreshTimer: Timer?
    private let gitService = GitService()
    private var saveDebounceTimer: Timer?
    private var resizeDebounceTimer: Timer?
    private var isAutoResizing = false

    init(state: WindowState) {
        self.id = state.id
        self.state = state

        let rect = NSRect(x: state.x, y: state.y, width: state.width, height: state.height)
        self.window = BorderlessWindow(contentRect: rect)

        super.init()

        let hv = NSHostingView(rootView: DirStatView(controller: self))
        hv.sizingOptions = []  // prevent hosting view from overriding our manual frame sizing
        self.hostingView = hv
        let containerView = WindowContainerView(hostingView: hv)
        window.contentView = containerView
        window.alphaValue = CGFloat(state.alpha)
        window.interactionDelegate = self

        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        startRefreshTimer()

        if state.directoryPath != nil {
            refreshGitData()
        }
    }

    func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshGitData()
        }
    }

    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refreshGitData() {
        guard let path = state.directoryPath else { return }
        let baseBranch = state.baseBranch
        Task {
            let data = await gitService.fetchGitData(directoryPath: path, baseBranch: baseBranch)
            self.gitData = data
            self.fitWindowToContent()
        }
    }

    func openDirectoryChooser() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a directory to track"

        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            self.state.directoryPath = url.path(percentEncoded: false)
            self.refreshGitData()
            self.scheduleSave()
        }
    }

    func setBaseBranch(_ branch: String) {
        state.baseBranch = branch
        gitData.baseBranch = branch
        refreshGitData()
        scheduleSave()
    }

    func fitWindowToContent() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let currentFrame = self.window.frame

            // NSHostingController.sizeThatFits(in:) proposes a real CGSize to the
            // SwiftUI layout system, unlike NSHostingView.fittingSize which always
            // returns the unconstrained ideal size.
            let mc = NSHostingController(rootView: DirStatView(controller: self))
            _ = mc.view // force view load
            let fitted = mc.sizeThatFits(in: CGSize(
                width: currentFrame.width,
                height: CGFloat.greatestFiniteMagnitude
            ))
            let newHeight = ceil(fitted.height)

            guard abs(currentFrame.height - newHeight) > 1 else { return }
            let newOrigin = NSPoint(x: currentFrame.origin.x, y: currentFrame.origin.y + currentFrame.height - newHeight)
            self.isAutoResizing = true
            self.window.setFrame(NSRect(x: newOrigin.x, y: newOrigin.y, width: currentFrame.width, height: newHeight), display: true)
            self.isAutoResizing = false
        }
    }

    func setAlpha(_ alpha: Double) {
        state.alpha = alpha
        window.alphaValue = CGFloat(alpha)
        scheduleSave()
    }

    func closeWindow() {
        stopRefreshTimer()
        window.orderOut(nil)
        WindowManager.shared.removeController(self)
    }

    func scheduleSave() {
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.state.x = Double(self.window.frame.origin.x)
            self.state.y = Double(self.window.frame.origin.y)
            self.state.width = Double(self.window.frame.width)
            self.state.height = Double(self.window.frame.height)
            PersistenceService.shared.saveAll()
        }
    }

    deinit {
        refreshTimer?.invalidate()
        saveDebounceTimer?.invalidate()
        resizeDebounceTimer?.invalidate()
    }
}

extension WindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        guard !isAutoResizing else { return }
        // Debounce to avoid fighting with the user's live drag
        resizeDebounceTimer?.invalidate()
        resizeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            self?.fitWindowToContent()
            self?.scheduleSave()
        }
    }
}

extension WindowController: BorderlessWindowDelegate {
    func borderlessWindowClicked(_ window: BorderlessWindow) {
        openDirectoryChooser()
    }

    func borderlessWindowRightClicked(_ window: BorderlessWindow, event: NSEvent) {
        let menu = ContextMenuBuilder.build(for: self)
        NSMenu.popUpContextMenu(menu, with: event, for: window.contentView!)
    }

    func borderlessWindowDidMove(_ window: BorderlessWindow) {
        scheduleSave()
    }
}

class WindowContainerView: NSView {
    init(hostingView: NSView) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.white.cgColor

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
