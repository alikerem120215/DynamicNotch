import AppKit
import SwiftUI

@MainActor
public final class NotchWindowController: NSObject {
    public static let shared = NotchWindowController()
    
    private var panel: NotchPanel?
    private var screenChangeObserver: NSObjectProtocol?
    
    private override init() {
        super.init()
    }
    
    public func setupWindow(with stateManager: NotchStateManager) {
        let screen = NSScreen.main
        let info = ScreenGeometryHelper.shared.getNotchInfo(for: screen)
        
        // Window container frame: large enough to accommodate shelf / expanded views (500x260)
        let containerWidth: CGFloat = 500
        let containerHeight: CGFloat = 260
        let notchRect = info.physicalNotchRect
        let screenFrame = info.screenFrame
        
        let originX = notchRect.midX - (containerWidth / 2.0)
        let originY = screenFrame.origin.y + screenFrame.height - containerHeight
        let initialRect = NSRect(x: originX, y: originY, width: containerWidth, height: containerHeight)
        
        let panel = NotchPanel(contentRect: initialRect)
        
        let rootView = NotchRootView(
            stateManager: stateManager,
            nowPlaying: NowPlayingManager.shared,
            shelfManager: DropShelfManager.shared
        )
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight)
        
        panel.contentView = hostingView
        panel.updateTrackingArea()
        
        // Mouse hover callbacks
        panel.onMouseEntered = { [weak stateManager] in
            stateManager?.handleMouseEnter()
        }
        
        panel.onMouseExited = { [weak stateManager] in
            stateManager?.handleMouseExit()
        }
        
        // Drag and drop callbacks
        panel.onDragEntered = { [weak stateManager] in
            stateManager?.handleDragEntered()
        }
        
        panel.onDragExited = { [weak stateManager] in
            stateManager?.handleDragExited()
        }
        
        panel.onFilesDropped = { [weak stateManager] urls in
            stateManager?.handleFilesDropped(urls)
        }
        
        panel.orderFrontRegardless()
        self.panel = panel
        
        observeScreenChanges()
    }
    
    private func observeScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.repositionWindow()
            }
        }
    }
    
    public func repositionWindow() {
        guard let panel = panel else { return }
        let screen = NSScreen.main
        let info = ScreenGeometryHelper.shared.getNotchInfo(for: screen)
        
        let containerWidth: CGFloat = 500
        let containerHeight: CGFloat = 260
        let notchRect = info.physicalNotchRect
        let screenFrame = info.screenFrame
        
        let originX = notchRect.midX - (containerWidth / 2.0)
        let originY = screenFrame.origin.y + screenFrame.height - containerHeight
        let newRect = NSRect(x: originX, y: originY, width: containerWidth, height: containerHeight)
        
        panel.setFrame(newRect, display: true, animate: false)
        panel.updateTrackingArea()
    }
    
    public func show() {
        panel?.orderFrontRegardless()
    }
    
    public func hide() {
        panel?.orderOut(nil)
    }
}
