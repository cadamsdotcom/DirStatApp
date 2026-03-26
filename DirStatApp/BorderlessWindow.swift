import AppKit

protocol BorderlessWindowDelegate: AnyObject {
    func borderlessWindowClicked(_ window: BorderlessWindow)
    func borderlessWindowRightClicked(_ window: BorderlessWindow, event: NSEvent)
    func borderlessWindowDidMove(_ window: BorderlessWindow)
}

class BorderlessWindow: NSWindow {
    weak var interactionDelegate: BorderlessWindowDelegate?

    private var mouseDownLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    private var isDragging = false
    private let dragThreshold: CGFloat = 3.0

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        isMovableByWindowBackground = false
        hasShadow = true
        minSize = NSSize(width: 300, height: 50)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = NSEvent.mouseLocation
        initialWindowOrigin = frame.origin
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startLocation = mouseDownLocation,
              let startOrigin = initialWindowOrigin else { return }
        let currentLocation = NSEvent.mouseLocation
        let dx = currentLocation.x - startLocation.x
        let dy = currentLocation.y - startLocation.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance > dragThreshold {
            isDragging = true
            let newOrigin = NSPoint(
                x: startOrigin.x + dx,
                y: startOrigin.y + dy
            )
            setFrameOrigin(newOrigin)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            interactionDelegate?.borderlessWindowDidMove(self)
        } else {
            interactionDelegate?.borderlessWindowClicked(self)
        }
        mouseDownLocation = nil
        isDragging = false
    }

    override func rightMouseDown(with event: NSEvent) {
        interactionDelegate?.borderlessWindowRightClicked(self, event: event)
    }
}
