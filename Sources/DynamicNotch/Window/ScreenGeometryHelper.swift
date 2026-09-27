import AppKit

public struct ScreenNotchInfo: Sendable {
    public let hasPhysicalNotch: Bool
    public let physicalNotchRect: NSRect
    public let screenFrame: NSRect
    public let safeAreaTop: CGFloat
    
    public init(
        hasPhysicalNotch: Bool,
        physicalNotchRect: NSRect,
        screenFrame: NSRect,
        safeAreaTop: CGFloat
    ) {
        self.hasPhysicalNotch = hasPhysicalNotch
        self.physicalNotchRect = physicalNotchRect
        self.screenFrame = screenFrame
        self.safeAreaTop = safeAreaTop
    }
}

public final class ScreenGeometryHelper: @unchecked Sendable {
    public static let shared = ScreenGeometryHelper()
    
    private init() {}
    
    /// Detects notch info for the given or main screen
    public func getNotchInfo(for screen: NSScreen? = NSScreen.main) -> ScreenNotchInfo {
        guard let screen = screen ?? NSScreen.main else {
            let fallbackRect = NSRect(x: 0, y: 0, width: 1440, height: 900)
            let notchRect = NSRect(x: (1440 - 160) / 2, y: 900 - 32, width: 160, height: 32)
            return ScreenNotchInfo(
                hasPhysicalNotch: false,
                physicalNotchRect: notchRect,
                screenFrame: fallbackRect,
                safeAreaTop: 32
            )
        }
        
        let screenFrame = screen.frame
        let safeAreaTop = screen.safeAreaInsets.top
        
        // Physical notch detection on Apple Silicon (Sonoma/Sequoia)
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea,
           leftArea.width > 0 && rightArea.width > 0 {
            
            let notchWidth = screenFrame.width - (leftArea.width + rightArea.width)
            let notchHeight = max(safeAreaTop, 34.0)
            let notchX = screenFrame.origin.x + leftArea.width
            let notchY = screenFrame.origin.y + screenFrame.height - notchHeight
            
            let notchRect = NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
            
            return ScreenNotchInfo(
                hasPhysicalNotch: true,
                physicalNotchRect: notchRect,
                screenFrame: screenFrame,
                safeAreaTop: safeAreaTop
            )
        } else {
            // External monitor or Mac without physical notch: Virtual Dynamic Island
            let islandWidth: CGFloat = 160.0
            let islandHeight: CGFloat = 32.0
            let notchX = screenFrame.origin.x + (screenFrame.width - islandWidth) / 2.0
            let notchY = screenFrame.origin.y + screenFrame.height - islandHeight
            
            let islandRect = NSRect(x: notchX, y: notchY, width: islandWidth, height: islandHeight)
            
            return ScreenNotchInfo(
                hasPhysicalNotch: false,
                physicalNotchRect: islandRect,
                screenFrame: screenFrame,
                safeAreaTop: safeAreaTop > 0 ? safeAreaTop : 28.0
            )
        }
    }
    
    /// Returns the target frame for the overlay window based on active NotchState
    public func targetWindowFrame(for state: NotchState, on screen: NSScreen? = NSScreen.main) -> NSRect {
        let info = getNotchInfo(for: screen)
        let notchRect = info.physicalNotchRect
        let screenFrame = info.screenFrame
        let notchHeight = info.hasPhysicalNotch ? notchRect.height : 0
        
        let targetWidth: CGFloat
        let targetHeight: CGFloat
        
        switch state {
        case .idle:
            if info.hasPhysicalNotch {
                targetWidth = notchRect.width + 4
                targetHeight = notchRect.height + 2
            } else {
                targetWidth = 160
                targetHeight = 32
            }
        case .mediaCompact:
            targetWidth = max(notchRect.width + 140, 260)
            targetHeight = max(notchRect.height + 4, 36)
        case .mediaExpanded:
            targetWidth = 440
            targetHeight = notchHeight + 180
        case .shelfCompact:
            targetWidth = max(notchRect.width + 130, 250)
            targetHeight = max(notchRect.height + 4, 36)
        case .shelfExpanded:
            targetWidth = 480
            targetHeight = notchHeight + 160
        case .dropTargetActive:
            targetWidth = max(notchRect.width + 180, 360)
            targetHeight = notchHeight + 72
        case .volumeHUD, .brightnessHUD:
            targetWidth = max(notchRect.width + 120, 300)
            // Essential: Content drops down below physical notch camera
            targetHeight = notchHeight + 42
        }
        
        // Horizontal centering relative to the notch
        let targetX = notchRect.midX - (targetWidth / 2.0)
        // Top alignment to the top edge of screen
        let targetY = screenFrame.origin.y + screenFrame.height - targetHeight
        
        return NSRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
    }
}
