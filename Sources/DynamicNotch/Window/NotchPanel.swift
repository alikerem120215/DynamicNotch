import AppKit

public final class NotchPanel: NSPanel {
    
    public var onMouseEntered: (() -> Void)?
    public var onMouseExited: (() -> Void)?
    public var onDragEntered: (() -> Void)?
    public var onDragExited: (() -> Void)?
    public var onFilesDropped: (([URL]) -> Void)?
    
    private var trackingArea: NSTrackingArea?
    
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupPanel()
        setupDragAndDrop()
    }
    
    private func setupPanel() {
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.level = .statusBar
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        
        self.acceptsMouseMovedEvents = true
        self.hidesOnDeactivate = false
    }
    
    private func setupDragAndDrop() {
        registerForDraggedTypes([
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("public.item")
        ])
    }
    
    public override var canBecomeKey: Bool {
        return false
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
    
    public func updateTrackingArea() {
        if let existing = trackingArea {
            contentView?.removeTrackingArea(existing)
        }
        
        guard let contentView = self.contentView else { return }
        
        let newArea = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(newArea)
        self.trackingArea = newArea
    }
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        onMouseEntered?()
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        onMouseExited?()
    }
    
    // MARK: - NSDraggingDestination
    
    public func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onDragEntered?()
        return .copy
    }
    
    public func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    public func draggingExited(_ sender: NSDraggingInfo?) {
        onDragExited?()
    }
    
    public func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            if !urls.isEmpty {
                onFilesDropped?(urls)
                return true
            }
        }
        return false
    }
}
